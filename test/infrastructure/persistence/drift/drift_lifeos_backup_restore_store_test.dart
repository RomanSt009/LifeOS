import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/backup/lifeos_backup_export_contracts.dart';
import 'package:lifeos/application/backup/lifeos_backup_restore_contracts.dart';
import 'package:lifeos/application/use_cases/restore_lifeos_backup.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/infrastructure/backup/files/lifeos_backup_file_reader.dart';
import 'package:lifeos/infrastructure/backup/formats/backup_export_format_v1.dart';
import 'package:lifeos/infrastructure/identity/file_device_identity_store.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/production_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_task_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/restore/drift_lifeos_backup_restore_store.dart';
import 'package:path/path.dart' as path;

void main() {
  late LifeOsDatabase database;
  late DriftLifeOsTaskRepository repository;
  late DriftLifeOsBackupRestoreStore restoreStore;
  var changeId = 0;

  setUp(() {
    database = LifeOsDatabase(NativeDatabase.memory());
    repository = DriftLifeOsTaskRepository(
      database,
      () => 'change-${++changeId}',
      'current-device',
    );
    restoreStore = DriftLifeOsBackupRestoreStore(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'atomically replaces Tasks with exact metadata and clears Outbox',
    () async {
      final original = task(
        id: '00000000-0000-4000-8000-000000000010',
        title: 'Original Task',
      );
      final restored = task(
        id: '00000000-0000-4000-8000-000000000020',
        title: 'Restored Task',
        isCompleted: true,
        lifecycle: LifeOsEntityLifecycle.archived,
        version: 9,
        source: LifeOsEntitySource.sync,
        createdAt: DateTime.utc(2025, 1, 2, 3, 4, 5),
        updatedAt: DateTime.utc(2026, 6, 7, 8, 9, 10),
      );
      await repository.save(original);
      expect(await database.select(database.outboxEntries).get(), hasLength(1));

      await restoreStore.replaceAll(LifeOsDataSnapshot(tasks: [restored]));

      expect(await repository.getById(original.id), isNull);
      expect(await repository.getById(restored.id), restored);
      expect(await database.select(database.entities).get(), hasLength(1));
      expect(await database.select(database.taskRecords).get(), hasLength(1));
      expect(await database.select(database.outboxEntries).get(), isEmpty);
    },
  );

  test('rolls back Domain State and Outbox when an insert fails', () async {
    final original = task(
      id: '00000000-0000-4000-8000-000000000010',
      title: 'Original Task',
    );
    await repository.save(original);
    final outboxBefore = await database.select(database.outboxEntries).get();
    await database.customStatement('''
      CREATE TRIGGER fail_restore_task
      BEFORE INSERT ON tasks
      WHEN NEW.title = 'Trigger Restore Failure'
      BEGIN
        SELECT RAISE(ABORT, 'restore failure');
      END
    ''');
    final failingTask = task(
      id: '00000000-0000-4000-8000-000000000020',
      title: 'Trigger Restore Failure',
    );

    await expectLater(
      restoreStore.replaceAll(LifeOsDataSnapshot(tasks: [failingTask])),
      throwsA(
        isA<LifeOsBackupRestoreException>().having(
          (error) => error.code,
          'code',
          LifeOsBackupRestoreErrorCode.persistenceFailure,
        ),
      ),
    );

    expect(await repository.getAll(), [original]);
    expect(await database.select(database.outboxEntries).get(), outboxBefore);
  });

  test(
    'supports restoring into an empty database and an empty snapshot',
    () async {
      expect(await restoreStore.hasRestorableData(), isFalse);
      final restored = task(
        id: '00000000-0000-4000-8000-000000000020',
        title: 'Restored into empty state',
      );

      await restoreStore.replaceAll(LifeOsDataSnapshot(tasks: [restored]));
      expect(await restoreStore.hasRestorableData(), isTrue);
      expect(await repository.getAll(), [restored]);

      await restoreStore.replaceAll(LifeOsDataSnapshot(tasks: const []));
      expect(await restoreStore.hasRestorableData(), isFalse);
      expect(await repository.getAll(), isEmpty);
      expect(await database.select(database.outboxEntries).get(), isEmpty);
    },
  );

  test('confirmation failure preserves real Domain State and Outbox', () async {
    final original = task(
      id: '00000000-0000-4000-8000-000000000010',
      title: 'Original before confirmation',
    );
    await repository.save(original);
    final outboxBefore = await database.select(database.outboxEntries).get();
    final directory = await Directory.systemTemp.createTemp(
      'lifeos-confirmation-restore-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final candidate = <String, Object?>{
      'id': '00000000-0000-4000-8000-000000000020',
      'entityType': 'task',
      'createdAt': '2026-09-01T00:00:00.000Z',
      'updatedAt': '2026-09-02T00:00:00.000Z',
      'lifecycle': 'active',
      'version': 2,
      'source': 'user',
      'title': 'Confirmed replacement',
      'isCompleted': true,
    };
    final backup = await _writeRestoreArchive(
      directory,
      'confirmation.zip',
      utf8.encode(
        jsonEncode({
          'tasks': [candidate],
        }),
      ),
    );
    final restore = RestoreLifeOsBackup(
      reader: const LifeOsBackupFileReader(),
      restoreStore: restoreStore,
    );

    await expectLater(
      restore(sourcePath: backup.path, destructiveReplaceConfirmed: false),
      throwsA(
        isA<LifeOsBackupRestoreException>().having(
          (error) => error.code,
          'code',
          LifeOsBackupRestoreErrorCode.confirmationRequired,
        ),
      ),
    );
    expect(await repository.getAll(), [original]);
    expect(await database.select(database.outboxEntries).get(), outboxBefore);

    await restore(sourcePath: backup.path, destructiveReplaceConfirmed: true);
    expect((await repository.getAll()).single.title, 'Confirmed replacement');
    expect(await database.select(database.outboxEntries).get(), isEmpty);
  });

  test('invalid Backup variants never mutate current persistence', () async {
    final original = task(
      id: '00000000-0000-4000-8000-000000000010',
      title: 'State that must survive validation',
    );
    await repository.save(original);
    final originalOutbox = await database.select(database.outboxEntries).get();
    final directory = await Directory.systemTemp.createTemp(
      'lifeos-invalid-restore-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final identityStore = FileDeviceIdentityStore(
      directory,
      () => 'current-device-identity',
    );
    final deviceIdBefore = await identityStore.resolve();
    final restore = RestoreLifeOsBackup(
      reader: const LifeOsBackupFileReader(),
      restoreStore: restoreStore,
    );
    final validTask = <String, Object?>{
      'id': '00000000-0000-4000-8000-000000000020',
      'entityType': 'task',
      'createdAt': '2026-09-01T00:00:00.000Z',
      'updatedAt': '2026-09-02T00:00:00.000Z',
      'lifecycle': 'active',
      'version': 2,
      'source': 'user',
      'title': 'Candidate Restore Task',
      'isCompleted': false,
    };
    List<int> dataWith(Map<String, Object?> changedTask) => utf8.encode(
      jsonEncode({
        'tasks': [changedTask],
      }),
    );
    final invalidFiles = <File>[
      await _writeRestoreArchive(
        directory,
        'unsupported.zip',
        dataWith(validTask),
        formatVersion: 2,
      ),
      await _writeRestoreArchive(
        directory,
        'checksum.zip',
        dataWith(validTask),
        checksumOverride: '0' * 64,
      ),
      await _writeRestoreArchive(
        directory,
        'malformed-json.zip',
        utf8.encode('{malformed'),
      ),
      await _writeRestoreArchive(
        directory,
        'duplicate-id.zip',
        utf8.encode(
          jsonEncode({
            'tasks': [validTask, validTask],
          }),
        ),
      ),
      await _writeRestoreArchive(
        directory,
        'invalid-uuid.zip',
        dataWith({...validTask, 'id': 'not-a-uuid'}),
      ),
      await _writeRestoreArchive(
        directory,
        'invalid-timestamp.zip',
        dataWith({...validTask, 'createdAt': 'not-a-timestamp'}),
      ),
      await _writeRestoreArchive(
        directory,
        'invalid-entity-type.zip',
        dataWith({...validTask, 'entityType': 'note'}),
      ),
      await _writeRestoreArchive(
        directory,
        'invalid-enum.zip',
        dataWith({...validTask, 'lifecycle': 'unknown'}),
      ),
      await _writeRestoreArchive(
        directory,
        'invalid-source.zip',
        dataWith({...validTask, 'source': 'unknown'}),
      ),
      await _writeRestoreArchive(
        directory,
        'invalid-version.zip',
        dataWith({...validTask, 'version': 0}),
      ),
      await _writeRestoreArchive(
        directory,
        'inconsistent-timestamps.zip',
        dataWith({
          ...validTask,
          'createdAt': '2026-09-03T00:00:00.000Z',
          'updatedAt': '2026-09-02T00:00:00.000Z',
        }),
      ),
      await _writeRestoreArchive(
        directory,
        'missing-title.zip',
        dataWith(Map<String, Object?>.from(validTask)..remove('title')),
      ),
    ];
    final malformedZip = File(path.join(directory.path, 'malformed.zip'));
    await malformedZip.writeAsBytes([1, 2, 3], flush: true);
    invalidFiles.add(malformedZip);

    for (final invalidFile in invalidFiles) {
      await expectLater(
        restore(
          sourcePath: invalidFile.path,
          destructiveReplaceConfirmed: true,
        ),
        throwsA(isA<LifeOsBackupRestoreException>()),
        reason: path.basename(invalidFile.path),
      );
      expect(await repository.getAll(), [original]);
      expect(
        await database.select(database.outboxEntries).get(),
        originalOutbox,
      );
      expect(await identityStore.resolve(), deviceIdBefore);
    }
  });

  test(
    'persists Restore across close/reopen and preserves device identity',
    () async {
      await database.close();
      final directory = await Directory.systemTemp.createTemp(
        'lifeos-restore-reopen-',
      );
      var identityGenerationCount = 0;
      final identityStore = FileDeviceIdentityStore(
        directory,
        () => 'device-${++identityGenerationCount}',
      );
      final deviceIdBefore = await identityStore.resolve();
      database = await openProductionDatabaseIn(directory);
      repository = DriftLifeOsTaskRepository(
        database,
        () => 'file-change',
        deviceIdBefore,
      );
      final original = task(
        id: '00000000-0000-4000-8000-000000000010',
        title: 'File-backed original',
      );
      final restored = task(
        id: '00000000-0000-4000-8000-000000000020',
        title: 'File-backed restored',
        isCompleted: true,
        lifecycle: LifeOsEntityLifecycle.deleted,
        version: 4,
        source: LifeOsEntitySource.import,
        createdAt: DateTime.utc(2025, 2, 3),
        updatedAt: DateTime.utc(2026, 4, 5),
      );
      await repository.save(original);

      await DriftLifeOsBackupRestoreStore(database)
          .replaceAll(LifeOsDataSnapshot(tasks: [restored]));
      await database.close();
      database = await openProductionDatabaseIn(directory);
      repository = DriftLifeOsTaskRepository(
        database,
        () => 'unused-change',
        deviceIdBefore,
      );
      final deviceIdAfter = await FileDeviceIdentityStore(
        directory,
        () => 'unexpected-new-device',
      ).resolve();

      expect(await repository.getAll(), [restored]);
      expect(await database.select(database.outboxEntries).get(), isEmpty);
      expect(deviceIdAfter, deviceIdBefore);
      expect(identityGenerationCount, 1);
      await database.close();
      database = LifeOsDatabase(NativeDatabase.memory());
      await directory.delete(recursive: true);
    },
  );
}

Future<File> _writeRestoreArchive(
  Directory directory,
  String name,
  List<int> dataBytes, {
  int formatVersion = lifeOsBackupFormatVersion,
  String? checksumOverride,
}) async {
  final manifestBytes = utf8.encode(
    jsonEncode({
      'format': lifeOsBackupFormatKind,
      'formatVersion': formatVersion,
      'createdAt': '2026-09-11T12:00:00.000Z',
      'applicationId': lifeOsApplicationId,
      'applicationVersion': '1.0.0+1',
      'sourceDatabaseSchemaVersion': 1,
      'requiredSections': [lifeOsBackupDataFileName],
      'dataSha256': checksumOverride ?? sha256.convert(dataBytes).toString(),
    }),
  );
  final archive = Archive()
    ..addFile(
      ArchiveFile(
        lifeOsBackupManifestFileName,
        manifestBytes.length,
        manifestBytes,
      ),
    )
    ..addFile(
      ArchiveFile(lifeOsBackupDataFileName, dataBytes.length, dataBytes),
    );
  final file = File(path.join(directory.path, name));
  await file.writeAsBytes(
    ZipEncoder().encode(archive, modified: DateTime.utc(2026, 9, 11))!,
    flush: true,
  );
  return file;
}

LifeOsTask task({
  required String id,
  required String title,
  bool isCompleted = false,
  LifeOsEntityLifecycle lifecycle = LifeOsEntityLifecycle.active,
  int version = 1,
  LifeOsEntitySource source = LifeOsEntitySource.user,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 9, 1);
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
