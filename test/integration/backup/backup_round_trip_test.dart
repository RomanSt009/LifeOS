import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/dependencies.dart';
import 'package:lifeos/application/backup/lifeos_backup_operations.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/infrastructure/backup/formats/backup_export_format_v1.dart';
import 'package:lifeos/infrastructure/backup/formats/backup_export_format_v2.dart';
import 'package:lifeos/infrastructure/identity/file_device_identity_store.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory root;
  late List<LifeOsAppDependencies> openedDependencies;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('lifeos-be08-round-trip-');
    openedDependencies = [];
  });

  tearDown(() async {
    for (final dependencies in openedDependencies.reversed) {
      await dependencies.close();
    }
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  Future<LifeOsAppDependencies> openInstallation(
    String directoryName,
    String deviceId, {
    DateTime? timestamp,
  }) async {
    final supportDirectory = Directory(path.join(root.path, directoryName));
    var generatedCount = 0;
    final dependencies = await createProductionDependencies(
      applicationSupportDirectoryProvider: () async => supportDirectory,
      identifierGenerator: () {
        generatedCount += 1;
        return generatedCount == 1
            ? deviceId
            : '$deviceId-change-$generatedCount';
      },
      entityIdGenerator: () => '00000000-0000-4000-8000-000000000099',
      utcClock: () => timestamp ?? DateTime.utc(2026, 9, 11, 12),
    );
    openedDependencies.add(dependencies);
    return dependencies;
  }

  test(
    'round-trips full Domain State into a separate installation and reopen',
    () async {
      final source = await openInstallation('source', 'source-device');
      final sourceTasks = [
        _task(
          id: '00000000-0000-4000-8000-000000000003',
          title: 'Deleted system Task',
          isCompleted: true,
          lifecycle: LifeOsEntityLifecycle.deleted,
          version: 8,
          source: LifeOsEntitySource.system,
          createdAt: DateTime.utc(2024, 1, 2, 3, 4, 5),
          updatedAt: DateTime.utc(2026, 8, 9, 10, 11, 12),
        ),
        _task(
          id: '00000000-0000-4000-8000-000000000001',
          title: 'Active user Task',
          createdAt: DateTime.utc(2025, 2, 3, 4, 5, 6),
          updatedAt: DateTime.utc(2025, 2, 3, 4, 5, 6),
        ),
        _task(
          id: '00000000-0000-4000-8000-000000000002',
          title: 'Archived imported Task',
          lifecycle: LifeOsEntityLifecycle.archived,
          version: 4,
          source: LifeOsEntitySource.import,
          createdAt: DateTime.utc(2025, 5, 6, 7, 8, 9),
          updatedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
        ),
      ];
      for (final task in sourceTasks) {
        await source.taskRepository.save(task);
      }
      final sourceNote = LifeOsNote(
        id: const LifeOsEntityId(
          value: '00000000-0000-4000-8000-000000000004',
          entityType: LifeOsEntityType.note,
        ),
        title: 'Imported Note',
        content: '  exact\r\nNote content  ',
        createdAt: DateTime.utc(2025, 6, 7, 8, 9, 10),
        updatedAt: DateTime.utc(2026, 7, 8, 9, 10, 11),
        lifecycle: LifeOsEntityLifecycle.archived,
        version: 5,
        source: LifeOsEntitySource.import,
      );
      await source.noteRepository.save(sourceNote);
      expect(
        await source.taskRepository.getAll(),
        unorderedEquals(sourceTasks),
      );
      expect(await source.noteRepository.getAll(), [sourceNote]);
      expect(await _outbox(source), hasLength(4));
      await source.close();

      final persistedSource = await openInstallation(
        'source',
        'unexpected-source-device',
      );
      expect(
        await persistedSource.taskRepository.getAll(),
        unorderedEquals(sourceTasks),
      );
      expect(await persistedSource.noteRepository.getAll(), [sourceNote]);
      expect(await _outbox(persistedSource), hasLength(4));
      expect(await _deviceId(root, 'source'), 'source-device');

      final backupPath = path.join(root.path, 'cross-installation.zip');
      await persistedSource.backupOperations.createBackupAt(backupPath);
      final secondBackupPath = path.join(
        root.path,
        'cross-installation-second.zip',
      );
      await persistedSource.backupOperations.createBackupAt(secondBackupPath);
      final backupBytes = await File(backupPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(backupBytes, verify: true);
      expect(archive.map((entry) => entry.name).toSet(), {
        lifeOsBackupManifestFileName,
        lifeOsBackupDataFileName,
      });
      expect(archive, hasLength(2));
      final artifactText = archive
          .map((entry) => utf8.decode(entry.content as List<int>))
          .join();
      expect(artifactText, isNot(contains('source-device')));
      expect(artifactText, isNot(contains('outbox')));
      expect(artifactText, isNot(contains('changeId')));
      final secondArchive = ZipDecoder().decodeBytes(
        await File(secondBackupPath).readAsBytes(),
        verify: true,
      );
      expect(
        secondArchive.findFile(lifeOsBackupDataFileName)!.content,
        archive.findFile(lifeOsBackupDataFileName)!.content,
      );
      await persistedSource.close();

      final target = await openInstallation('target', 'target-device');
      expect(await _deviceId(root, 'target'), 'target-device');
      await target.backupOperations.restoreBackupFrom(
        backupPath,
        destructiveReplaceConfirmed: false,
      );
      expect(
        await target.taskRepository.getAll(),
        unorderedEquals(sourceTasks),
      );
      expect(await target.noteRepository.getAll(), [sourceNote]);
      expect(await _outbox(target), isEmpty);
      expect(await _deviceId(root, 'target'), 'target-device');
      expect(await _deviceId(root, 'target'), isNot('source-device'));
      await target.close();

      final reopened = await openInstallation('target', 'unexpected-device');
      expect(
        await reopened.taskRepository.getAll(),
        unorderedEquals(sourceTasks),
      );
      expect(await reopened.noteRepository.getAll(), [sourceNote]);
      expect(await _outbox(reopened), isEmpty);
      expect(await _deviceId(root, 'target'), 'target-device');
    },
  );

  test('restores an earlier snapshot in the same installation', () async {
    final installation = await openInstallation('same', 'same-device');
    final snapshotTask = _task(
      id: '00000000-0000-4000-8000-000000000010',
      title: 'Snapshot Task',
      version: 3,
      source: LifeOsEntitySource.ai,
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 2, 1),
    );
    await installation.taskRepository.save(snapshotTask);
    final backupPath = path.join(root.path, 'same-installation.zip');
    await installation.backupOperations.createBackupAt(backupPath);

    final changedTask = LifeOsTask(
      id: snapshotTask.id,
      title: 'Changed after Backup',
      isCompleted: true,
      createdAt: snapshotTask.createdAt,
      updatedAt: DateTime.utc(2026, 9, 11, 13),
      lifecycle: snapshotTask.lifecycle,
      version: snapshotTask.version + 1,
      source: snapshotTask.source,
    );
    final postBackupTask = _task(
      id: '00000000-0000-4000-8000-000000000011',
      title: 'Created after Backup',
    );
    await installation.taskRepository.save(changedTask);
    await installation.taskRepository.save(postBackupTask);
    expect(await _outbox(installation), hasLength(3));

    await installation.backupOperations.restoreBackupFrom(
      backupPath,
      destructiveReplaceConfirmed: true,
    );
    expect(await installation.taskRepository.getAll(), [snapshotTask]);
    expect(await _outbox(installation), isEmpty);
    expect(await _deviceId(root, 'same'), 'same-device');
    await installation.close();

    final reopened = await openInstallation('same', 'unexpected-device');
    expect(await reopened.taskRepository.getAll(), [snapshotTask]);
    expect(await _outbox(reopened), isEmpty);
    expect(await _deviceId(root, 'same'), 'same-device');
  });

  test('restores an empty snapshot over non-empty state and reopen', () async {
    final emptySource = await openInstallation('empty-source', 'empty-source');
    final backupPath = path.join(root.path, 'empty.zip');
    await emptySource.backupOperations.createBackupAt(backupPath);
    await emptySource.close();

    final target = await openInstallation('empty-target', 'empty-target');
    await target.taskRepository.save(
      _task(
        id: '00000000-0000-4000-8000-000000000020',
        title: 'Removed by empty Restore',
      ),
    );
    await target.backupOperations.restoreBackupFrom(
      backupPath,
      destructiveReplaceConfirmed: true,
    );
    expect(await target.taskRepository.getAll(), isEmpty);
    expect(await _outbox(target), isEmpty);
    expect(await _deviceId(root, 'empty-target'), 'empty-target');
    await target.close();

    final reopened = await openInstallation(
      'empty-target',
      'unexpected-device',
    );
    expect(await reopened.taskRepository.getAll(), isEmpty);
    expect(await _outbox(reopened), isEmpty);
    expect(await _deviceId(root, 'empty-target'), 'empty-target');
  });

  test('writes deterministic Export and preserves fail-if-exists', () async {
    final installation = await openInstallation('export', 'export-device');
    final tasks = [
      _task(
        id: '00000000-0000-4000-8000-000000000032',
        title: 'Second by UUID',
        isCompleted: true,
        version: 2,
      ),
      _task(
        id: '00000000-0000-4000-8000-000000000031',
        title: 'First by UUID',
        lifecycle: LifeOsEntityLifecycle.archived,
        source: LifeOsEntitySource.sync,
      ),
    ];
    for (final task in tasks) {
      await installation.taskRepository.save(task);
    }
    final note = LifeOsNote.createUserNote(
      id: const LifeOsEntityId(
        value: '00000000-0000-4000-8000-000000000033',
        entityType: LifeOsEntityType.note,
      ),
      title: 'Exported Note',
      content: ' exact export content ',
      timestamp: DateTime.utc(2026, 9, 11, 11),
    );
    await installation.noteRepository.save(note);
    final firstPath = path.join(root.path, 'export-1.json');
    final secondPath = path.join(root.path, 'export-2.json');
    await installation.backupOperations.exportDataAt(firstPath);
    await installation.backupOperations.exportDataAt(secondPath);

    final firstBytes = await File(firstPath).readAsBytes();
    expect(await File(secondPath).readAsBytes(), firstBytes);
    final source = utf8.decode(firstBytes);
    final json = jsonDecode(source) as Map<String, dynamic>;
    final document = LifeOsDataFormatV2.decodeExport(source);
    expect(json['format'], lifeOsExportFormatKind);
    expect(json['formatVersion'], lifeOsExportFormatVersionV2);
    expect(document.tasks.map((task) => task.id), [
      '00000000-0000-4000-8000-000000000031',
      '00000000-0000-4000-8000-000000000032',
    ]);
    expect(
      document.tasks.map((record) => record.toDomain()),
      orderedEquals([tasks[1], tasks[0]]),
    );
    expect(document.notes.map((record) => record.toDomain()), [note]);
    expect(source, isNot(contains('outbox')));
    expect(source, isNot(contains('changeId')));
    expect(source, isNot(contains('deviceId')));
    expect(await _outbox(installation), hasLength(3));

    final originalBytes = List<int>.from(firstBytes);
    await expectLater(
      installation.backupOperations.exportDataAt(firstPath),
      _throwsOperation(LifeOsBackupOperationErrorCode.destinationAlreadyExists),
    );
    expect(await File(firstPath).readAsBytes(), originalBytes);
    expect(await _temporarySiblings(firstPath), isEmpty);

    final backupPath = path.join(root.path, 'fail-if-exists.zip');
    await installation.backupOperations.createBackupAt(backupPath);
    final originalBackupBytes = await File(backupPath).readAsBytes();
    await expectLater(
      installation.backupOperations.createBackupAt(backupPath),
      _throwsOperation(LifeOsBackupOperationErrorCode.destinationAlreadyExists),
    );
    expect(await File(backupPath).readAsBytes(), originalBackupBytes);
    expect(await _temporarySiblings(backupPath), isEmpty);
  });
}

LifeOsTask _task({
  required String id,
  required String title,
  bool isCompleted = false,
  LifeOsEntityLifecycle lifecycle = LifeOsEntityLifecycle.active,
  int version = 1,
  LifeOsEntitySource source = LifeOsEntitySource.user,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 1, 1);
  return LifeOsTask(
    id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.task),
    title: title,
    isCompleted: isCompleted,
    createdAt: created,
    updatedAt: updatedAt ?? created,
    lifecycle: lifecycle,
    version: version,
    source: source,
  );
}

Future<List<Object>> _outbox(LifeOsAppDependencies dependencies) async {
  return dependencies.database
      .select(dependencies.database.outboxEntries)
      .get();
}

Future<String> _deviceId(Directory root, String directoryName) {
  return FileDeviceIdentityStore(
    Directory(path.join(root.path, directoryName)),
    () => 'unexpected-device',
  ).resolve();
}

Matcher _throwsOperation(LifeOsBackupOperationErrorCode code) {
  return throwsA(
    isA<LifeOsBackupOperationException>().having(
      (error) => error.code,
      'code',
      code,
    ),
  );
}

Future<List<FileSystemEntity>> _temporarySiblings(String destinationPath) {
  final destinationName = path.basename(destinationPath);
  return Directory(path.dirname(destinationPath))
      .list()
      .where(
        (entry) =>
            path.basename(entry.path).startsWith('.$destinationName.lifeos-'),
      )
      .toList();
}
