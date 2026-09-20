import 'package:drift/drift.dart';

import '../../../../application/workspaces/lifeos_workspace_member_creation_store.dart';
import '../../../../domain/entities/lifeos_entity.dart';
import '../../../../domain/entities/lifeos_note.dart';
import '../../../../domain/entities/lifeos_task.dart';
import '../../../../domain/entities/lifeos_workspace_membership.dart';
import '../lifeos_database.dart';
import '../mappers/lifeos_note_mapper.dart';
import '../mappers/lifeos_task_mapper.dart';
import '../mappers/lifeos_workspace_membership_mapper.dart';
import '../repositories/drift_lifeos_task_repository.dart'
    show ChangeIdGenerator;

final class LifeOsWorkspaceMemberCreationPersistenceException
    implements Exception {
  const LifeOsWorkspaceMemberCreationPersistenceException(this.message);
  final String message;

  @override
  String toString() =>
      'LifeOsWorkspaceMemberCreationPersistenceException: $message';
}

final class DriftLifeOsWorkspaceMemberCreationStore
    implements LifeOsWorkspaceMemberCreationStore {
  const DriftLifeOsWorkspaceMemberCreationStore(
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
  Future<void> createTaskInWorkspace(
    LifeOsTask task,
    LifeOsWorkspaceMembership membership,
  ) => _create(
    member: task,
    membership: membership,
    writeTypedMember: () => _database
        .into(_database.taskRecords)
        .insert(
          TaskRecordsCompanion.insert(
            entityId: task.id.value,
            title: task.title,
            isCompleted: task.isCompleted,
          ),
        ),
    memberSnapshot: LifeOsTaskMapper.toJsonSnapshot(task),
  );

  @override
  Future<void> createNoteInWorkspace(
    LifeOsNote note,
    LifeOsWorkspaceMembership membership,
  ) => _create(
    member: note,
    membership: membership,
    writeTypedMember: () => _database
        .into(_database.noteRecords)
        .insert(
          NoteRecordsCompanion.insert(
            entityId: note.id.value,
            title: note.title,
            content: note.content,
          ),
        ),
    memberSnapshot: LifeOsNoteMapper.toJsonSnapshot(note),
  );

  Future<void> _create({
    required LifeOsEntity member,
    required LifeOsWorkspaceMembership membership,
    required Future<int> Function() writeTypedMember,
    required String memberSnapshot,
  }) async {
    _validateCreationInput(member, membership);
    try {
      await _database.transaction(() async {
        await _requirePersistedActiveWorkspace(membership.workspaceId);
        if (await _entity(member.id.value) != null ||
            await _entity(membership.id.value) != null) {
          throw const LifeOsWorkspaceMemberCreationPersistenceException(
            'A quick-create Entity ID is already in use.',
          );
        }
        final pair =
            await (_database.select(_database.workspaceMembershipRecords)
                  ..where(
                    (row) =>
                        row.workspaceId.equals(membership.workspaceId.value) &
                        row.memberEntityId.equals(member.id.value),
                  ))
                .getSingleOrNull();
        if (pair != null) {
          throw const LifeOsWorkspaceMemberCreationPersistenceException(
            'A Workspace membership pair already exists.',
          );
        }

        await _writeEntity(member);
        await writeTypedMember();
        await _writeOutbox(member, memberSnapshot);
        await _writeEntity(membership);
        await _database
            .into(_database.workspaceMembershipRecords)
            .insert(
              WorkspaceMembershipRecordsCompanion.insert(
                entityId: membership.id.value,
                workspaceId: membership.workspaceId.value,
                memberEntityId: membership.memberEntityId.value,
              ),
            );
        await _writeOutbox(
          membership,
          LifeOsWorkspaceMembershipMapper.toJsonSnapshot(membership),
        );
      });
    } on LifeOsWorkspaceMemberCreationPersistenceException {
      rethrow;
    } on Object {
      throw const LifeOsWorkspaceMemberCreationPersistenceException(
        'Workspace quick create could not be persisted atomically.',
      );
    }
  }

  Future<void> _writeEntity(LifeOsEntity entity) => _database
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

  Future<void> _writeOutbox(LifeOsEntity entity, String snapshot) => _database
      .into(_database.outboxEntries)
      .insert(
        OutboxEntriesCompanion.insert(
          changeId: _changeIdGenerator(),
          entityId: entity.id.value,
          deviceId: _deviceId,
          operation: 'CREATE',
          baseVersion: const Value(null),
          newVersion: entity.version,
          payload: snapshot,
          schemaVersion: _changeSchemaVersion,
          status: _pendingStatus,
          attemptCount: 0,
          createdAt: entity.updatedAt,
          lastAttemptAt: const Value.absent(),
        ),
      );

  Future<void> _requirePersistedActiveWorkspace(LifeOsEntityId id) async {
    final entity = await _entity(id.value);
    final typed = await (_database.select(
      _database.workspaceRecords,
    )..where((row) => row.entityId.equals(id.value))).getSingleOrNull();
    if (entity == null ||
        typed == null ||
        entity.entityType != LifeOsEntityType.workspace.name ||
        entity.lifecycle != LifeOsEntityLifecycle.active.name) {
      throw const LifeOsWorkspaceMemberCreationPersistenceException(
        'Quick create requires a complete active Workspace.',
      );
    }
  }

  Future<EntityRecord?> _entity(String id) => (_database.select(
    _database.entities,
  )..where((row) => row.id.equals(id))).getSingleOrNull();
}

void _validateCreationInput(
  LifeOsEntity member,
  LifeOsWorkspaceMembership membership,
) {
  final supportedMember =
      member.entityType == LifeOsEntityType.task ||
      member.entityType == LifeOsEntityType.note;
  final validCreation =
      supportedMember &&
      member.id == membership.memberEntityId &&
      member.lifecycle == LifeOsEntityLifecycle.active &&
      membership.lifecycle == LifeOsEntityLifecycle.active &&
      member.version == 1 &&
      membership.version == 1 &&
      member.source == LifeOsEntitySource.user &&
      membership.source == LifeOsEntitySource.user &&
      member.createdAt == member.updatedAt &&
      membership.createdAt == membership.updatedAt &&
      member.createdAt == membership.createdAt;
  if (!validCreation) {
    throw const LifeOsWorkspaceMemberCreationPersistenceException(
      'Quick create inputs violate the local creation contract.',
    );
  }
}
