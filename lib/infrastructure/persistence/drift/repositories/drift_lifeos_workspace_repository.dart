import 'package:drift/drift.dart';

import '../../../../domain/entities/lifeos_entity.dart';
import '../../../../domain/entities/lifeos_workspace.dart';
import '../../../../domain/repositories/lifeos_workspace_repository.dart';
import '../lifeos_database.dart';
import '../mappers/lifeos_workspace_mapper.dart';
import 'drift_lifeos_task_repository.dart' show ChangeIdGenerator;

final class LifeOsWorkspacePersistenceException implements Exception {
  const LifeOsWorkspacePersistenceException(this.message);
  final String message;

  @override
  String toString() => 'LifeOsWorkspacePersistenceException: $message';
}

final class DriftLifeOsWorkspaceRepository
    implements LifeOsWorkspaceRepository {
  DriftLifeOsWorkspaceRepository(
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
  Future<List<LifeOsWorkspace>> getAll() => _getWorkspaces();

  @override
  Future<List<LifeOsWorkspace>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) => _getWorkspaces(lifecycle: lifecycle);

  Future<List<LifeOsWorkspace>> _getWorkspaces({
    LifeOsEntityLifecycle? lifecycle,
  }) async {
    final query =
        _database.select(_database.entities).join([
            innerJoin(
              _database.workspaceRecords,
              _database.workspaceRecords.entityId.equalsExp(
                _database.entities.id,
              ),
            ),
          ])
          ..where(
            _database.entities.entityType.equals(
                  LifeOsEntityType.workspace.name,
                ) &
                (lifecycle == null
                    ? const Constant(true)
                    : _database.entities.lifecycle.equals(lifecycle.name)),
          )
          ..orderBy([
            OrderingTerm.desc(_database.entities.updatedAt),
            OrderingTerm.asc(_database.entities.id),
          ]);
    return (await query.get()).map(_map).toList(growable: false);
  }

  @override
  Future<LifeOsWorkspace?> getById(LifeOsEntityId id) async {
    if (id.entityType != LifeOsEntityType.workspace) return null;
    final entity = await _entity(id.value);
    if (entity == null ||
        entity.entityType != LifeOsEntityType.workspace.name) {
      return null;
    }
    final typed = await (_database.select(
      _database.workspaceRecords,
    )..where((row) => row.entityId.equals(id.value))).getSingleOrNull();
    if (typed == null) {
      throw const LifeOsWorkspacePersistenceException(
        'The Workspace Entity has no matching typed record.',
      );
    }
    return LifeOsWorkspaceMapper.toDomain(entity, typed);
  }

  @override
  Future<void> save(LifeOsWorkspace workspace) async {
    try {
      await _database.transaction(() async {
        final existing = await _entity(workspace.id.value);
        LifeOsWorkspace? persisted;
        if (existing != null) {
          if (existing.entityType != LifeOsEntityType.workspace.name) {
            throw const LifeOsWorkspacePersistenceException(
              'An Entity with this ID already has another type.',
            );
          }
          final typed =
              await (_database.select(_database.workspaceRecords)
                    ..where((row) => row.entityId.equals(workspace.id.value)))
                  .getSingleOrNull();
          if (typed == null) {
            throw const LifeOsWorkspacePersistenceException(
              'The Workspace Entity has no matching typed record.',
            );
          }
          persisted = LifeOsWorkspaceMapper.toDomain(existing, typed);
          if (persisted == workspace) return;
          _validateUpdate(persisted, workspace);
        } else {
          _validateCreation(workspace);
        }

        await _database
            .into(_database.entities)
            .insertOnConflictUpdate(
              EntitiesCompanion.insert(
                id: workspace.id.value,
                entityType: workspace.entityType.name,
                createdAt: workspace.createdAt,
                updatedAt: workspace.updatedAt,
                lifecycle: workspace.lifecycle.name,
                version: workspace.version,
                source: workspace.source.name,
              ),
            );
        await _database
            .into(_database.workspaceRecords)
            .insertOnConflictUpdate(
              WorkspaceRecordsCompanion.insert(
                entityId: workspace.id.value,
                title: workspace.title,
                description: Value(workspace.description),
              ),
            );
        await _database
            .into(_database.outboxEntries)
            .insert(
              OutboxEntriesCompanion.insert(
                changeId: _changeIdGenerator(),
                entityId: workspace.id.value,
                deviceId: _deviceId,
                operation: existing == null ? 'CREATE' : 'UPDATE',
                baseVersion: Value(existing?.version),
                newVersion: workspace.version,
                payload: LifeOsWorkspaceMapper.toJsonSnapshot(workspace),
                schemaVersion: _changeSchemaVersion,
                status: _pendingStatus,
                attemptCount: 0,
                createdAt: workspace.updatedAt,
                lastAttemptAt: const Value.absent(),
              ),
            );
      });
    } on LifeOsWorkspacePersistenceException {
      rethrow;
    } on LifeOsWorkspaceMappingException {
      rethrow;
    } on Object {
      throw const LifeOsWorkspacePersistenceException(
        'The Workspace could not be persisted atomically.',
      );
    }
  }

  LifeOsWorkspace _map(TypedResult row) => LifeOsWorkspaceMapper.toDomain(
    row.readTable(_database.entities),
    row.readTable(_database.workspaceRecords),
  );

  Future<EntityRecord?> _entity(String id) => (_database.select(
    _database.entities,
  )..where((row) => row.id.equals(id))).getSingleOrNull();
}

void _validateCreation(LifeOsWorkspace workspace) {
  if (workspace.lifecycle != LifeOsEntityLifecycle.active ||
      workspace.version != 1 ||
      workspace.source != LifeOsEntitySource.user ||
      workspace.createdAt != workspace.updatedAt) {
    throw const LifeOsWorkspacePersistenceException(
      'A new Workspace must satisfy the local creation contract.',
    );
  }
}

void _validateUpdate(LifeOsWorkspace persisted, LifeOsWorkspace replacement) {
  final commonValid =
      replacement.id == persisted.id &&
      replacement.createdAt == persisted.createdAt &&
      replacement.source == persisted.source &&
      replacement.version == persisted.version + 1 &&
      !replacement.updatedAt.isBefore(persisted.updatedAt);
  final isEdit =
      persisted.lifecycle == LifeOsEntityLifecycle.active &&
      replacement.lifecycle == persisted.lifecycle &&
      (replacement.title != persisted.title ||
          replacement.description != persisted.description);
  final fieldsUnchanged =
      replacement.title == persisted.title &&
      replacement.description == persisted.description;
  final isLifecycleChange =
      fieldsUnchanged &&
      switch ((persisted.lifecycle, replacement.lifecycle)) {
        (LifeOsEntityLifecycle.active, LifeOsEntityLifecycle.archived) => true,
        (LifeOsEntityLifecycle.active, LifeOsEntityLifecycle.deleted) => true,
        (LifeOsEntityLifecycle.archived, LifeOsEntityLifecycle.active) => true,
        (LifeOsEntityLifecycle.archived, LifeOsEntityLifecycle.deleted) => true,
        (LifeOsEntityLifecycle.deleted, LifeOsEntityLifecycle.active) => true,
        _ => false,
      };
  if (!commonValid || (!isEdit && !isLifecycleChange)) {
    throw const LifeOsWorkspacePersistenceException(
      'The Workspace replacement is not a supported material mutation.',
    );
  }
}
