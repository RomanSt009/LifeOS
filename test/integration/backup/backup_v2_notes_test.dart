import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/backup/lifeos_backup_export_contracts.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/infrastructure/backup/files/lifeos_backup_export_file_writers.dart';
import 'package:lifeos/infrastructure/backup/files/lifeos_backup_file_reader.dart';
import 'package:lifeos/infrastructure/backup/formats/backup_export_format_v2.dart';
import 'package:lifeos/infrastructure/backup/formats/v1_backup_export_encoder.dart';
import 'package:lifeos/infrastructure/backup/formats/v2_backup_export_encoder.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/restore/drift_lifeos_backup_restore_store.dart';

void main() {
  final timestamp = DateTime.utc(2026, 9, 12, 10);
  final task = LifeOsTask.createUserTask(
    id: const LifeOsEntityId(
      value: '00000000-0000-4000-8000-000000000001',
      entityType: LifeOsEntityType.task,
    ),
    title: 'Task',
    timestamp: timestamp,
  );
  final note = LifeOsNote.createUserNote(
    id: const LifeOsEntityId(
      value: '00000000-0000-4000-8000-000000000002',
      entityType: LifeOsEntityType.note,
    ),
    title: 'Note',
    content: '  exact\r\ncontent  ',
    timestamp: timestamp,
  );

  test(
    'writes and reads v2 Task and Note while preserving Note data',
    () async {
      final directory = await Directory.systemTemp.createTemp('lifeos-v2-');
      addTearDown(() => directory.delete(recursive: true));
      final snapshot = LifeOsDataSnapshot(tasks: [task], notes: [note]);
      const encoder = V2BackupExportEncoder();
      final draft = LifeOsBackupDraft(
        createdAt: timestamp,
        applicationVersion: '1.0.0+1',
        dataJson: encoder.encodeBackupData(snapshot),
        formatVersion: 2,
      );
      final path = '${directory.path}${Platform.pathSeparator}backup.zip';

      await const LifeOsBackupFileWriter().write(
        draft: draft,
        sourceDatabaseSchemaVersion: 2,
        destinationPath: path,
      );
      final decoded = await const LifeOsBackupFileReader().read(path);

      expect(decoded.tasks, [task]);
      expect(decoded.notes, [note]);
      expect(decoded.notes.single.content, '  exact\r\ncontent  ');
      final export = encoder.encodeExport(
        createdAt: timestamp,
        applicationVersion: '1.0.0+1',
        snapshot: snapshot,
      );
      LifeOsDataFormatV2.validateExport(export);
      expect(export, contains('"notes"'));
    },
  );

  test('writes and reads a v2 Task-only Backup', () async {
    final directory = await Directory.systemTemp.createTemp('lifeos-v2-task-');
    addTearDown(() => directory.delete(recursive: true));
    const encoder = V2BackupExportEncoder();
    final draft = LifeOsBackupDraft(
      createdAt: timestamp,
      applicationVersion: '1.0.0+1',
      dataJson: encoder.encodeBackupData(LifeOsDataSnapshot(tasks: [task])),
      formatVersion: 2,
    );
    final path = '${directory.path}${Platform.pathSeparator}backup.zip';

    await const LifeOsBackupFileWriter().write(
      draft: draft,
      sourceDatabaseSchemaVersion: 2,
      destinationPath: path,
    );

    final decoded = await const LifeOsBackupFileReader().read(path);
    expect(decoded.tasks, [task]);
    expect(decoded.notes, isEmpty);
  });

  test('restoring a historical v1 Backup removes local Notes', () async {
    final directory = await Directory.systemTemp.createTemp('lifeos-v1-');
    addTearDown(() => directory.delete(recursive: true));
    final database = LifeOsDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftLifeOsBackupRestoreStore(database);
    await store.replaceAll(LifeOsDataSnapshot(tasks: const [], notes: [note]));
    const encoder = V1BackupExportEncoder();
    final draft = LifeOsBackupDraft(
      createdAt: timestamp,
      applicationVersion: '1.0.0+1',
      dataJson: encoder.encodeBackupData(LifeOsDataSnapshot(tasks: [task])),
    );
    final path = '${directory.path}${Platform.pathSeparator}backup.zip';
    await const LifeOsBackupFileWriter().write(
      draft: draft,
      sourceDatabaseSchemaVersion: 1,
      destinationPath: path,
    );

    await store.replaceAll(await const LifeOsBackupFileReader().read(path));

    expect(await database.select(database.taskRecords).get(), hasLength(1));
    expect(await database.select(database.noteRecords).get(), isEmpty);
    expect(await database.select(database.outboxEntries).get(), isEmpty);
  });

  test('atomically restores v2 Notes without creating Outbox', () async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftLifeOsBackupRestoreStore(database);

    await store.replaceAll(LifeOsDataSnapshot(tasks: [task], notes: [note]));

    final noteRow = await database.select(database.noteRecords).getSingle();
    expect(noteRow.title, note.title);
    expect(noteRow.content, note.content);
    expect(await database.select(database.entities).get(), hasLength(2));
    expect(await database.select(database.outboxEntries).get(), isEmpty);
  });

  test('rolls back the whole restore when Note insertion fails', () async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftLifeOsBackupRestoreStore(database);
    await store.replaceAll(LifeOsDataSnapshot(tasks: [task]));
    await database.customStatement('''
      CREATE TRIGGER fail_note BEFORE INSERT ON notes
      BEGIN SELECT RAISE(ABORT, 'controlled'); END;
    ''');

    await expectLater(
      store.replaceAll(LifeOsDataSnapshot(tasks: const [], notes: [note])),
      throwsA(anything),
    );

    expect(await database.select(database.taskRecords).get(), hasLength(1));
    expect(await database.select(database.noteRecords).get(), isEmpty);
  });

  test('rejects malformed Notes before persistence receives a snapshot', () {
    final encoded = const V2BackupExportEncoder().encodeBackupData(
      LifeOsDataSnapshot(tasks: [task], notes: [note]),
    );
    final malformed = encoded.replaceFirst('"title":"Note"', '"title":" "');

    expect(
      () => LifeOsDataFormatV2.decodeBackupData(malformed),
      throwsA(anything),
    );
  });
}
