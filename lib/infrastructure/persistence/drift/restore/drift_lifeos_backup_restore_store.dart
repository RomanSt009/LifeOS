import '../../../../application/backup/lifeos_backup_export_contracts.dart';
import '../../../../application/backup/lifeos_backup_restore_contracts.dart';
import '../lifeos_database.dart';

class DriftLifeOsBackupRestoreStore implements LifeOsBackupRestoreStore {
  const DriftLifeOsBackupRestoreStore(this._database);

  final LifeOsDatabase _database;

  @override
  Future<bool> hasRestorableData() async {
    try {
      return (await _database.select(_database.entities).get()).isNotEmpty;
    } on Object {
      throw const LifeOsBackupRestoreException(
        code: LifeOsBackupRestoreErrorCode.persistenceFailure,
        message: 'The current LifeOS state could not be inspected.',
      );
    }
  }

  @override
  Future<void> replaceAll(LifeOsDataSnapshot snapshot) async {
    try {
      await _database.transaction(() async {
        await _database.delete(_database.outboxEntries).go();
        await _database.delete(_database.taskRecords).go();
        await _database.delete(_database.entities).go();

        for (final task in snapshot.tasks) {
          await _database
              .into(_database.entities)
              .insert(
                EntitiesCompanion.insert(
                  id: task.id.value,
                  entityType: task.entityType.name,
                  createdAt: task.createdAt,
                  updatedAt: task.updatedAt,
                  lifecycle: task.lifecycle.name,
                  version: task.version,
                  source: task.source.name,
                ),
              );
          await _database
              .into(_database.taskRecords)
              .insert(
                TaskRecordsCompanion.insert(
                  entityId: task.id.value,
                  title: task.title,
                  isCompleted: task.isCompleted,
                ),
              );
        }
      });
    } on LifeOsBackupRestoreException {
      rethrow;
    } on Object {
      throw const LifeOsBackupRestoreException(
        code: LifeOsBackupRestoreErrorCode.persistenceFailure,
        message: 'The Backup could not atomically replace LifeOS data.',
      );
    }
  }
}
