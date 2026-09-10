import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/infrastructure/backup/formats/backup_export_format_v1.dart';

void main() {
  const firstId = '00000000-0000-4000-8000-000000000001';
  const secondId = '00000000-0000-4000-8000-000000000002';
  const sha256 =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  final createdAt = DateTime.utc(2026, 9, 11, 10, 30);
  final updatedAt = DateTime.utc(2026, 9, 11, 11, 45);

  BackupTaskRecordV1 task({
    String id = firstId,
    LifeOsEntityLifecycle lifecycle = LifeOsEntityLifecycle.active,
    LifeOsEntitySource source = LifeOsEntitySource.user,
    int version = 2,
    bool isCompleted = true,
  }) {
    return BackupTaskRecordV1(
      id: id,
      entityType: LifeOsEntityType.task,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lifecycle: lifecycle,
      version: version,
      source: source,
      title: 'Preserve every Task field',
      isCompleted: isCompleted,
    );
  }

  test('round-trips the v1 Backup manifest contract', () {
    final manifest = BackupManifestV1(
      createdAt: createdAt,
      applicationVersion: '1.0.0+1',
      sourceDatabaseSchemaVersion: 1,
      requiredSections: const [lifeOsBackupDataFileName],
      dataSha256: sha256,
    );

    final encoded = LifeOsDataFormatV1.encodeBackupManifest(manifest);
    final decoded = LifeOsDataFormatV1.decodeBackupManifest(encoded);
    final json = jsonDecode(encoded) as Map<String, dynamic>;

    expect(json, {
      'format': lifeOsBackupFormatKind,
      'formatVersion': lifeOsBackupFormatVersion,
      'createdAt': '2026-09-11T10:30:00.000Z',
      'applicationId': lifeOsApplicationId,
      'applicationVersion': '1.0.0+1',
      'sourceDatabaseSchemaVersion': 1,
      'requiredSections': [lifeOsBackupDataFileName],
      'dataSha256': sha256,
    });
    expect(decoded.formatVersion, lifeOsBackupFormatVersion);
    expect(decoded.createdAt, createdAt);
    expect(decoded.applicationVersion, '1.0.0+1');
    expect(decoded.sourceDatabaseSchemaVersion, 1);
    expect(decoded.requiredSections, [lifeOsBackupDataFileName]);
    expect(decoded.dataSha256, sha256);
  });

  test('round-trips every Task field through logical Backup data', () {
    final original = task(
      lifecycle: LifeOsEntityLifecycle.archived,
      source: LifeOsEntitySource.import,
    );

    final encoded = LifeOsDataFormatV1.encodeBackupData(
      BackupSnapshotV1(tasks: [original]),
    );
    final decoded = LifeOsDataFormatV1.decodeBackupData(encoded).tasks.single;

    expect(decoded.id, original.id);
    expect(decoded.entityType, LifeOsEntityType.task);
    expect(decoded.createdAt, createdAt);
    expect(decoded.updatedAt, updatedAt);
    expect(decoded.lifecycle, LifeOsEntityLifecycle.archived);
    expect(decoded.version, 2);
    expect(decoded.source, LifeOsEntitySource.import);
    expect(decoded.title, original.title);
    expect(decoded.isCompleted, isTrue);
    expect(decoded.toDomain(), original.toDomain());
  });

  test('maps a Domain Task without changing identity or metadata', () {
    final domainTask = LifeOsTask(
      id: const LifeOsEntityId(
        value: firstId,
        entityType: LifeOsEntityType.task,
      ),
      title: 'Domain source',
      isCompleted: false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lifecycle: LifeOsEntityLifecycle.deleted,
      version: 4,
      source: LifeOsEntitySource.sync,
    );

    expect(BackupTaskRecordV1.fromDomain(domainTask).toDomain(), domainTask);
  });

  test('orders Backup and Export Tasks by Entity UUID ascending', () {
    final laterId = task(id: secondId);
    final earlierId = task(id: firstId);

    final backupJson = jsonDecode(
      LifeOsDataFormatV1.encodeBackupData(
        BackupSnapshotV1(tasks: [laterId, earlierId]),
      ),
    ) as Map<String, dynamic>;
    final exportJson = jsonDecode(
      LifeOsDataFormatV1.encodeExport(
        ExportDocumentV1(
          createdAt: createdAt,
          applicationVersion: '1.0.0+1',
          tasks: [laterId, earlierId],
        ),
      ),
    ) as Map<String, dynamic>;

    expect(
      (backupJson['tasks'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((record) => record['id']),
      [firstId, secondId],
    );
    expect(
      (exportJson['tasks'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((record) => record['id']),
      [firstId, secondId],
    );
  });

  test('writes a separate human-readable v1 Export envelope', () {
    final encoded = LifeOsDataFormatV1.encodeExport(
      ExportDocumentV1(
        createdAt: createdAt,
        applicationVersion: '1.0.0+1',
        tasks: [
          task(lifecycle: LifeOsEntityLifecycle.deleted, version: 5),
        ],
      ),
    );
    final decoded = LifeOsDataFormatV1.decodeExport(encoded);
    final json = jsonDecode(encoded) as Map<String, dynamic>;

    expect(encoded, contains('\n  "format": "lifeos-export"'));
    expect(json['formatVersion'], lifeOsExportFormatVersion);
    expect(json, isNot(contains('sourceDatabaseSchemaVersion')));
    expect(decoded.tasks.single.lifecycle, LifeOsEntityLifecycle.deleted);
    expect(decoded.tasks.single.version, 5);
  });

  test('excludes Outbox, change and device identity from both formats', () {
    final backup = LifeOsDataFormatV1.encodeBackupData(
      BackupSnapshotV1(tasks: [task()]),
    );
    final export = LifeOsDataFormatV1.encodeExport(
      ExportDocumentV1(
        createdAt: createdAt,
        applicationVersion: '1.0.0+1',
        tasks: [task()],
      ),
    );

    for (final encoded in [backup, export]) {
      expect(encoded, isNot(contains('outbox')));
      expect(encoded, isNot(contains('changeId')));
      expect(encoded, isNot(contains('deviceId')));
      expect(encoded, isNot(contains('lifeos.db')));
    }
  });

  test('rejects missing required fields and malformed JSON', () {
    expect(
      () => LifeOsDataFormatV1.decodeBackupData('{"tasks": [{"id": "$firstId"}]}'),
      throwsFormatError(LifeOsDataFormatErrorCode.missingField),
    );
    expect(
      () => LifeOsDataFormatV1.decodeBackupData('{broken'),
      throwsFormatError(LifeOsDataFormatErrorCode.malformedJson),
    );
  });

  test('rejects invalid enum values and unknown Entity types', () {
    final validTask = task().toJson();
    final invalidLifecycle = {...validTask, 'lifecycle': 'unknown'};
    final unknownEntity = {...validTask, 'entityType': 'note'};

    expect(
      () => decodeTasks([invalidLifecycle]),
      throwsFormatError(LifeOsDataFormatErrorCode.invalidField),
    );
    expect(
      () => decodeTasks([unknownEntity]),
      throwsFormatError(LifeOsDataFormatErrorCode.invalidField),
    );
  });

  test('rejects duplicate Entity UUIDs', () {
    expect(
      () => BackupSnapshotV1(tasks: [task(), task()]),
      throwsFormatError(LifeOsDataFormatErrorCode.duplicateEntityId),
    );
  });

  test('rejects invalid UUID and non-UTC timestamp representations', () {
    final validTask = task().toJson();
    final invalidUuid = {...validTask, 'id': 'not-a-uuid'};
    final nonCanonicalUuid = {
      ...validTask,
      'id': '00000000-0000-4000-8000-00000000000A',
    };
    final nonUtcTimestamp = {
      ...validTask,
      'updatedAt': '2026-09-11T14:45:00+03:00',
    };

    expect(
      () => decodeTasks([invalidUuid]),
      throwsFormatError(LifeOsDataFormatErrorCode.invalidField),
    );
    expect(
      () => decodeTasks([nonCanonicalUuid]),
      throwsFormatError(LifeOsDataFormatErrorCode.invalidField),
    );
    expect(
      () => decodeTasks([nonUtcTimestamp]),
      throwsFormatError(LifeOsDataFormatErrorCode.invalidField),
    );
  });

  test('rejects unsupported Backup and Export format versions', () {
    final manifest = BackupManifestV1(
      createdAt: createdAt,
      applicationVersion: '1.0.0+1',
      sourceDatabaseSchemaVersion: 1,
      requiredSections: const [lifeOsBackupDataFileName],
      dataSha256: sha256,
    ).toJson()..['formatVersion'] = 2;
    final export = ExportDocumentV1(
      createdAt: createdAt,
      applicationVersion: '1.0.0+1',
      tasks: [task()],
    ).toJson()..['formatVersion'] = 2;

    expect(
      () => LifeOsDataFormatV1.decodeBackupManifest(jsonEncode(manifest)),
      throwsFormatError(LifeOsDataFormatErrorCode.unsupportedVersion),
    );
    expect(
      () => LifeOsDataFormatV1.decodeExport(jsonEncode(export)),
      throwsFormatError(LifeOsDataFormatErrorCode.unsupportedVersion),
    );
  });

  test('ignores unknown optional JSON fields', () {
    final taskJson = {...task().toJson(), 'futureTaskField': 'ignored'};
    final export = ExportDocumentV1(
      createdAt: createdAt,
      applicationVersion: '1.0.0+1',
      tasks: [task()],
    ).toJson()
      ..['futureTopLevelField'] = true
      ..['tasks'] = [taskJson];

    final decoded = LifeOsDataFormatV1.decodeExport(jsonEncode(export));

    expect(decoded.tasks.single.id, firstId);
  });
}

BackupSnapshotV1 decodeTasks(List<Map<String, Object>> tasks) {
  return LifeOsDataFormatV1.decodeBackupData(jsonEncode({'tasks': tasks}));
}

Matcher throwsFormatError(LifeOsDataFormatErrorCode code) {
  return throwsA(
    isA<LifeOsDataFormatException>().having(
      (error) => error.code,
      'code',
      code,
    ),
  );
}
