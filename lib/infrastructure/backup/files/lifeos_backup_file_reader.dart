import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../../../application/backup/lifeos_backup_export_contracts.dart';
import '../../../application/backup/lifeos_backup_restore_contracts.dart';
import '../formats/backup_export_format_v1.dart';
import '../formats/backup_export_format_v2.dart';

class LifeOsBackupFileReader implements LifeOsBackupReader {
  const LifeOsBackupFileReader();

  @override
  Future<LifeOsDataSnapshot> read(String sourcePath) async {
    late final List<int> archiveBytes;
    try {
      archiveBytes = await File(sourcePath).readAsBytes();
    } on FileSystemException {
      throw const LifeOsBackupRestoreException(
        code: LifeOsBackupRestoreErrorCode.unreadableFile,
        message: 'The Backup file could not be read.',
      );
    }

    late final Archive archive;
    late final List<String?> encodedEntryNames;
    try {
      final decoder = ZipDecoder();
      archive = decoder.decodeBytes(archiveBytes, verify: true);
      encodedEntryNames = decoder.directory.fileHeaders
          .map((header) => header.file?.filename)
          .toList(growable: false);
    } on Object {
      throw const LifeOsBackupRestoreException(
        code: LifeOsBackupRestoreErrorCode.invalidContainer,
        message: 'The Backup file is not a valid ZIP container.',
      );
    }

    final entries = _requireExactEntries(archive, encodedEntryNames);
    final manifestBytes = _entryBytes(entries[lifeOsBackupManifestFileName]!);
    final dataBytes = _entryBytes(entries[lifeOsBackupDataFileName]!);

    late final dynamic manifest;
    late final int formatVersion;
    try {
      final manifestSource = utf8.decode(manifestBytes);
      final manifestJson = jsonDecode(manifestSource);
      if (manifestJson is! Map<String, dynamic> ||
          manifestJson['formatVersion'] is! int) {
        throw const FormatException('Invalid format version.');
      }
      formatVersion = manifestJson['formatVersion'] as int;
      manifest = switch (formatVersion) {
        1 => LifeOsDataFormatV1.decodeBackupManifest(manifestSource),
        2 => LifeOsDataFormatV2.decodeManifest(manifestSource),
        _ => throw const LifeOsDataFormatException(
          code: LifeOsDataFormatErrorCode.unsupportedVersion,
          message: 'Unsupported Backup format version.',
        ),
      };
    } on LifeOsDataFormatException catch (error) {
      throw _mapFormatError(error);
    } on FormatException {
      throw const LifeOsBackupRestoreException(
        code: LifeOsBackupRestoreErrorCode.invalidData,
        message: 'The Backup manifest is not valid UTF-8.',
      );
    }

    if (manifest.dataSha256 != sha256.convert(dataBytes).toString()) {
      throw const LifeOsBackupRestoreException(
        code: LifeOsBackupRestoreErrorCode.checksumMismatch,
        message: 'The Backup data checksum does not match the manifest.',
      );
    }

    try {
      final source = utf8.decode(dataBytes);
      if (formatVersion == 1) {
        final backup = LifeOsDataFormatV1.decodeBackupData(source);
        return LifeOsDataSnapshot(
          tasks: backup.tasks.map((record) => record.toDomain()),
        );
      }
      final backup = LifeOsDataFormatV2.decodeBackupData(source);
      return LifeOsDataSnapshot(
        tasks: backup.tasks.map((record) => record.toDomain()),
        notes: backup.notes.map((record) => record.toDomain()),
      );
    } on LifeOsDataFormatException catch (error) {
      throw _mapFormatError(error);
    } on FormatException {
      throw const LifeOsBackupRestoreException(
        code: LifeOsBackupRestoreErrorCode.invalidData,
        message: 'The Backup data is not valid UTF-8.',
      );
    }
  }
}

Map<String, ArchiveFile> _requireExactEntries(
  Archive archive,
  List<String?> encodedEntryNames,
) {
  if (encodedEntryNames.length != 2 ||
      encodedEntryNames.any((name) => name == null) ||
      encodedEntryNames.toSet().length != encodedEntryNames.length ||
      archive.length != 2) {
    throw const LifeOsBackupRestoreException(
      code: LifeOsBackupRestoreErrorCode.invalidContainer,
      message: 'Backup ZIP v1 must contain exactly two entries.',
    );
  }

  final entries = <String, ArchiveFile>{};
  for (final entry in archive) {
    if (!entry.isFile || entries.containsKey(entry.name)) {
      throw const LifeOsBackupRestoreException(
        code: LifeOsBackupRestoreErrorCode.invalidContainer,
        message: 'The Backup ZIP contains an invalid or duplicate entry.',
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
    throw const LifeOsBackupRestoreException(
      code: LifeOsBackupRestoreErrorCode.invalidContainer,
      message: 'The Backup ZIP entries do not match the v1 contract.',
    );
  }
  return entries;
}

List<int> _entryBytes(ArchiveFile entry) {
  final content = entry.content;
  if (content is! List<int>) {
    throw const LifeOsBackupRestoreException(
      code: LifeOsBackupRestoreErrorCode.invalidContainer,
      message: 'A Backup ZIP entry does not contain bytes.',
    );
  }
  return List<int>.unmodifiable(content);
}

LifeOsBackupRestoreException _mapFormatError(LifeOsDataFormatException error) {
  return LifeOsBackupRestoreException(
    code: error.code == LifeOsDataFormatErrorCode.unsupportedVersion
        ? LifeOsBackupRestoreErrorCode.unsupportedFormat
        : LifeOsBackupRestoreErrorCode.invalidData,
    message: error.message,
  );
}
