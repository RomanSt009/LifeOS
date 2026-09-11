enum LifeOsBackupOperationErrorCode {
  invalidBackup,
  unsupportedBackup,
  checksumMismatch,
  destinationAlreadyExists,
  fileSystemFailure,
  confirmationRequired,
  restorePersistenceFailure,
}

class LifeOsBackupOperationException implements Exception {
  const LifeOsBackupOperationException(this.code);

  final LifeOsBackupOperationErrorCode code;
}

abstract interface class LifeOsBackupOperations {
  Future<void> createBackupAt(String destinationPath);

  Future<void> exportDataAt(String destinationPath);

  Future<void> restoreBackupFrom(
    String sourcePath, {
    required bool destructiveReplaceConfirmed,
  });
}
