import 'package:drift/drift.dart';

import '../../../../domain/entities/lifeos_entity.dart';
import '../../../../domain/entities/lifeos_workspace_membership.dart';
import '../../../../domain/repositories/lifeos_workspace_membership_repository.dart';
import '../lifeos_database.dart';
import '../mappers/lifeos_workspace_membership_mapper.dart';
import 'drift_lifeos_task_repository.dart' show ChangeIdGenerator;

final class LifeOsWorkspaceMembershipPersistenceException implements Exception {
  const LifeOsWorkspaceMembershipPersistenceException(this.message);
  final String message;

  @override
  String toString() =>
      'LifeOsWorkspaceMembershipPersistenceException: $message';
}

final class DriftLifeOsWorkspaceMembershipRepository
    implements LifeOsWorkspaceMembershipRepository {
  DriftLifeOsWorkspaceMembershipRepository(
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
  Future<List<LifeOsWorkspaceMembership>> getAll() => _getMemberships();

  @override
  Future<LifeOsWorkspaceMembership?> getById(LifeOsEntityId id) async {
    if (id.entityType != LifeOsEntityType.workspaceMembership) return null;
    final entity = await _entity(id.value);
    if (entity == null ||
        entity.entityType != LifeOsEntityType.workspaceMembership.name) {
      return null;
    }
    final typed = await _typedById(id.value);
    if (typed == null) {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'The Workspace membership Entity has no matching typed record.',
      );
    }
    return _map(entity, typed);
  }

  @override
  Future<LifeOsWorkspaceMembership?> getByPair(
    LifeOsEntityId workspaceId,
    LifeOsEntityId memberEntityId,
  ) async {
    _validatePairTypes(workspaceId, memberEntityId);
    final typed = await _typedByPair(workspaceId.value, memberEntityId.value);
    if (typed == null) return null;
    final entity = await _entity(typed.entityId);
    if (entity == null) {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'The Workspace membership typed record has no Entity metadata.',
      );
    }
    return _map(entity, typed);
  }

  @override
  Future<List<LifeOsWorkspaceMembership>> getActiveForWorkspace(
    LifeOsEntityId workspaceId,
  ) {
    if (workspaceId.entityType != LifeOsEntityType.workspace) {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'A Workspace membership query requires a Workspace ID.',
      );
    }
    return _getMemberships(workspaceId: workspaceId.value, activeOnly: true);
  }

  @override
  Future<List<LifeOsWorkspaceMembership>> getActiveForMember(
    LifeOsEntityId memberEntityId,
  ) {
    if (!_isMemberType(memberEntityId.entityType)) {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'A Workspace membership query requires a Task or Note ID.',
      );
    }
    return _getMemberships(
      memberEntityId: memberEntityId.value,
      activeOnly: true,
    );
  }

  Future<List<LifeOsWorkspaceMembership>> _getMemberships({
    String? workspaceId,
    String? memberEntityId,
    bool activeOnly = false,
  }) async {
    final query = _database.select(_database.workspaceMembershipRecords).join([
      innerJoin(
        _database.entities,
        _database.entities.id.equalsExp(
          _database.workspaceMembershipRecords.entityId,
        ),
      ),
    ]);
    Expression<bool> predicate = _database.entities.entityType.equals(
      LifeOsEntityType.workspaceMembership.name,
    );
    if (workspaceId != null) {
      predicate =
          predicate &
          _database.workspaceMembershipRecords.workspaceId.equals(workspaceId);
    }
    if (memberEntityId != null) {
      predicate =
          predicate &
          _database.workspaceMembershipRecords.memberEntityId.equals(
            memberEntityId,
          );
    }
    if (activeOnly) {
      predicate =
          predicate &
          _database.entities.lifecycle.equals(
            LifeOsEntityLifecycle.active.name,
          );
    }
    query
      ..where(predicate)
      ..orderBy([
        OrderingTerm.desc(_database.entities.updatedAt),
        OrderingTerm.asc(_database.entities.id),
      ]);
    final values = <LifeOsWorkspaceMembership>[];
    for (final row in await query.get()) {
      values.add(
        await _map(
          row.readTable(_database.entities),
          row.readTable(_database.workspaceMembershipRecords),
        ),
      );
    }
    return List.unmodifiable(values);
  }

  @override
  Future<LifeOsWorkspaceMembership> attach({
    required LifeOsEntityId workspaceId,
    required LifeOsEntityId memberEntityId,
    required LifeOsEntityId newMembershipId,
    required DateTime timestamp,
  }) async {
    _validatePairTypes(workspaceId, memberEntityId);
    if (newMembershipId.entityType != LifeOsEntityType.workspaceMembership) {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'Attach requires a Workspace membership candidate ID.',
      );
    }
    try {
      return await _database.transaction(() async {
        await _verifiedWorkspace(workspaceId);
        await _verifiedMember(memberEntityId);
        final existingTyped = await _typedByPair(
          workspaceId.value,
          memberEntityId.value,
        );
        if (existingTyped != null) {
          final existingEntity = await _entity(existingTyped.entityId);
          if (existingEntity == null) {
            throw const LifeOsWorkspaceMembershipPersistenceException(
              'The Workspace membership has no Entity metadata.',
            );
          }
          final existing = await _map(existingEntity, existingTyped);
          if (existing.lifecycle == LifeOsEntityLifecycle.active) {
            return existing.reattach(updatedAt: timestamp);
          }
          final reattached = existing.reattach(updatedAt: timestamp);
          await _persist(reattached, existingEntity);
          return reattached;
        }
        if (await _entity(newMembershipId.value) != null) {
          throw const LifeOsWorkspaceMembershipPersistenceException(
            'The candidate membership ID is already in use.',
          );
        }
        final membership = LifeOsWorkspaceMembership.createUserMembership(
          id: newMembershipId,
          workspaceId: workspaceId,
          memberEntityId: memberEntityId,
          timestamp: timestamp,
        );
        await _persist(membership, null);
        return membership;
      });
    } on LifeOsWorkspaceMembershipPersistenceException {
      rethrow;
    } on LifeOsWorkspaceMembershipMappingException {
      rethrow;
    } on Object {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'The Workspace membership could not be attached atomically.',
      );
    }
  }

  @override
  Future<LifeOsWorkspaceMembership?> remove({
    required LifeOsEntityId membershipId,
    required DateTime timestamp,
  }) async {
    if (membershipId.entityType != LifeOsEntityType.workspaceMembership) {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'Remove requires a Workspace membership ID.',
      );
    }
    try {
      return await _database.transaction(() async {
        final entity = await _entity(membershipId.value);
        if (entity == null) return null;
        if (entity.entityType != LifeOsEntityType.workspaceMembership.name) {
          throw const LifeOsWorkspaceMembershipPersistenceException(
            'The requested Entity is not a Workspace membership.',
          );
        }
        final typed = await _typedById(membershipId.value);
        if (typed == null) {
          throw const LifeOsWorkspaceMembershipPersistenceException(
            'The Workspace membership Entity has no matching typed record.',
          );
        }
        final existing = await _map(entity, typed);
        final removed = existing.remove(updatedAt: timestamp);
        if (identical(existing, removed)) return existing;
        await _persist(removed, entity);
        return removed;
      });
    } on LifeOsWorkspaceMembershipPersistenceException {
      rethrow;
    } on LifeOsWorkspaceMembershipMappingException {
      rethrow;
    } on Object {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'The Workspace membership could not be removed atomically.',
      );
    }
  }

  Future<void> _persist(
    LifeOsWorkspaceMembership membership,
    EntityRecord? existing,
  ) async {
    await _database
        .into(_database.entities)
        .insertOnConflictUpdate(
          EntitiesCompanion.insert(
            id: membership.id.value,
            entityType: membership.entityType.name,
            createdAt: membership.createdAt,
            updatedAt: membership.updatedAt,
            lifecycle: membership.lifecycle.name,
            version: membership.version,
            source: membership.source.name,
          ),
        );
    await _database
        .into(_database.workspaceMembershipRecords)
        .insertOnConflictUpdate(
          WorkspaceMembershipRecordsCompanion.insert(
            entityId: membership.id.value,
            workspaceId: membership.workspaceId.value,
            memberEntityId: membership.memberEntityId.value,
          ),
        );
    await _database
        .into(_database.outboxEntries)
        .insert(
          OutboxEntriesCompanion.insert(
            changeId: _changeIdGenerator(),
            entityId: membership.id.value,
            deviceId: _deviceId,
            operation: existing == null ? 'CREATE' : 'UPDATE',
            baseVersion: Value(existing?.version),
            newVersion: membership.version,
            payload: LifeOsWorkspaceMembershipMapper.toJsonSnapshot(membership),
            schemaVersion: _changeSchemaVersion,
            status: _pendingStatus,
            attemptCount: 0,
            createdAt: membership.updatedAt,
            lastAttemptAt: const Value.absent(),
          ),
        );
  }

  Future<LifeOsWorkspaceMembership> _map(
    EntityRecord entity,
    WorkspaceMembershipRecord typed,
  ) async {
    final workspace = await _entity(typed.workspaceId);
    final member = await _entity(typed.memberEntityId);
    if (workspace == null || member == null) {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'A Workspace membership endpoint Entity is missing.',
      );
    }
    if (!await _hasWorkspaceRecord(workspace.id) ||
        !await _hasMemberRecord(member)) {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'A Workspace membership endpoint has no matching typed record.',
      );
    }
    return LifeOsWorkspaceMembershipMapper.toDomain(
      entity,
      typed,
      workspace,
      member,
    );
  }

  Future<EntityRecord> _verifiedWorkspace(LifeOsEntityId id) async {
    final entity = await _entity(id.value);
    if (entity == null) {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'Workspace Entity does not exist.',
      );
    }
    if (entity.entityType != LifeOsEntityType.workspace.name ||
        entity.lifecycle != LifeOsEntityLifecycle.active.name ||
        !await _hasWorkspaceRecord(entity.id)) {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'Workspace Entity must be a complete active Workspace.',
      );
    }
    return entity;
  }

  Future<EntityRecord> _verifiedMember(LifeOsEntityId id) async {
    final entity = await _entity(id.value);
    if (entity == null) {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'Member Entity does not exist.',
      );
    }
    if (!_isStoredMemberType(entity.entityType) ||
        entity.entityType != id.entityType.name ||
        entity.lifecycle != LifeOsEntityLifecycle.active.name ||
        !await _hasMemberRecord(entity)) {
      throw const LifeOsWorkspaceMembershipPersistenceException(
        'Member Entity must be an active Task or Note of the expected type.',
      );
    }
    return entity;
  }

  Future<bool> _hasWorkspaceRecord(String id) async =>
      await (_database.select(
        _database.workspaceRecords,
      )..where((row) => row.entityId.equals(id))).getSingleOrNull() !=
      null;

  Future<bool> _hasMemberRecord(EntityRecord entity) async {
    if (entity.entityType == LifeOsEntityType.task.name) {
      return await (_database.select(_database.taskRecords)
                ..where((row) => row.entityId.equals(entity.id)))
              .getSingleOrNull() !=
          null;
    }
    if (entity.entityType == LifeOsEntityType.note.name) {
      return await (_database.select(_database.noteRecords)
                ..where((row) => row.entityId.equals(entity.id)))
              .getSingleOrNull() !=
          null;
    }
    return false;
  }

  Future<EntityRecord?> _entity(String id) => (_database.select(
    _database.entities,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<WorkspaceMembershipRecord?> _typedById(String id) => (_database.select(
    _database.workspaceMembershipRecords,
  )..where((row) => row.entityId.equals(id))).getSingleOrNull();

  Future<WorkspaceMembershipRecord?> _typedByPair(
    String workspaceId,
    String memberEntityId,
  ) =>
      (_database.select(_database.workspaceMembershipRecords)..where(
            (row) =>
                row.workspaceId.equals(workspaceId) &
                row.memberEntityId.equals(memberEntityId),
          ))
          .getSingleOrNull();
}

void _validatePairTypes(
  LifeOsEntityId workspaceId,
  LifeOsEntityId memberEntityId,
) {
  if (workspaceId.entityType != LifeOsEntityType.workspace ||
      !_isMemberType(memberEntityId.entityType) ||
      workspaceId.value == memberEntityId.value) {
    throw const LifeOsWorkspaceMembershipPersistenceException(
      'Workspace membership endpoints are invalid.',
    );
  }
}

bool _isMemberType(LifeOsEntityType type) =>
    type == LifeOsEntityType.task || type == LifeOsEntityType.note;

bool _isStoredMemberType(String type) =>
    type == LifeOsEntityType.task.name || type == LifeOsEntityType.note.name;
