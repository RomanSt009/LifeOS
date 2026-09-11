import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/backup/lifeos_backup_export_contracts.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/infrastructure/backup/files/lifeos_backup_export_file_writers.dart';
import 'package:lifeos/infrastructure/backup/formats/backup_export_format_v1.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'lifeos-backup-writer-test-',
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('writes and validates an exact two-entry Backup ZIP v1', () async {
    final draft = createBackupDraft();
    final destination = path.join(temporaryDirectory.path, 'lifeos-backup.zip');

    final result = await const LifeOsBackupFileWriter().write(
      draft: draft,
      sourceDatabaseSchemaVersion: 1,
      destinationPath: destination,
    );

    expect(result.path, destination);
    expect(await result.exists(), isTrue);
    final archive = ZipDecoder().decodeBytes(
      await result.readAsBytes(),
      verify: true,
    );
    expect(archive.map((entry) => entry.name).toSet(), {
      lifeOsBackupManifestFileName,
      lifeOsBackupDataFileName,
    });
    expect(archive, hasLength(2));

    final manifestEntry = archive.findFile(lifeOsBackupManifestFileName)!;
    final dataEntry = archive.findFile(lifeOsBackupDataFileName)!;
    final dataBytes = List<int>.from(dataEntry.content as List<int>);
    final dataJson = utf8.decode(dataBytes);
    final manifest = LifeOsDataFormatV1.decodeBackupManifest(
      utf8.decode(manifestEntry.content as List<int>),
    );

    expect(dataJson, draft.dataJson);
    expect(manifest.createdAt, draft.createdAt);
    expect(manifest.applicationVersion, draft.applicationVersion);
    expect(manifest.sourceDatabaseSchemaVersion, 1);
    expect(manifest.requiredSections, [lifeOsBackupDataFileName]);
    expect(manifest.dataSha256, sha256.convert(dataBytes).toString());
    expect(dataJson, isNot(contains('outbox')));
    expect(dataJson, isNot(contains('deviceId')));
    expect(await siblingTemporaryFiles(destination), isEmpty);
  });

  test('fails if the Backup target exists and preserves it', () async {
    final destination = path.join(temporaryDirectory.path, 'existing.zip');
    final existing = File(destination);
    await existing.writeAsString('keep-existing-backup', flush: true);

    await expectLater(
      const LifeOsBackupFileWriter().write(
        draft: createBackupDraft(),
        sourceDatabaseSchemaVersion: 1,
        destinationPath: destination,
      ),
      throwsArtifactError(LifeOsArtifactWriteErrorCode.targetAlreadyExists),
    );

    expect(await existing.readAsString(), 'keep-existing-backup');
    expect(await siblingTemporaryFiles(destination), isEmpty);
  });

  test('removes a temporary Backup after validation failure', () async {
    final destination = path.join(temporaryDirectory.path, 'invalid.zip');
    final invalidDraft = LifeOsBackupDraft(
      createdAt: DateTime.utc(2026, 9, 11, 14),
      applicationVersion: '1.0.0+1',
      dataJson: '{malformed',
    );

    await expectLater(
      const LifeOsBackupFileWriter().write(
        draft: invalidDraft,
        sourceDatabaseSchemaVersion: 1,
        destinationPath: destination,
      ),
      throwsArtifactError(LifeOsArtifactWriteErrorCode.validationFailed),
    );

    expect(await File(destination).exists(), isFalse);
    expect(await temporaryDirectory.list().toList(), isEmpty);
  });

  test('writes a parseable UTF-8 Export v1 without changing bytes', () async {
    final exportJson = createExportJson(title: 'Задача для экспорта');
    final destination = path.join(
      temporaryDirectory.path,
      'lifeos-export.json',
    );

    final result = await const LifeOsExportFileWriter().write(
      exportJson: exportJson,
      destinationPath: destination,
    );

    expect(await result.readAsBytes(), utf8.encode(exportJson));
    final decoded = LifeOsDataFormatV1.decodeExport(
      await result.readAsString(encoding: utf8),
    );
    expect(decoded.tasks.single.title, 'Задача для экспорта');
    expect(exportJson, isNot(contains('outbox')));
    expect(exportJson, isNot(contains('deviceId')));
    expect(await siblingTemporaryFiles(destination), isEmpty);
  });

  test('fails if the Export target exists and preserves it', () async {
    final destination = path.join(temporaryDirectory.path, 'existing.json');
    final existing = File(destination);
    await existing.writeAsString('keep-existing-export', flush: true);

    await expectLater(
      const LifeOsExportFileWriter().write(
        exportJson: createExportJson(),
        destinationPath: destination,
      ),
      throwsArtifactError(LifeOsArtifactWriteErrorCode.targetAlreadyExists),
    );

    expect(await existing.readAsString(), 'keep-existing-export');
    expect(await siblingTemporaryFiles(destination), isEmpty);
  });

  test('removes a temporary Export after validation failure', () async {
    final destination = path.join(temporaryDirectory.path, 'invalid.json');

    await expectLater(
      const LifeOsExportFileWriter().write(
        exportJson: '{malformed',
        destinationPath: destination,
      ),
      throwsArtifactError(LifeOsArtifactWriteErrorCode.validationFailed),
    );

    expect(await File(destination).exists(), isFalse);
    expect(await temporaryDirectory.list().toList(), isEmpty);
  });

  test('rejects relative paths and missing destination directories', () async {
    await expectLater(
      const LifeOsExportFileWriter().write(
        exportJson: createExportJson(),
        destinationPath: 'relative-export.json',
      ),
      throwsArtifactError(LifeOsArtifactWriteErrorCode.invalidDestination),
    );

    await expectLater(
      const LifeOsExportFileWriter().write(
        exportJson: createExportJson(),
        destinationPath: path.join(
          temporaryDirectory.path,
          'missing',
          'export.json',
        ),
      ),
      throwsArtifactError(
        LifeOsArtifactWriteErrorCode.destinationDirectoryNotFound,
      ),
    );
    expect(await temporaryDirectory.list().toList(), isEmpty);
  });
}

LifeOsBackupDraft createBackupDraft() {
  final dataJson = LifeOsDataFormatV1.encodeBackupData(
    BackupSnapshotV1(tasks: [createTaskRecord()]),
  );
  return LifeOsBackupDraft(
    createdAt: DateTime.utc(2026, 9, 11, 14),
    applicationVersion: '1.0.0+1',
    dataJson: dataJson,
  );
}

String createExportJson({String title = 'Exported Task'}) {
  return LifeOsDataFormatV1.encodeExport(
    ExportDocumentV1(
      createdAt: DateTime.utc(2026, 9, 11, 14),
      applicationVersion: '1.0.0+1',
      tasks: [createTaskRecord(title: title)],
    ),
  );
}

BackupTaskRecordV1 createTaskRecord({String title = 'Backup Task'}) {
  return BackupTaskRecordV1(
    id: '00000000-0000-4000-8000-000000000001',
    entityType: LifeOsEntityType.task,
    createdAt: DateTime.utc(2026, 9, 10, 10),
    updatedAt: DateTime.utc(2026, 9, 11, 11),
    lifecycle: LifeOsEntityLifecycle.active,
    version: 2,
    source: LifeOsEntitySource.user,
    title: title,
    isCompleted: false,
  );
}

Future<List<FileSystemEntity>> siblingTemporaryFiles(
  String destinationPath,
) async {
  final destinationName = path.basename(destinationPath);
  return Directory(path.dirname(destinationPath))
      .list()
      .where(
        (entry) =>
            path.basename(entry.path).startsWith('.$destinationName.lifeos-'),
      )
      .toList();
}

Matcher throwsArtifactError(LifeOsArtifactWriteErrorCode code) {
  return throwsA(
    isA<LifeOsArtifactWriteException>().having(
      (error) => error.code,
      'code',
      code,
    ),
  );
}
