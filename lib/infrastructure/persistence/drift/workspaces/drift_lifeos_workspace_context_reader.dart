import 'package:drift/drift.dart';

import '../../../../application/workspaces/lifeos_workspace_context_reader.dart';
import '../../../../domain/entities/lifeos_entity.dart';
import '../lifeos_database.dart';
import '../mappers/lifeos_note_mapper.dart';
import '../mappers/lifeos_task_mapper.dart';

final class LifeOsWorkspaceContextPersistenceException implements Exception {
  const LifeOsWorkspaceContextPersistenceException(this.message);
  final String message;

  @override
  String toString() => 'LifeOsWorkspaceContextPersistenceException: $message';
}

final class DriftLifeOsWorkspaceContextReader
    implements LifeOsWorkspaceContextReader {
  const DriftLifeOsWorkspaceContextReader(this._database);

  final LifeOsDatabase _database;

  @override
  Future<List<LifeOsWorkspaceMember>> getDirectMembers(
    LifeOsEntityId workspaceId,
  ) async {
    await _requireActiveWorkspace(workspaceId);
    final membershipEntities = _database.alias(
      _database.entities,
      'direct_membership_entities',
    );
    final workspaceEntities = _database.alias(
      _database.entities,
      'direct_workspace_entities',
    );
    final memberEntities = _database.alias(
      _database.entities,
      'direct_member_entities',
    );
    final query =
        _database.select(_database.workspaceMembershipRecords).join([
          innerJoin(
            membershipEntities,
            membershipEntities.id.equalsExp(
              _database.workspaceMembershipRecords.entityId,
            ),
          ),
          innerJoin(
            workspaceEntities,
            workspaceEntities.id.equalsExp(
              _database.workspaceMembershipRecords.workspaceId,
            ),
          ),
          innerJoin(
            memberEntities,
            memberEntities.id.equalsExp(
              _database.workspaceMembershipRecords.memberEntityId,
            ),
          ),
        ])..where(
          _database.workspaceMembershipRecords.workspaceId.equals(
                workspaceId.value,
              ) &
              membershipEntities.entityType.equals(
                LifeOsEntityType.workspaceMembership.name,
              ) &
              membershipEntities.lifecycle.equals(
                LifeOsEntityLifecycle.active.name,
              ) &
              workspaceEntities.entityType.equals(
                LifeOsEntityType.workspace.name,
              ) &
              workspaceEntities.lifecycle.equals(
                LifeOsEntityLifecycle.active.name,
              ) &
              memberEntities.lifecycle.equals(
                LifeOsEntityLifecycle.active.name,
              ),
        );

    final values = <LifeOsWorkspaceMember>[];
    for (final row in await query.get()) {
      final membership = row.readTable(_database.workspaceMembershipRecords);
      final memberEntity = row.readTable(memberEntities);
      values.add(
        await _mapMember(
          memberEntity,
          LifeOsEntityId(
            value: membership.entityId,
            entityType: LifeOsEntityType.workspaceMembership,
          ),
        ),
      );
    }
    _sort(values);
    return List.unmodifiable(values);
  }

  @override
  Future<List<LifeOsWorkspaceMember>> getUnassigned() async {
    final assignedIds = await _effectiveAssignedMemberIds();
    final values = <LifeOsWorkspaceMember>[];

    final taskQuery =
        _database.select(_database.entities).join([
          innerJoin(
            _database.taskRecords,
            _database.taskRecords.entityId.equalsExp(_database.entities.id),
          ),
        ])..where(
          _database.entities.entityType.equals(LifeOsEntityType.task.name) &
              _database.entities.lifecycle.equals(
                LifeOsEntityLifecycle.active.name,
              ),
        );
    for (final row in await taskQuery.get()) {
      final entity = row.readTable(_database.entities);
      if (assignedIds.contains(entity.id)) continue;
      values.add(
        LifeOsWorkspaceTaskMember(
          membershipId: null,
          task: LifeOsTaskMapper.toDomain(
            entity,
            row.readTable(_database.taskRecords),
          ),
        ),
      );
    }

    final noteQuery =
        _database.select(_database.entities).join([
          innerJoin(
            _database.noteRecords,
            _database.noteRecords.entityId.equalsExp(_database.entities.id),
          ),
        ])..where(
          _database.entities.entityType.equals(LifeOsEntityType.note.name) &
              _database.entities.lifecycle.equals(
                LifeOsEntityLifecycle.active.name,
              ),
        );
    for (final row in await noteQuery.get()) {
      final entity = row.readTable(_database.entities);
      if (assignedIds.contains(entity.id)) continue;
      values.add(
        LifeOsWorkspaceNoteMember(
          membershipId: null,
          note: LifeOsNoteMapper.toDomain(
            entity,
            row.readTable(_database.noteRecords),
          ),
        ),
      );
    }
    _sort(values);
    return List.unmodifiable(values);
  }

  Future<LifeOsWorkspaceMember> _mapMember(
    EntityRecord entity,
    LifeOsEntityId membershipId,
  ) async {
    switch (LifeOsEntityType.values.byName(entity.entityType)) {
      case LifeOsEntityType.task:
        final task = await (_database.select(
          _database.taskRecords,
        )..where((row) => row.entityId.equals(entity.id))).getSingleOrNull();
        if (task == null) throw _corruptMember();
        return LifeOsWorkspaceTaskMember(
          membershipId: membershipId,
          task: LifeOsTaskMapper.toDomain(entity, task),
        );
      case LifeOsEntityType.note:
        final note = await (_database.select(
          _database.noteRecords,
        )..where((row) => row.entityId.equals(entity.id))).getSingleOrNull();
        if (note == null) throw _corruptMember();
        return LifeOsWorkspaceNoteMember(
          membershipId: membershipId,
          note: LifeOsNoteMapper.toDomain(entity, note),
        );
      case LifeOsEntityType.relationship:
      case LifeOsEntityType.workspace:
      case LifeOsEntityType.workspaceMembership:
        throw _corruptMember();
    }
  }

  Future<Set<String>> _effectiveAssignedMemberIds() async {
    final membershipEntities = _database.alias(
      _database.entities,
      'assigned_membership_entities',
    );
    final workspaceEntities = _database.alias(
      _database.entities,
      'assigned_workspace_entities',
    );
    final query =
        _database.select(_database.workspaceMembershipRecords).join([
          innerJoin(
            membershipEntities,
            membershipEntities.id.equalsExp(
              _database.workspaceMembershipRecords.entityId,
            ),
          ),
          innerJoin(
            workspaceEntities,
            workspaceEntities.id.equalsExp(
              _database.workspaceMembershipRecords.workspaceId,
            ),
          ),
        ])..where(
          membershipEntities.entityType.equals(
                LifeOsEntityType.workspaceMembership.name,
              ) &
              membershipEntities.lifecycle.equals(
                LifeOsEntityLifecycle.active.name,
              ) &
              workspaceEntities.entityType.equals(
                LifeOsEntityType.workspace.name,
              ) &
              workspaceEntities.lifecycle.equals(
                LifeOsEntityLifecycle.active.name,
              ),
        );
    return (await query.get())
        .map(
          (row) => row
              .readTable(_database.workspaceMembershipRecords)
              .memberEntityId,
        )
        .toSet();
  }

  Future<void> _requireActiveWorkspace(LifeOsEntityId id) async {
    if (id.entityType != LifeOsEntityType.workspace) {
      throw const LifeOsWorkspaceContextPersistenceException(
        'Direct members require a Workspace ID.',
      );
    }
    final query =
        _database.select(_database.entities).join([
          innerJoin(
            _database.workspaceRecords,
            _database.workspaceRecords.entityId.equalsExp(
              _database.entities.id,
            ),
          ),
        ])..where(
          _database.entities.id.equals(id.value) &
              _database.entities.entityType.equals(
                LifeOsEntityType.workspace.name,
              ) &
              _database.entities.lifecycle.equals(
                LifeOsEntityLifecycle.active.name,
              ),
        );
    if (await query.getSingleOrNull() == null) {
      throw const LifeOsWorkspaceContextPersistenceException(
        'Direct members require an existing active Workspace.',
      );
    }
  }
}

Never _corruptMember() =>
    throw const LifeOsWorkspaceContextPersistenceException(
      'A direct Workspace member violates the Task/Note persistence contract.',
    );

void _sort(List<LifeOsWorkspaceMember> values) {
  values.sort((first, second) {
    final updated = second.updatedAt.compareTo(first.updatedAt);
    return updated != 0
        ? updated
        : first.entityId.value.compareTo(second.entityId.value);
  });
}
