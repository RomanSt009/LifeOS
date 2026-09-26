import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/ai/lifeos_ai_context.dart';
import 'package:lifeos/application/use_cases/build_lifeos_ai_context.dart';
import 'package:lifeos/application/workspaces/lifeos_workspace_context_reader.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_workspace.dart';
import 'package:lifeos/domain/repositories/lifeos_workspace_repository.dart';

void main() {
  const workspaceId = LifeOsEntityId(
    value: 'workspace-1',
    entityType: LifeOsEntityType.workspace,
  );
  final baseTime = DateTime.utc(2026, 9, 26, 10);

  test(
    'builds typed active Workspace context in deterministic order',
    () async {
      final workspace = _workspace(
        workspaceId,
        baseTime,
        title: 'Work',
        description: 'abc',
      );
      final task = _task(
        'task-1',
        baseTime.add(const Duration(hours: 2)),
        title: 'Task',
        completed: true,
      );
      final note = _note(
        'note-1',
        baseTime.add(const Duration(hours: 1)),
        title: 'Note',
        content: 'Body',
      );
      final repository = _WorkspaceRepository(workspace);
      final reader = _ContextReader([_noteMember(note), _taskMember(task)]);

      final context =
          await BuildLifeOsAiContext(
            workspaceRepository: repository,
            workspaceContextReader: reader,
          )(
            BuildLifeOsAiContextInput(
              workspaceId: workspaceId,
              budget: LifeOsAiContextBudget(
                maxItems: 5,
                maxCharacters: 100,
                maxCharactersPerItem: 50,
              ),
            ),
          );

      expect(context.rootWorkspace.workspaceId, workspaceId);
      expect(context.rootWorkspace.title, 'Work');
      expect(context.rootWorkspace.description, 'abc');
      expect(
        context.rootWorkspace.provenance,
        LifeOsAiContextProvenance.workspaceRoot,
      );
      expect(context.items.map((item) => item.entityId.value), [
        'task-1',
        'note-1',
      ]);
      final taskItem = context.items.first as LifeOsAiTaskContextItem;
      expect(taskItem.isCompleted, isTrue);
      expect(taskItem.provenance, LifeOsAiContextProvenance.workspaceMember);
      final noteItem = context.items.last as LifeOsAiNoteContextItem;
      expect(noteItem.content, 'Body');
      expect(noteItem.truncated, isFalse);
      expect(context.usage.itemCount, 2);
      expect(context.usage.characterCount, 19);
      expect(context.usage.omittedItemCount, 0);
      expect(reader.directCalls, 1);
      expect(reader.unassignedCalls, 0);
      expect(repository.saveCount, 0);
    },
  );

  test('rejects invalid budget and missing or inactive Workspace', () async {
    expect(
      () => LifeOsAiContextBudget(
        maxItems: 0,
        maxCharacters: 1,
        maxCharactersPerItem: 1,
      ),
      throwsA(
        isA<LifeOsAiContextBuildException>().having(
          (error) => error.error,
          'error',
          LifeOsAiContextBuildError.invalidBudget,
        ),
      ),
    );

    final missingReader = _ContextReader(const []);
    final missingBuilder = BuildLifeOsAiContext(
      workspaceRepository: _WorkspaceRepository(null),
      workspaceContextReader: missingReader,
    );
    await expectLater(
      missingBuilder(_input(workspaceId)),
      throwsA(
        isA<LifeOsAiContextBuildException>().having(
          (error) => error.error,
          'error',
          LifeOsAiContextBuildError.workspaceNotFound,
        ),
      ),
    );
    expect(missingReader.directCalls, 0);

    final inactiveReader = _ContextReader(const []);
    final inactiveBuilder = BuildLifeOsAiContext(
      workspaceRepository: _WorkspaceRepository(
        _workspace(
          workspaceId,
          baseTime,
          lifecycle: LifeOsEntityLifecycle.archived,
        ),
      ),
      workspaceContextReader: inactiveReader,
    );
    await expectLater(
      inactiveBuilder(_input(workspaceId)),
      throwsA(
        isA<LifeOsAiContextBuildException>().having(
          (error) => error.error,
          'error',
          LifeOsAiContextBuildError.workspaceInactive,
        ),
      ),
    );
    expect(inactiveReader.directCalls, 0);
  });

  test(
    'filters inactive members, deduplicates, and enforces maxItems',
    () async {
      final newest = _task(
        'task-newest',
        baseTime.add(const Duration(hours: 3)),
        title: 'Newest',
      );
      final middle = _note(
        'note-middle',
        baseTime.add(const Duration(hours: 2)),
        title: 'Middle',
        content: 'Body',
      );
      final oldest = _task(
        'task-oldest',
        baseTime.add(const Duration(hours: 1)),
        title: 'Oldest',
      );
      final inactive = _note(
        'note-inactive',
        baseTime.add(const Duration(hours: 4)),
        title: 'Inactive',
        content: 'Hidden',
        lifecycle: LifeOsEntityLifecycle.deleted,
      );
      final reader = _ContextReader([
        _taskMember(oldest),
        _noteMember(inactive),
        _noteMember(middle),
        _taskMember(newest),
        _taskMember(newest),
      ]);

      final context =
          await BuildLifeOsAiContext(
            workspaceRepository: _WorkspaceRepository(
              _workspace(workspaceId, baseTime),
            ),
            workspaceContextReader: reader,
          )(
            BuildLifeOsAiContextInput(
              workspaceId: workspaceId,
              budget: LifeOsAiContextBudget(
                maxItems: 2,
                maxCharacters: 100,
                maxCharactersPerItem: 30,
              ),
            ),
          );

      expect(context.items.map((item) => item.entityId.value), [
        'task-newest',
        'note-middle',
      ]);
      expect(context.usage.deduplicatedItemCount, 1);
      expect(context.usage.omittedItemCount, 1);
    },
  );

  test('truncates by Unicode scalar budget and rebuilds identically', () async {
    final note = _note(
      'note-1',
      baseTime.add(const Duration(hours: 1)),
      title: 'N',
      content: 'a😀bc',
    );
    final builder = BuildLifeOsAiContext(
      workspaceRepository: _WorkspaceRepository(
        _workspace(workspaceId, baseTime, title: 'W', description: 'xyz'),
      ),
      workspaceContextReader: _ContextReader([_noteMember(note)]),
    );
    final input = BuildLifeOsAiContextInput(
      workspaceId: workspaceId,
      budget: LifeOsAiContextBudget(
        maxItems: 1,
        maxCharacters: 6,
        maxCharactersPerItem: 3,
      ),
    );

    final first = await builder(input);
    final second = await builder(input);
    final firstNote = first.items.single as LifeOsAiNoteContextItem;
    final secondNote = second.items.single as LifeOsAiNoteContextItem;

    expect(first.rootWorkspace.description, 'xy');
    expect(first.rootWorkspace.descriptionTruncated, isTrue);
    expect(firstNote.content, 'a😀');
    expect(firstNote.originalContentCharacterCount, 4);
    expect(firstNote.truncated, isTrue);
    expect(first.usage.characterCount, 6);
    expect(first.usage.truncatedProjectionCount, 2);
    expect(second.rootWorkspace.description, first.rootWorkspace.description);
    expect(secondNote.content, firstNote.content);
    expect(second.usage.characterCount, first.usage.characterCount);
  });

  test('stops before a partial item when its title cannot fit', () async {
    final first = _task(
      'task-1',
      baseTime.add(const Duration(hours: 2)),
      title: 'First',
    );
    final second = _task(
      'task-2',
      baseTime.add(const Duration(hours: 1)),
      title: 'Second',
    );
    final context =
        await BuildLifeOsAiContext(
          workspaceRepository: _WorkspaceRepository(
            _workspace(workspaceId, baseTime, title: 'W'),
          ),
          workspaceContextReader: _ContextReader([
            _taskMember(first),
            _taskMember(second),
          ]),
        )(
          BuildLifeOsAiContextInput(
            workspaceId: workspaceId,
            budget: LifeOsAiContextBudget(
              maxItems: 2,
              maxCharacters: 5,
              maxCharactersPerItem: 10,
            ),
          ),
        );

    expect(context.items, isEmpty);
    expect(context.usage.omittedItemCount, 2);
    expect(context.usage.characterCount, 1);
  });
}

BuildLifeOsAiContextInput _input(LifeOsEntityId workspaceId) =>
    BuildLifeOsAiContextInput(
      workspaceId: workspaceId,
      budget: LifeOsAiContextBudget(
        maxItems: 5,
        maxCharacters: 100,
        maxCharactersPerItem: 50,
      ),
    );

LifeOsWorkspace _workspace(
  LifeOsEntityId id,
  DateTime timestamp, {
  String title = 'Workspace',
  String? description,
  LifeOsEntityLifecycle lifecycle = LifeOsEntityLifecycle.active,
}) => LifeOsWorkspace(
  id: id,
  title: title,
  description: description,
  createdAt: timestamp,
  updatedAt: timestamp,
  lifecycle: lifecycle,
  version: 1,
  source: LifeOsEntitySource.user,
);

LifeOsTask _task(
  String id,
  DateTime updatedAt, {
  required String title,
  bool completed = false,
  LifeOsEntityLifecycle lifecycle = LifeOsEntityLifecycle.active,
}) => LifeOsTask(
  id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.task),
  title: title,
  isCompleted: completed,
  createdAt: updatedAt,
  updatedAt: updatedAt,
  lifecycle: lifecycle,
  version: 1,
  source: LifeOsEntitySource.user,
);

LifeOsNote _note(
  String id,
  DateTime updatedAt, {
  required String title,
  required String content,
  LifeOsEntityLifecycle lifecycle = LifeOsEntityLifecycle.active,
}) => LifeOsNote(
  id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.note),
  title: title,
  content: content,
  createdAt: updatedAt,
  updatedAt: updatedAt,
  lifecycle: lifecycle,
  version: 1,
  source: LifeOsEntitySource.user,
);

LifeOsWorkspaceTaskMember _taskMember(LifeOsTask task) =>
    LifeOsWorkspaceTaskMember(
      membershipId: LifeOsEntityId(
        value: 'membership-' + task.id.value,
        entityType: LifeOsEntityType.workspaceMembership,
      ),
      task: task,
    );

LifeOsWorkspaceNoteMember _noteMember(LifeOsNote note) =>
    LifeOsWorkspaceNoteMember(
      membershipId: LifeOsEntityId(
        value: 'membership-' + note.id.value,
        entityType: LifeOsEntityType.workspaceMembership,
      ),
      note: note,
    );

final class _WorkspaceRepository implements LifeOsWorkspaceRepository {
  _WorkspaceRepository(this.workspace);

  final LifeOsWorkspace? workspace;
  var saveCount = 0;

  @override
  Future<List<LifeOsWorkspace>> getAll() async =>
      workspace == null ? [] : [workspace!];

  @override
  Future<LifeOsWorkspace?> getById(LifeOsEntityId id) async =>
      workspace?.id == id ? workspace : null;

  @override
  Future<List<LifeOsWorkspace>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async => workspace?.lifecycle == lifecycle ? [workspace!] : [];

  @override
  Future<void> save(LifeOsWorkspace workspace) async {
    saveCount++;
  }
}

final class _ContextReader implements LifeOsWorkspaceContextReader {
  _ContextReader(this.members);

  final List<LifeOsWorkspaceMember> members;
  var directCalls = 0;
  var unassignedCalls = 0;

  @override
  Future<List<LifeOsWorkspaceMember>> getDirectMembers(
    LifeOsEntityId workspaceId,
  ) async {
    directCalls++;
    return members;
  }

  @override
  Future<List<LifeOsWorkspaceMember>> getUnassigned() async {
    unassignedCalls++;
    return const [];
  }
}
