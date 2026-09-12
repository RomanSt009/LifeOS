import '../../../../application/backup/lifeos_backup_export_contracts.dart';
import '../../../../application/backup/lifeos_backup_restore_contracts.dart';
import '../../../../domain/entities/lifeos_entity.dart';
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
        await _database.delete(_database.relationshipRecords).go();
        await _database.delete(_database.taskRecords).go();
        await _database.delete(_database.noteRecords).go();
        await _database.delete(_database.entities).go();

        for (final entity in <LifeOsEntity>[
          ...snapshot.tasks,
          ...snapshot.notes,
          ...snapshot.relationships,
        ]) {
          await _database
              .into(_database.entities)
              .insert(
                EntitiesCompanion.insert(
                  id: entity.id.value,
                  entityType: entity.entityType.name,
                  createdAt: entity.createdAt,
                  updatedAt: entity.updatedAt,
                  lifecycle: entity.lifecycle.name,
                  version: entity.version,
                  source: entity.source.name,
                ),
              );
        }
        for (final task in snapshot.tasks) {
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
        for (final note in snapshot.notes) {
          await _database
              .into(_database.noteRecords)
              .insert(
                NoteRecordsCompanion.insert(
                  entityId: note.id.value,
                  title: note.title,
                  content: note.content,
                ),
              );
        }
        for (final relationship in snapshot.relationships) {
          await _database
              .into(_database.relationshipRecords)
              .insert(
                RelationshipRecordsCompanion.insert(
                  entityId: relationship.id.value,
                  firstEntityId: relationship.firstEntityId.value,
                  secondEntityId: relationship.secondEntityId.value,
                  kind: relationship.kind.name,
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
