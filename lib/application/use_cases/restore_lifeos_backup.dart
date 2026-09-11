import '../backup/lifeos_backup_restore_contracts.dart';

class RestoreLifeOsBackup {
  const RestoreLifeOsBackup({required this.reader, required this.restoreStore});

  final LifeOsBackupReader reader;
  final LifeOsBackupRestoreStore restoreStore;

  Future<void> call({
    required String sourcePath,
    required bool destructiveReplaceConfirmed,
  }) async {
    final snapshot = await reader.read(sourcePath);
    final hasRestorableData = await restoreStore.hasRestorableData();

    if (hasRestorableData && !destructiveReplaceConfirmed) {
      throw const LifeOsBackupRestoreException(
        code: LifeOsBackupRestoreErrorCode.confirmationRequired,
        message: 'Replacing existing LifeOS data requires confirmation.',
      );
    }

    await restoreStore.replaceAll(snapshot);
  }
}
