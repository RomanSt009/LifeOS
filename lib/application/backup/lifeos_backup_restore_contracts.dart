import 'lifeos_backup_export_contracts.dart';

enum LifeOsBackupRestoreErrorCode {
  unreadableFile,
  invalidContainer,
  unsupportedFormat,
  checksumMismatch,
  invalidData,
  confirmationRequired,
  persistenceFailure,
}

class LifeOsBackupRestoreException implements Exception {
  const LifeOsBackupRestoreException({
    required this.code,
    required this.message,
  });

  final LifeOsBackupRestoreErrorCode code;
  final String message;

  @override
  String toString() => 'LifeOsBackupRestoreException($code): $message';
}

abstract interface class LifeOsBackupReader {
  Future<LifeOsDataSnapshot> read(String sourcePath);
}

abstract interface class LifeOsBackupRestoreStore {
  Future<bool> hasRestorableData();

  Future<void> replaceAll(LifeOsDataSnapshot snapshot);
}
