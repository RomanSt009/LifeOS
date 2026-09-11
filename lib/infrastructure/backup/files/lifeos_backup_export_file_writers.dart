import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../../../application/backup/lifeos_backup_export_contracts.dart';
import '../formats/backup_export_format_v1.dart';

enum LifeOsArtifactWriteErrorCode {
  invalidDestination,
  destinationDirectoryNotFound,
  destinationAccessFailed,
  targetAlreadyExists,
  temporaryFileCreationFailed,
  writeFailed,
  validationFailed,
  finalizationFailed,
}

class LifeOsArtifactWriteException implements Exception {
  const LifeOsArtifactWriteException({
    required this.code,
    required this.message,
    this.cause,
  });

  final LifeOsArtifactWriteErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() => 'LifeOsArtifactWriteException($code): $message';
}

class LifeOsBackupFileWriter {
  const LifeOsBackupFileWriter();

  Future<File> write({
    required LifeOsBackupDraft draft,
    required int sourceDatabaseSchemaVersion,
    required String destinationPath,
  }) async {
    final dataBytes = utf8.encode(draft.dataJson);
    final manifestJson = LifeOsDataFormatV1.encodeBackupManifest(
      BackupManifestV1(
        createdAt: draft.createdAt,
        applicationVersion: draft.applicationVersion,
        sourceDatabaseSchemaVersion: sourceDatabaseSchemaVersion,
        requiredSections: const [lifeOsBackupDataFileName],
        dataSha256: sha256.convert(dataBytes).toString(),
      ),
    );
    final manifestBytes = utf8.encode(manifestJson);
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
    final archiveBytes = ZipEncoder().encode(
      archive,
      modified: draft.createdAt,
    );
    if (archiveBytes == null) {
      throw const LifeOsArtifactWriteException(
        code: LifeOsArtifactWriteErrorCode.writeFailed,
        message: 'The Backup ZIP encoder did not produce an artifact.',
      );
    }

    return _writeAtomically(
      destinationPath: destinationPath,
      bytes: archiveBytes,
      validate: (temporaryFile) => _validateBackupArtifact(
        temporaryFile,
        expectedDraft: draft,
        expectedSourceDatabaseSchemaVersion: sourceDatabaseSchemaVersion,
      ),
    );
  }
}

class LifeOsExportFileWriter {
  const LifeOsExportFileWriter();

  Future<File> write({
    required String exportJson,
    required String destinationPath,
  }) {
    final exportBytes = utf8.encode(exportJson);
    return _writeAtomically(
      destinationPath: destinationPath,
      bytes: exportBytes,
      validate: (temporaryFile) =>
          _validateExportArtifact(temporaryFile, expectedBytes: exportBytes),
    );
  }
}

typedef _ArtifactValidator = Future<void> Function(File temporaryFile);

Future<File> _writeAtomically({
  required String destinationPath,
  required List<int> bytes,
  required _ArtifactValidator validate,
}) async {
  final normalizedDestination = path.normalize(destinationPath);
  if (!path.isAbsolute(normalizedDestination)) {
    throw const LifeOsArtifactWriteException(
      code: LifeOsArtifactWriteErrorCode.invalidDestination,
      message: 'The artifact destination path must be absolute.',
    );
  }

  final destinationDirectory = Directory(path.dirname(normalizedDestination));
  bool destinationDirectoryExists;
  try {
    destinationDirectoryExists = await destinationDirectory.exists();
  } on FileSystemException catch (error) {
    throw LifeOsArtifactWriteException(
      code: LifeOsArtifactWriteErrorCode.destinationAccessFailed,
      message: 'The artifact destination directory cannot be accessed.',
      cause: error,
    );
  }
  if (!destinationDirectoryExists) {
    throw const LifeOsArtifactWriteException(
      code: LifeOsArtifactWriteErrorCode.destinationDirectoryNotFound,
      message: 'The artifact destination directory does not exist.',
    );
  }

  await _ensureTargetDoesNotExist(normalizedDestination);
  final temporaryFile = await _createTemporarySibling(normalizedDestination);

  try {
    await _writeAndClose(temporaryFile, bytes);
    try {
      await validate(temporaryFile);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        LifeOsArtifactWriteException(
          code: LifeOsArtifactWriteErrorCode.validationFailed,
          message: 'The temporary artifact failed validation.',
          cause: error,
        ),
        stackTrace,
      );
    }

    await _ensureTargetDoesNotExist(normalizedDestination);
    try {
      return await temporaryFile.rename(normalizedDestination);
    } on FileSystemException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        LifeOsArtifactWriteException(
          code: LifeOsArtifactWriteErrorCode.finalizationFailed,
          message: 'The temporary artifact could not be finalized.',
          cause: error,
        ),
        stackTrace,
      );
    }
  } on Object {
    await _deleteBestEffort(temporaryFile);
    rethrow;
  }
}

Future<void> _ensureTargetDoesNotExist(String destinationPath) async {
  try {
    final targetType = await FileSystemEntity.type(
      destinationPath,
      followLinks: false,
    );
    if (targetType != FileSystemEntityType.notFound) {
      throw const LifeOsArtifactWriteException(
        code: LifeOsArtifactWriteErrorCode.targetAlreadyExists,
        message: 'The artifact destination already exists.',
      );
    }
  } on LifeOsArtifactWriteException {
    rethrow;
  } on FileSystemException catch (error) {
    throw LifeOsArtifactWriteException(
      code: LifeOsArtifactWriteErrorCode.destinationAccessFailed,
      message: 'The artifact destination cannot be inspected.',
      cause: error,
    );
  }
}

Future<File> _createTemporarySibling(String destinationPath) async {
  final directory = path.dirname(destinationPath);
  final destinationName = path.basename(destinationPath);
  final random = Random.secure();

  for (var attempt = 0; attempt < 10; attempt += 1) {
    final suffix = random.nextInt(0x7fffffff).toRadixString(16);
    final candidate = File(
      path.join(directory, '.$destinationName.lifeos-$pid-$suffix.tmp'),
    );
    try {
      return await candidate.create(exclusive: true);
    } on FileSystemException catch (error) {
      if (await candidate.exists()) {
        continue;
      }
      throw LifeOsArtifactWriteException(
        code: LifeOsArtifactWriteErrorCode.temporaryFileCreationFailed,
        message: 'A temporary sibling artifact could not be created.',
        cause: error,
      );
    }
  }

  throw const LifeOsArtifactWriteException(
    code: LifeOsArtifactWriteErrorCode.temporaryFileCreationFailed,
    message: 'A unique temporary sibling artifact could not be created.',
  );
}

Future<void> _writeAndClose(File file, List<int> bytes) async {
  RandomAccessFile? handle;
  try {
    handle = await file.open(mode: FileMode.writeOnly);
    await handle.writeFrom(bytes);
    await handle.flush();
    await handle.close();
    handle = null;
  } on Object catch (error, stackTrace) {
    if (handle != null) {
      try {
        await handle.close();
      } on Object {
        // Preserve the original write/flush/close failure.
      }
    }
    Error.throwWithStackTrace(
      LifeOsArtifactWriteException(
        code: LifeOsArtifactWriteErrorCode.writeFailed,
        message: 'The temporary artifact could not be written and closed.',
        cause: error,
      ),
      stackTrace,
    );
  }
}

Future<void> _validateBackupArtifact(
  File file, {
  required LifeOsBackupDraft expectedDraft,
  required int expectedSourceDatabaseSchemaVersion,
}) async {
  final encodedArchive = await file.readAsBytes();
  final decodedArchive = ZipDecoder().decodeBytes(encodedArchive, verify: true);
  if (decodedArchive.length != 2) {
    throw const FormatException(
      'Backup ZIP v1 must contain exactly two entries.',
    );
  }

  final entries = <String, ArchiveFile>{};
  for (final entry in decodedArchive) {
    if (!entry.isFile || entries.containsKey(entry.name)) {
      throw const FormatException(
        'Backup ZIP v1 contains an invalid or duplicate entry.',
      );
    }
    entries[entry.name] = entry;
  }
  if (entries.keys.toSet().difference(const {
        lifeOsBackupManifestFileName,
        lifeOsBackupDataFileName,
      }).isNotEmpty ||
      !entries.containsKey(lifeOsBackupManifestFileName) ||
      !entries.containsKey(lifeOsBackupDataFileName)) {
    throw const FormatException(
      'Backup ZIP v1 entries do not match the required contract.',
    );
  }

  final manifestBytes = _archiveEntryBytes(
    entries[lifeOsBackupManifestFileName]!,
  );
  final dataBytes = _archiveEntryBytes(entries[lifeOsBackupDataFileName]!);
  final manifest = LifeOsDataFormatV1.decodeBackupManifest(
    utf8.decode(manifestBytes),
  );
  LifeOsDataFormatV1.decodeBackupData(utf8.decode(dataBytes));

  if (manifest.createdAt != expectedDraft.createdAt ||
      manifest.applicationVersion != expectedDraft.applicationVersion ||
      manifest.sourceDatabaseSchemaVersion !=
          expectedSourceDatabaseSchemaVersion ||
      manifest.dataSha256 != sha256.convert(dataBytes).toString() ||
      !_bytesEqual(dataBytes, utf8.encode(expectedDraft.dataJson))) {
    throw const FormatException(
      'Backup ZIP v1 content does not match the source draft.',
    );
  }
}

Future<void> _validateExportArtifact(
  File file, {
  required List<int> expectedBytes,
}) async {
  final actualBytes = await file.readAsBytes();
  LifeOsDataFormatV1.decodeExport(utf8.decode(actualBytes));
  if (!_bytesEqual(actualBytes, expectedBytes)) {
    throw const FormatException(
      'The Export artifact does not match the source document.',
    );
  }
}

List<int> _archiveEntryBytes(ArchiveFile entry) {
  final content = entry.content;
  if (content is! List<int>) {
    throw const FormatException('A Backup ZIP entry is not byte content.');
  }
  return content;
}

bool _bytesEqual(List<int> first, List<int> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

Future<void> _deleteBestEffort(File file) async {
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } on Object {
    // Cleanup must not hide the original operation failure.
  }
}
