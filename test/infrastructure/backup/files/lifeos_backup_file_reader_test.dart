import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/backup/lifeos_backup_restore_contracts.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/infrastructure/backup/files/lifeos_backup_file_reader.dart';
import 'package:lifeos/infrastructure/backup/formats/backup_export_format_v1.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory temporaryDirectory;
  late LifeOsBackupFileReader reader;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'lifeos-backup-reader-test-',
    );
    reader = const LifeOsBackupFileReader();
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  Future<File> writeArchive(
    String name,
    List<MapEntry<String, List<int>>> entries,
  ) async {
    final output = OutputStream();
    final encoder = ZipEncoder();
    encoder.startEncode(output, modified: DateTime.utc(2026, 9, 11));
    for (final entry in entries) {
      encoder.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }
    encoder.endEncode();
    final bytes = output.getBytes();
    final file = File(path.join(temporaryDirectory.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  test('reads a validated Backup ZIP into Domain Tasks', () async {
    final file = await writeArchive('valid.zip', validEntries());

    final snapshot = await reader.read(file.path);

    expect(snapshot.tasks, hasLength(1));
    final task = snapshot.tasks.single;
    expect(task.id.value, '00000000-0000-4000-8000-000000000001');
    expect(task.entityType, LifeOsEntityType.task);
    expect(task.createdAt, DateTime.utc(2026, 9, 1, 10));
    expect(task.updatedAt, DateTime.utc(2026, 9, 2, 11));
    expect(task.lifecycle, LifeOsEntityLifecycle.archived);
    expect(task.version, 7);
    expect(task.source, LifeOsEntitySource.sync);
    expect(task.title, 'Restored Task');
    expect(task.isCompleted, isTrue);
  });

  test('rejects missing, duplicate, and unknown ZIP entries', () async {
    final valid = validEntries();
    final cases = <String, List<MapEntry<String, List<int>>>>{
      'missing-manifest.zip': [valid[1]],
      'missing-data.zip': [valid[0]],
      'duplicate-manifest.zip': [valid[0], valid[0], valid[1]],
      'duplicate-data.zip': [valid[0], valid[1], valid[1]],
      'unknown-entry.zip': [
        valid[0],
        valid[1],
        const MapEntry('extra.json', [123, 125]),
      ],
    };

    for (final entry in cases.entries) {
      final file = await writeArchive(entry.key, entry.value);
      await expectLater(
        reader.read(file.path),
        throwsRestoreError(LifeOsBackupRestoreErrorCode.invalidContainer),
        reason: entry.key,
      );
    }
  });

  test(
    'rejects malformed ZIP and unreadable files with typed errors',
    () async {
      final malformed = File(path.join(temporaryDirectory.path, 'broken.zip'));
      await malformed.writeAsBytes([1, 2, 3, 4], flush: true);

      await expectLater(
        reader.read(malformed.path),
        throwsRestoreError(LifeOsBackupRestoreErrorCode.invalidContainer),
      );
      await expectLater(
        reader.read(path.join(temporaryDirectory.path, 'missing.zip')),
        throwsRestoreError(LifeOsBackupRestoreErrorCode.unreadableFile),
      );

      final valid = await writeArchive(
        'valid-for-truncation.zip',
        validEntries(),
      );
      final validBytes = await valid.readAsBytes();
      final truncated = File(
        path.join(temporaryDirectory.path, 'truncated.zip'),
      );
      await truncated.writeAsBytes(
        validBytes.sublist(0, validBytes.length - 8),
        flush: true,
      );
      await expectLater(
        reader.read(truncated.path),
        throwsRestoreError(LifeOsBackupRestoreErrorCode.invalidContainer),
      );
    },
  );

  test('rejects invalid UTF-8 in manifest and data', () async {
    final valid = validEntries();
    final invalidManifest = await writeArchive('manifest-utf8.zip', [
      const MapEntry(lifeOsBackupManifestFileName, [0xff]),
      valid[1],
    ]);
    final invalidDataBytes = [0xff];
    final manifestForInvalidData = manifestBytes(dataBytes: invalidDataBytes);
    final invalidData = await writeArchive('data-utf8.zip', [
      MapEntry(lifeOsBackupManifestFileName, manifestForInvalidData),
      MapEntry(lifeOsBackupDataFileName, invalidDataBytes),
    ]);

    await expectLater(
      reader.read(invalidManifest.path),
      throwsRestoreError(LifeOsBackupRestoreErrorCode.invalidData),
    );
    await expectLater(
      reader.read(invalidData.path),
      throwsRestoreError(LifeOsBackupRestoreErrorCode.invalidData),
    );
  });

  test('distinguishes checksum and unsupported-version failures', () async {
    final dataBytes = validDataBytes();
    final mismatch = await writeArchive('checksum.zip', [
      MapEntry(
        lifeOsBackupManifestFileName,
        manifestBytes(dataBytes: utf8.encode('{"tasks":[]}')),
      ),
      MapEntry(lifeOsBackupDataFileName, dataBytes),
    ]);
    final unsupportedManifest = jsonEncode({
      'format': lifeOsBackupFormatKind,
      'formatVersion': 99,
      'createdAt': '2026-09-11T12:00:00.000Z',
      'applicationId': lifeOsApplicationId,
      'applicationVersion': '1.0.0+1',
      'sourceDatabaseSchemaVersion': 1,
      'requiredSections': [lifeOsBackupDataFileName],
      'dataSha256': sha256.convert(dataBytes).toString(),
    });
    final unsupported = await writeArchive('unsupported.zip', [
      MapEntry(lifeOsBackupManifestFileName, utf8.encode(unsupportedManifest)),
      MapEntry(lifeOsBackupDataFileName, dataBytes),
    ]);

    await expectLater(
      reader.read(mismatch.path),
      throwsRestoreError(LifeOsBackupRestoreErrorCode.checksumMismatch),
    );
    await expectLater(
      reader.read(unsupported.path),
      throwsRestoreError(LifeOsBackupRestoreErrorCode.unsupportedFormat),
    );
  });

  test('hashes exact physical data.json bytes', () async {
    final originalData = validDataBytes();
    final oneByteChanged = List<int>.from(originalData);
    final titleByte = oneByteChanged.indexOf('R'.codeUnitAt(0));
    expect(titleByte, isNonNegative);
    oneByteChanged[titleByte] = 'r'.codeUnitAt(0);
    final changedByte = await writeArchive('changed-byte.zip', [
      MapEntry(
        lifeOsBackupManifestFileName,
        manifestBytes(dataBytes: originalData),
      ),
      MapEntry(lifeOsBackupDataFileName, oneByteChanged),
    ]);
    final whitespaceChanged = await writeArchive('changed-whitespace.zip', [
      MapEntry(
        lifeOsBackupManifestFileName,
        manifestBytes(dataBytes: originalData),
      ),
      MapEntry(lifeOsBackupDataFileName, [...originalData, 0x20]),
    ]);

    for (final file in [changedByte, whitespaceChanged]) {
      await expectLater(
        reader.read(file.path),
        throwsRestoreError(LifeOsBackupRestoreErrorCode.checksumMismatch),
      );
    }
  });

  test('rejects malformed JSON and invalid logical Task data', () async {
    final malformedManifest = await writeArchive('malformed-manifest.zip', [
      MapEntry(lifeOsBackupManifestFileName, utf8.encode('{malformed')),
      MapEntry(lifeOsBackupDataFileName, validDataBytes()),
    ]);
    final malformedData = utf8.encode('{malformed');
    final malformed = await writeArchive('malformed-json.zip', [
      MapEntry(
        lifeOsBackupManifestFileName,
        manifestBytes(dataBytes: malformedData),
      ),
      MapEntry(lifeOsBackupDataFileName, malformedData),
    ]);
    final duplicateData = utf8.encode(
      jsonEncode({
        'tasks': [validTaskJson(), validTaskJson()],
      }),
    );
    final duplicate = await writeArchive('duplicate-id.zip', [
      MapEntry(
        lifeOsBackupManifestFileName,
        manifestBytes(dataBytes: duplicateData),
      ),
      MapEntry(lifeOsBackupDataFileName, duplicateData),
    ]);

    await expectLater(
      reader.read(malformedManifest.path),
      throwsRestoreError(LifeOsBackupRestoreErrorCode.invalidData),
    );
    await expectLater(
      reader.read(malformed.path),
      throwsRestoreError(LifeOsBackupRestoreErrorCode.invalidData),
    );
    await expectLater(
      reader.read(duplicate.path),
      throwsRestoreError(LifeOsBackupRestoreErrorCode.invalidData),
    );
  });
}

List<MapEntry<String, List<int>>> validEntries() {
  final dataBytes = validDataBytes();
  return [
    MapEntry(lifeOsBackupManifestFileName, manifestBytes(dataBytes: dataBytes)),
    MapEntry(lifeOsBackupDataFileName, dataBytes),
  ];
}

List<int> validDataBytes() {
  return utf8.encode(
    LifeOsDataFormatV1.encodeBackupData(
      BackupSnapshotV1(
        tasks: [
          BackupTaskRecordV1(
            id: '00000000-0000-4000-8000-000000000001',
            entityType: LifeOsEntityType.task,
            createdAt: DateTime.utc(2026, 9, 1, 10),
            updatedAt: DateTime.utc(2026, 9, 2, 11),
            lifecycle: LifeOsEntityLifecycle.archived,
            version: 7,
            source: LifeOsEntitySource.sync,
            title: 'Restored Task',
            isCompleted: true,
          ),
        ],
      ),
    ),
  );
}

List<int> manifestBytes({required List<int> dataBytes}) {
  return utf8.encode(
    LifeOsDataFormatV1.encodeBackupManifest(
      BackupManifestV1(
        createdAt: DateTime.utc(2026, 9, 11, 12),
        applicationVersion: '1.0.0+1',
        sourceDatabaseSchemaVersion: 1,
        requiredSections: const [lifeOsBackupDataFileName],
        dataSha256: sha256.convert(dataBytes).toString(),
      ),
    ),
  );
}

Map<String, Object> validTaskJson() => {
  'id': '00000000-0000-4000-8000-000000000001',
  'entityType': 'task',
  'createdAt': '2026-09-01T10:00:00.000Z',
  'updatedAt': '2026-09-02T11:00:00.000Z',
  'lifecycle': 'active',
  'version': 1,
  'source': 'user',
  'title': 'Duplicate Task',
  'isCompleted': false,
};

Matcher throwsRestoreError(LifeOsBackupRestoreErrorCode code) {
  return throwsA(
    isA<LifeOsBackupRestoreException>().having(
      (error) => error.code,
      'code',
      code,
    ),
  );
}
