import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../domain/entities/lifeos_task.dart';
import '../../domain/entities/lifeos_workspace_membership.dart';
import '../../domain/repositories/lifeos_workspace_repository.dart';
import '../workspaces/lifeos_workspace_member_creation_store.dart';
import 'create_lifeos_task.dart' show EntityIdGenerator, UtcClock;

final class LifeOsInactiveWorkspaceException implements Exception {
  const LifeOsInactiveWorkspaceException(this.workspaceId);
  final LifeOsEntityId workspaceId;
}

final class CreateLifeOsTaskInWorkspace {
  const CreateLifeOsTaskInWorkspace({
    required this.workspaceRepository,
    required this.store,
    required this.entityIdGenerator,
    required this.utcClock,
  });

  final LifeOsWorkspaceRepository workspaceRepository;
  final LifeOsWorkspaceMemberCreationStore store;
  final EntityIdGenerator entityIdGenerator;
  final UtcClock utcClock;

  Future<LifeOsTaskInWorkspaceCreation> call({
    required LifeOsEntityId workspaceId,
    required String title,
  }) async {
    await _requireActiveWorkspace(workspaceRepository, workspaceId);
    final timestamp = utcClock();
    final task = LifeOsTask.createUserTask(
      id: LifeOsEntityId(
        value: entityIdGenerator(),
        entityType: LifeOsEntityType.task,
      ),
      title: title,
      timestamp: timestamp,
    );
    final membership = _membership(
      entityIdGenerator(),
      workspaceId,
      task.id,
      timestamp,
    );
    await store.createTaskInWorkspace(task, membership);
    return LifeOsTaskInWorkspaceCreation(task: task, membership: membership);
  }
}

final class CreateLifeOsNoteInWorkspace {
  const CreateLifeOsNoteInWorkspace({
    required this.workspaceRepository,
    required this.store,
    required this.entityIdGenerator,
    required this.utcClock,
  });

  final LifeOsWorkspaceRepository workspaceRepository;
  final LifeOsWorkspaceMemberCreationStore store;
  final EntityIdGenerator entityIdGenerator;
  final UtcClock utcClock;

  Future<LifeOsNoteInWorkspaceCreation> call({
    required LifeOsEntityId workspaceId,
    required String title,
    required String content,
  }) async {
    await _requireActiveWorkspace(workspaceRepository, workspaceId);
    final timestamp = utcClock();
    final note = LifeOsNote.createUserNote(
      id: LifeOsEntityId(
        value: entityIdGenerator(),
        entityType: LifeOsEntityType.note,
      ),
      title: title,
      content: content,
      timestamp: timestamp,
    );
    final membership = _membership(
      entityIdGenerator(),
      workspaceId,
      note.id,
      timestamp,
    );
    await store.createNoteInWorkspace(note, membership);
    return LifeOsNoteInWorkspaceCreation(note: note, membership: membership);
  }
}

Future<void> _requireActiveWorkspace(
  LifeOsWorkspaceRepository repository,
  LifeOsEntityId workspaceId,
) async {
  final workspace = await repository.getById(workspaceId);
  if (workspace == null ||
      workspace.lifecycle != LifeOsEntityLifecycle.active) {
    throw LifeOsInactiveWorkspaceException(workspaceId);
  }
}

LifeOsWorkspaceMembership _membership(
  String id,
  LifeOsEntityId workspaceId,
  LifeOsEntityId memberId,
  DateTime timestamp,
) => LifeOsWorkspaceMembership.createUserMembership(
  id: LifeOsEntityId(
    value: id,
    entityType: LifeOsEntityType.workspaceMembership,
  ),
  workspaceId: workspaceId,
  memberEntityId: memberId,
  timestamp: timestamp,
);
