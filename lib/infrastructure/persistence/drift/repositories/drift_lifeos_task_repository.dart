import 'package:drift/drift.dart';

import '../../../../domain/entities/lifeos_entity.dart';
import '../../../../domain/entities/lifeos_task.dart';
import '../../../../domain/repositories/lifeos_task_repository.dart';
import '../lifeos_database.dart';
import '../mappers/lifeos_task_mapper.dart';

typedef ChangeIdGenerator = String Function();

class DriftLifeOsTaskRepository implements LifeOsTaskRepository {
  DriftLifeOsTaskRepository(
    this._database,
    this._changeIdGenerator,
    this._deviceId,
  );

  static const _changeSchemaVersion = 1;
  static const _pendingStatus = 'PENDING';

  final LifeOsDatabase _database;
  final ChangeIdGenerator _changeIdGenerator;
  final String _deviceId;

  @override
  Future<List<LifeOsTask>> getAll() async {
    final query = _database.select(_database.entities).join([
      innerJoin(
        _database.taskRecords,
        _database.taskRecords.entityId.equalsExp(_database.entities.id),
      ),
    ])..where(_database.entities.entityType.equals(LifeOsEntityType.task.name));

    final rows = await query.get();
    return rows
        .map(
          (row) => LifeOsTaskMapper.toDomain(
            row.readTable(_database.entities),
            row.readTable(_database.taskRecords),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async {
    final query =
        _database.select(_database.entities).join([
          innerJoin(
            _database.taskRecords,
            _database.taskRecords.entityId.equalsExp(_database.entities.id),
          ),
        ])..where(
          _database.entities.id.equals(id.value) &
              _database.entities.entityType.equals(id.entityType.name),
        );

    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }

    return LifeOsTaskMapper.toDomain(
      row.readTable(_database.entities),
      row.readTable(_database.taskRecords),
    );
  }

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) {
    throw UnimplementedError(
      'Task search persistence is implemented in LS-03.',
    );
  }

  @override
  Future<void> save(LifeOsTask task) async {
    await _database.transaction(() async {
      final existing = await (_database.select(
        _database.entities,
      )..where((entity) => entity.id.equals(task.id.value))).getSingleOrNull();

      await _database
          .into(_database.entities)
          .insertOnConflictUpdate(
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
          .insertOnConflictUpdate(
            TaskRecordsCompanion.insert(
              entityId: task.id.value,
              title: task.title,
              isCompleted: task.isCompleted,
            ),
          );

      await _database
          .into(_database.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              changeId: _changeIdGenerator(),
              entityId: task.id.value,
              deviceId: _deviceId,
              operation: existing == null ? 'CREATE' : 'UPDATE',
              baseVersion: Value(existing?.version),
              newVersion: task.version,
              payload: LifeOsTaskMapper.toJsonSnapshot(task),
              schemaVersion: _changeSchemaVersion,
              status: _pendingStatus,
              attemptCount: 0,
              createdAt: task.updatedAt,
              lastAttemptAt: const Value.absent(),
            ),
          );
    });
  }
}
