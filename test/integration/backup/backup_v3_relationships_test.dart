import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/backup/lifeos_backup_export_contracts.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_relationship.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/infrastructure/backup/files/lifeos_backup_export_file_writers.dart';
import 'package:lifeos/infrastructure/backup/files/lifeos_backup_file_reader.dart';
import 'package:lifeos/infrastructure/backup/formats/backup_export_format_v1.dart';
import 'package:lifeos/infrastructure/backup/formats/backup_export_format_v3.dart';
import 'package:lifeos/infrastructure/backup/formats/v3_backup_export_encoder.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/restore/drift_lifeos_backup_restore_store.dart';

void main() {
  final timestamp = DateTime.utc(2026, 9, 12, 10);
  final taskA = _task('00000000-0000-4000-8000-000000000001', timestamp);
  final taskB = _task('00000000-0000-4000-8000-000000000002', timestamp);
  final noteA = _note('00000000-0000-4000-8000-000000000003', timestamp);
  final noteB = _note('00000000-0000-4000-8000-000000000004', timestamp);
  final relationships = [
    _relationship(
      '00000000-0000-4000-8000-000000000101',
      taskA.id,
      taskB.id,
      timestamp,
    ),
    _relationship(
      '00000000-0000-4000-8000-000000000102',
      taskA.id,
      noteA.id,
      timestamp,
    ),
    _relationship(
      '00000000-0000-4000-8000-000000000103',
      noteA.id,
      noteB.id,
      timestamp,
    ).unlink(updatedAt: timestamp.add(const Duration(hours: 1))),
  ];

  test('v3 round trip preserves all Relationship kinds and metadata', () async {
    final directory = await Directory.systemTemp.createTemp('lifeos-v3-');
    addTearDown(() => directory.delete(recursive: true));
    final snapshot = LifeOsDataSnapshot(
      tasks: [taskA, taskB],
      notes: [noteA, noteB],
      relationships: relationships,
    );
    const encoder = V3BackupExportEncoder();
    final draft = LifeOsBackupDraft(
      createdAt: timestamp,
      applicationVersion: '1.0.0+1',
      dataJson: encoder.encodeBackupData(snapshot),
      formatVersion: 3,
    );
    final path = '${directory.path}${Platform.pathSeparator}backup.zip';

    await const LifeOsBackupFileWriter().write(
      draft: draft,
      sourceDatabaseSchemaVersion: 3,
      destinationPath: path,
    );
    final decoded = await const LifeOsBackupFileReader().read(path);

    expect(decoded.tasks, [taskA, taskB]);
    expect(decoded.notes, [noteA, noteB]);
    expect(decoded.relationships, relationships);
    expect(decoded.relationships.last.lifecycle, LifeOsEntityLifecycle.deleted);
    expect(decoded.relationships.last.version, 2);
  });

  test('v3 supports Task-only and Task plus Note datasets', () {
    const encoder = V3BackupExportEncoder();
    for (final snapshot in [
      LifeOsDataSnapshot(tasks: [taskA]),
      LifeOsDataSnapshot(tasks: [taskA], notes: [noteA]),
    ]) {
      final decoded = LifeOsDataFormatV3.decodeBackupData(
        encoder.encodeBackupData(snapshot),
      );
      expect(decoded.relationships, isEmpty);
    }
  });

  test('v3 rejects every invalid Relationship dataset before restore', () {
    final valid = jsonDecode(
      const V3BackupExportEncoder().encodeBackupData(
        LifeOsDataSnapshot(
          tasks: [taskA, taskB],
          notes: [noteA],
          relationships: [relationships.first],
        ),
      ),
    ) as Map<String, dynamic>;

    Map<String, dynamic> changed(void Function(Map<String, dynamic>) change) {
      final copy = jsonDecode(jsonEncode(valid)) as Map<String, dynamic>;
      change(copy);
      return copy;
    }

    final invalidDocuments = [
      changed(
        (json) => json['relationships'][0]['secondEntityId'] =
            '00000000-0000-4000-8000-000000000099',
      ),
      changed(
        (json) => json['relationships'][0]['firstEntityId'] =
            json['relationships'][0]['secondEntityId'],
      ),
      changed((json) {
        final relationship = json['relationships'][0];
        final first = relationship['firstEntityId'];
        relationship['firstEntityId'] = relationship['secondEntityId'];
        relationship['secondEntityId'] = first;
      }),
      changed((json) => json['relationships'][0]['kind'] = 'contains'),
      changed((json) {
        final duplicate = Map<String, dynamic>.from(json['relationships'][0]);
        duplicate['id'] = '00000000-0000-4000-8000-000000000104';
        json['relationships'].add(duplicate);
      }),
      changed((json) {
        final relationship = json['relationships'][0];
        relationship['id'] = '00000000-0000-4000-8000-000000000000';
        relationship['firstEntityId'] = relationship['id'];
      }),
    ];

    for (final document in invalidDocuments) {
      expect(
        () => LifeOsDataFormatV3.decodeBackupData(jsonEncode(document)),
        throwsA(isA<LifeOsDataFormatException>()),
      );
    }
  });

  test('atomic restore inserts Relationships and creates no Outbox', () async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftLifeOsBackupRestoreStore(database);
    final snapshot = LifeOsDataSnapshot(
      tasks: [taskA, taskB],
      notes: [noteA, noteB],
      relationships: relationships,
    );

    await store.replaceAll(snapshot);

    expect(
      await database.select(database.relationshipRecords).get(),
      hasLength(3),
    );
    expect(await database.select(database.outboxEntries).get(), isEmpty);
    final entities = await database.select(database.entities).get();
    expect(entities, hasLength(7));
  });

  test('Relationship insertion failure rolls back the whole restore', () async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftLifeOsBackupRestoreStore(database);
    await store.replaceAll(LifeOsDataSnapshot(tasks: [taskA]));
    await database.customStatement('''
      CREATE TRIGGER fail_relationship BEFORE INSERT ON relationships
      BEGIN SELECT RAISE(ABORT, 'controlled'); END;
    ''');

    await expectLater(
      store.replaceAll(
        LifeOsDataSnapshot(
          tasks: [taskA, taskB],
          relationships: [relationships.first],
        ),
      ),
      throwsA(anything),
    );

    expect(await database.select(database.taskRecords).get(), hasLength(1));
    expect(await database.select(database.relationshipRecords).get(), isEmpty);
  });

  test(
    'human-readable Export v3 includes Relationships without copied titles',
    () {
      final export = const V3BackupExportEncoder().encodeExport(
        createdAt: timestamp,
        applicationVersion: '1.0.0+1',
        snapshot: LifeOsDataSnapshot(
          tasks: [taskA, taskB],
          relationships: [relationships.first],
        ),
      );
      final decoded = LifeOsDataFormatV3.decodeExport(export);

      expect(decoded.relationships, hasLength(1));
      expect(export, contains('"relationships"'));
      expect(export, isNot(contains('copiedTitle')));
    },
  );
}

LifeOsTask _task(String id, DateTime timestamp) => LifeOsTask.createUserTask(
  id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.task),
  title: 'Task $id',
  timestamp: timestamp,
);

LifeOsNote _note(String id, DateTime timestamp) => LifeOsNote.createUserNote(
  id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.note),
  title: 'Note $id',
  content: ' exact\r\ncontent ',
  timestamp: timestamp,
);

LifeOsRelationship _relationship(
  String id,
  LifeOsEntityId first,
  LifeOsEntityId second,
  DateTime timestamp,
) => LifeOsRelationship.createUserRelationship(
  id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.relationship),
  firstEndpoint: first,
  secondEndpoint: second,
  timestamp: timestamp,
);
