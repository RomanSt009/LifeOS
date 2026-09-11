import '../application/backup/lifeos_backup_operations.dart';
import '../application/backup/lifeos_backup_restore_contracts.dart';
import '../application/use_cases/create_lifeos_backup.dart';
import '../application/use_cases/export_lifeos_data.dart';
import '../application/use_cases/restore_lifeos_backup.dart';
import '../infrastructure/backup/files/lifeos_backup_export_file_writers.dart';

class ComposedLifeOsBackupOperations implements LifeOsBackupOperations {
  const ComposedLifeOsBackupOperations({
    required this.createBackup,
    required this.exportData,
    required this.restoreBackup,
    required this.sourceDatabaseSchemaVersion,
    this.backupWriter = const LifeOsBackupFileWriter(),
    this.exportWriter = const LifeOsExportFileWriter(),
  });

  final CreateLifeOsBackup createBackup;
  final ExportLifeOsData exportData;
  final RestoreLifeOsBackup restoreBackup;
  final int sourceDatabaseSchemaVersion;
  final LifeOsBackupFileWriter backupWriter;
  final LifeOsExportFileWriter exportWriter;

  @override
  Future<void> createBackupAt(String destinationPath) async {
    try {
      final draft = await createBackup();
      await backupWriter.write(
        draft: draft,
        sourceDatabaseSchemaVersion: sourceDatabaseSchemaVersion,
        destinationPath: destinationPath,
      );
    } on LifeOsArtifactWriteException catch (error) {
      throw _mapWriteError(error);
    } on Object {
      throw const LifeOsBackupOperationException(
        LifeOsBackupOperationErrorCode.fileSystemFailure,
      );
    }
  }

  @override
  Future<void> exportDataAt(String destinationPath) async {
    try {
      await exportWriter.write(
        exportJson: await exportData(),
        destinationPath: destinationPath,
      );
    } on LifeOsArtifactWriteException catch (error) {
      throw _mapWriteError(error);
    } on Object {
      throw const LifeOsBackupOperationException(
        LifeOsBackupOperationErrorCode.fileSystemFailure,
      );
    }
  }

  @override
  Future<void> restoreBackupFrom(
    String sourcePath, {
    required bool destructiveReplaceConfirmed,
  }) async {
    try {
      await restoreBackup(
        sourcePath: sourcePath,
        destructiveReplaceConfirmed: destructiveReplaceConfirmed,
      );
    } on LifeOsBackupRestoreException catch (error) {
      throw LifeOsBackupOperationException(switch (error.code) {
        LifeOsBackupRestoreErrorCode.unreadableFile =>
          LifeOsBackupOperationErrorCode.fileSystemFailure,
        LifeOsBackupRestoreErrorCode.invalidContainer =>
          LifeOsBackupOperationErrorCode.invalidBackup,
        LifeOsBackupRestoreErrorCode.unsupportedFormat =>
          LifeOsBackupOperationErrorCode.unsupportedBackup,
        LifeOsBackupRestoreErrorCode.checksumMismatch =>
          LifeOsBackupOperationErrorCode.checksumMismatch,
        LifeOsBackupRestoreErrorCode.invalidData =>
          LifeOsBackupOperationErrorCode.invalidBackup,
        LifeOsBackupRestoreErrorCode.confirmationRequired =>
          LifeOsBackupOperationErrorCode.confirmationRequired,
        LifeOsBackupRestoreErrorCode.persistenceFailure =>
          LifeOsBackupOperationErrorCode.restorePersistenceFailure,
      });
    }
  }
}

LifeOsBackupOperationException _mapWriteError(
  LifeOsArtifactWriteException error,
) {
  return LifeOsBackupOperationException(
    error.code == LifeOsArtifactWriteErrorCode.targetAlreadyExists
        ? LifeOsBackupOperationErrorCode.destinationAlreadyExists
        : LifeOsBackupOperationErrorCode.fileSystemFailure,
  );
}
