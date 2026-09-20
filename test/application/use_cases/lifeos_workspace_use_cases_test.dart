import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/create_lifeos_entity_in_workspace.dart';
import 'package:lifeos/application/use_cases/create_lifeos_workspace.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_workspace.dart';
import 'package:lifeos/application/use_cases/get_lifeos_workspace_context.dart';
import 'package:lifeos/application/use_cases/get_lifeos_workspaces.dart';
import 'package:lifeos/application/use_cases/lifeos_workspace_lifecycle.dart';
import 'package:lifeos/application/use_cases/lifeos_workspace_membership.dart';
import 'package:lifeos/application/workspaces/lifeos_workspace_context_reader.dart';
import 'package:lifeos/application/workspaces/lifeos_workspace_member_creation_store.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_workspace.dart';
import 'package:lifeos/domain/entities/lifeos_workspace_membership.dart';
import 'package:lifeos/domain/repositories/lifeos_workspace_membership_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_workspace_repository.dart';

void main() {
  final timestamp = DateTime.utc(2026, 9, 20, 10);
  const workspaceId = LifeOsEntityId(
    value: 'workspace-1',
    entityType: LifeOsEntityType.workspace,
  );

  test('creates, gets, edits, deletes, and restores Workspace', () async {
    final repository = _WorkspaceRepository();
    final create = CreateLifeOsWorkspace(
      repository: repository,
      entityIdGenerator: () => workspaceId.value,
      utcClock: () => timestamp,
    );
    final created = await create(title: ' Work ', description: null);
    expect(created.title, 'Work');
    expect(await GetLifeOsWorkspace(repository)(workspaceId), created);
    expect(await GetLifeOsWorkspaces(repository)(), [created]);

    final edited = await EditLifeOsWorkspace(
      repository: repository,
      utcClock: () => timestamp.add(const Duration(hours: 1)),
    )(workspaceId, title: 'Home', description: 'exact ');
    expect(edited?.title, 'Home');
    final deleted = await DeleteLifeOsWorkspace(
      repository: repository,
      utcClock: () => timestamp.add(const Duration(hours: 2)),
    )(workspaceId);
    expect(await GetLifeOsWorkspaces(repository)(), isEmpty);
    expect(await GetDeletedLifeOsWorkspaces(repository)(), [deleted]);
    final restored = await RestoreLifeOsWorkspace(
      repository: repository,
      utcClock: () => timestamp.add(const Duration(hours: 3)),
    )(workspaceId);
    expect(restored?.lifecycle, LifeOsEntityLifecycle.active);
    expect(repository.saveCount, 4);
  });

  test('Workspace edit true no-op skips repository save', () async {
    final repository = _WorkspaceRepository()
      ..value = _workspace(workspaceId, timestamp);
    final result = await EditLifeOsWorkspace(
      repository: repository,
      utcClock: () => timestamp.add(const Duration(hours: 1)),
    )(workspaceId, title: 'Workspace', description: null);
    expect(result, same(repository.value));
    expect(repository.saveCount, 0);
  });

  test('attach delegates pair decisions and detach preserves member state', () async {
    final repository = _MembershipRepository();
    var id = 0;
    final attach = AttachLifeOsWorkspaceMember(
      repository: repository,
      entityIdGenerator: () => 'membership-${++id}',
      utcClock: () => timestamp.add(Duration(hours: id)),
    );
    const taskId = LifeOsEntityId(
      value: 'task-1',
      entityType: LifeOsEntityType.task,
    );
    final first = await attach(
      workspaceId: workspaceId,
      memberEntityId: taskId,
    );
    final duplicate = await attach(
      workspaceId: workspaceId,
      memberEntityId: taskId,
    );
    expect(duplicate, first);
    final detached = await DetachLifeOsWorkspaceMember(
      repository: repository,
      utcClock: () => timestamp.add(const Duration(hours: 3)),
    )(first.id);
    final reattached = await attach(
      workspaceId: workspaceId,
      memberEntityId: taskId,
    );
    expect(detached?.lifecycle, LifeOsEntityLifecycle.deleted);
    expect(reattached.id, first.id);
    expect(reattached.version, 3);
    expect(repository.attachCalls, 3);
  });

  test('context use cases expose the bounded mixed reader', () async {
    final task = LifeOsTask.createUserTask(
      id: const LifeOsEntityId(
        value: 'task-1',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Task',
      timestamp: timestamp,
    );
    final view = LifeOsWorkspaceTaskMember(
      membershipId: const LifeOsEntityId(
        value: 'membership-1',
        entityType: LifeOsEntityType.workspaceMembership,
      ),
      task: task,
    );
    final reader = _ContextReader([view]);
    expect(await GetLifeOsWorkspaceMembers(reader)(workspaceId), [view]);
    expect(await GetUnassignedLifeOsWorkspaceMembers(reader)(), [view]);
  });

  test('quick-create use cases share two typed IDs and one UTC timestamp', () async {
    final repository = _WorkspaceRepository()
      ..value = _workspace(workspaceId, timestamp);
    final store = _CreationStore();
    final ids = ['task-1', 'membership-task', 'note-1', 'membership-note'];
    var index = 0;
    final createTask = CreateLifeOsTaskInWorkspace(
      workspaceRepository: repository,
      store: store,
      entityIdGenerator: () => ids[index++],
      utcClock: () => timestamp,
    );
    final taskResult = await createTask(workspaceId: workspaceId, title: 'Task');
    expect(taskResult.task.id.value, 'task-1');
    expect(taskResult.membership.id.value, 'membership-task');
    expect(taskResult.membership.memberEntityId, taskResult.task.id);
    expect(taskResult.task.createdAt, taskResult.membership.createdAt);

    final noteResult = await CreateLifeOsNoteInWorkspace(
      workspaceRepository: repository,
      store: store,
      entityIdGenerator: () => ids[index++],
      utcClock: () => timestamp,
    )(
      workspaceId: workspaceId,
      title: 'Note',
      content: 'Body',
    );
    expect(noteResult.note.id.value, 'note-1');
    expect(noteResult.membership.id.value, 'membership-note');
    expect(noteResult.membership.memberEntityId, noteResult.note.id);
    expect(store.task, taskResult.task);
    expect(store.note, noteResult.note);
  });

  test('quick create rejects missing or inactive Workspace before store', () async {
    final repository = _WorkspaceRepository();
    final store = _CreationStore();
    final useCase = CreateLifeOsTaskInWorkspace(
      workspaceRepository: repository,
      store: store,
      entityIdGenerator: () => 'unused',
      utcClock: () => timestamp,
    );
    await expectLater(
      useCase(workspaceId: workspaceId, title: 'Task'),
      throwsA(isA<LifeOsInactiveWorkspaceException>()),
    );
    repository.value = _workspace(
      workspaceId,
      timestamp,
    ).delete(updatedAt: timestamp);
    await expectLater(
      useCase(workspaceId: workspaceId, title: 'Task'),
      throwsA(isA<LifeOsInactiveWorkspaceException>()),
    );
    expect(store.task, isNull);
  });
}

LifeOsWorkspace _workspace(LifeOsEntityId id, DateTime timestamp) =>
    LifeOsWorkspace.createUserWorkspace(
      id: id,
      title: 'Workspace',
      description: null,
      timestamp: timestamp,
    );

final class _WorkspaceRepository implements LifeOsWorkspaceRepository {
  LifeOsWorkspace? value;
  var saveCount = 0;

  @override
  Future<List<LifeOsWorkspace>> getAll() async => value == null ? [] : [value!];

  @override
  Future<LifeOsWorkspace?> getById(LifeOsEntityId id) async =>
      value?.id == id ? value : null;

  @override
  Future<List<LifeOsWorkspace>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async => value?.lifecycle == lifecycle ? [value!] : [];

  @override
  Future<void> save(LifeOsWorkspace workspace) async {
    value = workspace;
    saveCount++;
  }
}

final class _MembershipRepository
    implements LifeOsWorkspaceMembershipRepository {
  LifeOsWorkspaceMembership? value;
  var attachCalls = 0;

  @override
  Future<LifeOsWorkspaceMembership> attach({
    required LifeOsEntityId workspaceId,
    required LifeOsEntityId memberEntityId,
    required LifeOsEntityId newMembershipId,
    required DateTime timestamp,
  }) async {
    attachCalls++;
    if (value == null) {
      value = LifeOsWorkspaceMembership.createUserMembership(
        id: newMembershipId,
        workspaceId: workspaceId,
        memberEntityId: memberEntityId,
        timestamp: timestamp,
      );
    } else if (value!.lifecycle == LifeOsEntityLifecycle.deleted) {
      value = value!.reattach(updatedAt: timestamp);
    }
    return value!;
  }

  @override
  Future<LifeOsWorkspaceMembership?> remove({
    required LifeOsEntityId membershipId,
    required DateTime timestamp,
  }) async {
    if (value?.id != membershipId) return null;
    value = value!.remove(updatedAt: timestamp);
    return value;
  }

  @override
  Future<List<LifeOsWorkspaceMembership>> getAll() async =>
      value == null ? [] : [value!];
  @override
  Future<List<LifeOsWorkspaceMembership>> getActiveForMember(
    LifeOsEntityId memberEntityId,
  ) async => [];
  @override
  Future<List<LifeOsWorkspaceMembership>> getActiveForWorkspace(
    LifeOsEntityId workspaceId,
  ) async => [];
  @override
  Future<LifeOsWorkspaceMembership?> getById(LifeOsEntityId id) async => value;
  @override
  Future<LifeOsWorkspaceMembership?> getByPair(
    LifeOsEntityId workspaceId,
    LifeOsEntityId memberEntityId,
  ) async => value;
}

final class _ContextReader implements LifeOsWorkspaceContextReader {
  const _ContextReader(this.values);
  final List<LifeOsWorkspaceMember> values;
  @override
  Future<List<LifeOsWorkspaceMember>> getDirectMembers(
    LifeOsEntityId workspaceId,
  ) async => values;
  @override
  Future<List<LifeOsWorkspaceMember>> getUnassigned() async => values;
}

final class _CreationStore implements LifeOsWorkspaceMemberCreationStore {
  LifeOsTask? task;
  LifeOsNote? note;
  @override
  Future<void> createTaskInWorkspace(
    LifeOsTask task,
    LifeOsWorkspaceMembership membership,
  ) async {
    this.task = task;
  }

  @override
  Future<void> createNoteInWorkspace(
    LifeOsNote note,
    LifeOsWorkspaceMembership membership,
  ) async {
    this.note = note;
  }
}
