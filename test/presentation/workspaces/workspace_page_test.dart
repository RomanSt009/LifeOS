import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/create_lifeos_entity_in_workspace.dart';
import 'package:lifeos/application/use_cases/create_lifeos_workspace.dart';
import 'package:lifeos/application/use_cases/delete_lifeos_task.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_workspace.dart';
import 'package:lifeos/application/use_cases/get_lifeos_workspace_context.dart';
import 'package:lifeos/application/use_cases/get_lifeos_workspaces.dart';
import 'package:lifeos/application/use_cases/lifeos_workspace_lifecycle.dart';
import 'package:lifeos/application/use_cases/lifeos_workspace_membership.dart';
import 'package:lifeos/application/use_cases/restore_lifeos_task.dart';
import 'package:lifeos/application/workspaces/lifeos_workspace_context_reader.dart';
import 'package:lifeos/application/workspaces/lifeos_workspace_member_creation_store.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_workspace.dart';
import 'package:lifeos/domain/entities/lifeos_workspace_membership.dart';
import 'package:lifeos/domain/repositories/lifeos_note_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_workspace_membership_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_workspace_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/notes/note_providers.dart';
import 'package:lifeos/presentation/tasks/task_list_providers.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';
import 'package:lifeos/presentation/workspaces/workspace_page.dart';
import 'package:lifeos/presentation/workspaces/workspace_providers.dart';

void main() {
  testWidgets('shows loading, empty, and recoverable load error states', (
    tester,
  ) async {
    final harness = _Harness();
    harness.workspaceRepository.readGate = Completer<void>();

    await _pump(tester, harness);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    harness.workspaceRepository.readGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('No Workspaces yet'), findsOneWidget);

    harness.workspaceRepository.failReads = 1;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkspacePage)),
    );
    container.invalidate(workspaceListControllerProvider);
    await tester.pumpAndSettle();
    expect(find.text('Unable to load Workspaces'), findsOneWidget);

    await tester.tap(find.byKey(const Key('retry-workspaces')));
    await tester.pumpAndSettle();
    expect(find.text('No Workspaces yet'), findsOneWidget);
  });

  testWidgets('creates, edits, trashes, restores, and clears selection', (
    tester,
  ) async {
    final harness = _Harness();
    await _pump(tester, harness);

    await tester.tap(find.byKey(const Key('new-workspace-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-workspace-action')));
    await tester.pump();
    expect(find.text('Enter a Workspace title'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('workspace-title-field')),
      '  Product  ',
    );
    await tester.enterText(
      find.byKey(const Key('workspace-description-field')),
      ' literal description ',
    );
    await tester.tap(find.byKey(const Key('save-workspace-action')));
    await tester.pumpAndSettle();

    expect(find.text('Product'), findsWidgets);
    expect(find.text(' literal description '), findsWidgets);
    expect(
      harness.workspaceRepository.values.single.description,
      ' literal description ',
    );

    await tester.tap(find.byKey(const Key('edit-workspace-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workspace-title-field')),
      'Product Alpha',
    );
    await tester.tap(find.byKey(const Key('save-workspace-action')));
    await tester.pumpAndSettle();
    expect(find.text('Product Alpha'), findsWidgets);

    await tester.tap(find.byKey(const Key('delete-workspace-action')));
    await tester.pumpAndSettle();
    expect(find.textContaining('will be moved to Trash'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-workspace')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-detail-title')), findsNothing);
    expect(
      harness.workspaceRepository.values.single.lifecycle,
      LifeOsEntityLifecycle.deleted,
    );

    await tester.tap(find.byKey(const Key('workspace-trash-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Product Alpha'), findsOneWidget);
    await tester.tap(
      find.byKey(
        Key(
          'restore-workspace-${harness.workspaceRepository.values.single.id.value}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No deleted Workspaces'), findsOneWidget);

    await tester.tap(find.byKey(const Key('workspace-trash-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Product Alpha'), findsOneWidget);
  });

  testWidgets('lifecycle errors are visible and retryable', (tester) async {
    final harness = _Harness.seeded();
    await _pump(tester, harness);
    await _openSeededWorkspace(tester, harness);

    harness.workspaceRepository.failSaves = 1;
    await tester.tap(find.byKey(const Key('delete-workspace-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-workspace')));
    await tester.pumpAndSettle();
    expect(find.text('Unable to move Workspace to Trash'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-workspace')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('workspace-trash-toggle')));
    await tester.pumpAndSettle();
    harness.workspaceRepository.failSaves = 1;
    await tester.tap(find.byKey(const Key('restore-workspace-workspace-1')));
    await tester.pumpAndSettle();
    expect(find.text('Unable to restore Workspace'), findsOneWidget);
    await tester.tap(find.byKey(const Key('restore-workspace-workspace-1')));
    await tester.pumpAndSettle();
    expect(find.text('No deleted Workspaces'), findsOneWidget);
  });

  testWidgets('renders mixed members and supports quick create', (
    tester,
  ) async {
    final harness = _Harness.seeded();
    await _pump(tester, harness);
    await _openSeededWorkspace(tester, harness);

    expect(find.text('Seed Task'), findsOneWidget);
    expect(find.text('Seed Note'), findsOneWidget);

    await tester.tap(find.byKey(const Key('workspace-add-task-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workspace-task-title-field')),
      'Context Task',
    );
    await tester.tap(find.byKey(const Key('confirm-workspace-member-create')));
    await tester.pumpAndSettle();
    expect(find.text('Context Task'), findsOneWidget);
    expect(
      harness.taskRepository.values.any((task) => task.title == 'Context Task'),
      isTrue,
    );

    await tester.tap(find.byKey(const Key('workspace-add-note-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workspace-note-title-field')),
      'Context Note',
    );
    await tester.enterText(
      find.byKey(const Key('workspace-note-content-field')),
      '  literal note body  ',
    );
    await tester.tap(find.byKey(const Key('confirm-workspace-member-create')));
    await tester.pumpAndSettle();
    expect(find.text('Context Note'), findsOneWidget);
    expect(
      harness.noteRepository.values
          .singleWhere((note) => note.title == 'Context Note')
          .content,
      '  literal note body  ',
    );
    expect(harness.creationStore.taskCreateCalls, 1);
    expect(harness.creationStore.noteCreateCalls, 1);
  });

  testWidgets(
    'Unassigned renders mixed effective projection and assigns Task and Note',
    (tester) async {
      final harness = _Harness.seeded(includeUnattached: true);
      final deletedWorkspace = _workspace(
        'workspace-deleted',
        'Deleted Workspace',
      ).delete(updatedAt: _time.add(const Duration(minutes: 1)));
      final deletedOnlyTask = _task(
        'task-deleted-context',
        'Deleted context Task',
      );
      final mixedNote = _note(
        'note-mixed-context',
        'Mixed context Note',
        'Body',
      );
      final activeSecond = _workspace('workspace-2', 'Second Workspace');
      final deletedMember = _task(
        'task-deleted-member',
        'Deleted member',
      ).delete(updatedAt: _time.add(const Duration(minutes: 2)));
      harness.workspaceRepository.values.addAll([
        deletedWorkspace,
        activeSecond,
      ]);
      harness.taskRepository.values.addAll([deletedOnlyTask, deletedMember]);
      harness.noteRepository.values.add(mixedNote);
      harness.membershipRepository.values.addAll([
        _membership(
          'membership-deleted-only',
          deletedWorkspace.id,
          deletedOnlyTask.id,
        ),
        _membership(
          'membership-mixed-deleted',
          deletedWorkspace.id,
          mixedNote.id,
        ),
        _membership('membership-mixed-active', activeSecond.id, mixedNote.id),
      ]);

      await _pump(tester, harness, size: const Size(640, 600));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('workspace-unassigned-action')));
      await tester.pumpAndSettle();

      expect(find.text('Unattached Task'), findsOneWidget);
      expect(find.text('Unattached Note'), findsOneWidget);
      expect(find.text('Deleted context Task'), findsOneWidget);
      expect(find.text('Seed Task'), findsNothing);
      expect(find.text('Seed Note'), findsNothing);
      expect(find.text('Mixed context Note'), findsNothing);
      expect(find.text('Deleted member'), findsNothing);

      await tester.tap(find.byKey(const Key('assign-task-task-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('assign-to-workspace-1')));
      await tester.pumpAndSettle();
      expect(find.text('Unattached Task'), findsNothing);
      expect(
        harness.membershipRepository.values.where(
          (membership) => membership.memberEntityId.value == 'task-2',
        ),
        hasLength(1),
      );

      await tester.tap(find.byKey(const Key('assign-note-note-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('assign-to-workspace-2')));
      await tester.pumpAndSettle();
      expect(find.text('Unattached Note'), findsNothing);
      expect(
        harness.membershipRepository.values.where(
          (membership) => membership.memberEntityId.value == 'note-2',
        ),
        hasLength(1),
      );
    },
  );

  testWidgets('Unassigned recovers from error and shows empty state', (
    tester,
  ) async {
    final harness = _Harness();
    harness.contextReader.failUnassignedReads = 1;
    await _pump(tester, harness);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workspace-unassigned-action')));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load unassigned items'), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry-unassigned')));
    await tester.pumpAndSettle();
    expect(find.text('No unassigned Tasks or Notes'), findsOneWidget);
  });

  testWidgets(
    'restoring Workspace makes preserved memberships effective again',
    (tester) async {
      final harness = _Harness.seeded();
      harness.workspaceRepository.values[0] = harness
          .workspaceRepository
          .values[0]
          .delete(updatedAt: _time.add(const Duration(minutes: 1)));

      await _pump(tester, harness);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('workspace-unassigned-action')));
      await tester.pumpAndSettle();
      expect(find.text('Seed Task'), findsOneWidget);
      expect(find.text('Seed Note'), findsOneWidget);

      await tester.tap(find.byKey(const Key('back-from-unassigned')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('workspace-trash-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore-workspace-workspace-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('workspace-trash-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('workspace-unassigned-action')));
      await tester.pumpAndSettle();

      expect(find.text('No unassigned Tasks or Notes'), findsOneWidget);
      expect(find.text('Seed Task'), findsNothing);
      expect(find.text('Seed Note'), findsNothing);
      expect(harness.membershipRepository.values, hasLength(2));
    },
  );

  testWidgets('attaches, detaches, and reattaches without deleting Entity', (
    tester,
  ) async {
    final harness = _Harness.seeded(includeUnattached: true);
    await _pump(tester, harness);
    await _openSeededWorkspace(tester, harness);

    await tester.tap(find.byKey(const Key('workspace-attach-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('attach-task-task-1')), findsNothing);
    expect(find.byKey(const Key('attach-note-note-1')), findsNothing);
    await tester.tap(find.text('Unattached Task'));
    await tester.pumpAndSettle();
    expect(find.text('Unattached Task'), findsOneWidget);

    await tester.tap(find.byKey(const Key('workspace-attach-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unattached Note'));
    await tester.pumpAndSettle();
    expect(find.text('Unattached Note'), findsOneWidget);

    final task = harness.taskRepository.values.singleWhere(
      (item) => item.title == 'Unattached Task',
    );
    final membership = await harness.membershipRepository.getByPair(
      harness.workspaceRepository.values.single.id,
      task.id,
    );
    expect(membership, isNotNull);

    final tile = find.byKey(Key('workspace-task-${task.id.value}'));
    await tester.tap(
      find.descendant(of: tile, matching: find.text('Remove from Workspace')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(
        'The Task or Note will remain available outside this Workspace. Its relationships will not be changed.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm-workspace-detach')));
    await tester.pumpAndSettle();
    expect(find.text('Unattached Task'), findsNothing);
    expect(await harness.taskRepository.getById(task.id), isNotNull);
    expect(
      (await harness.membershipRepository.getByPair(
        harness.workspaceRepository.values.single.id,
        task.id,
      ))!.lifecycle,
      LifeOsEntityLifecycle.deleted,
    );

    await tester.tap(find.byKey(const Key('workspace-attach-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unattached Task'));
    await tester.pumpAndSettle();
    final reattached = await harness.membershipRepository.getByPair(
      harness.workspaceRepository.values.single.id,
      task.id,
    );
    expect(reattached!.id, membership!.id);
    expect(reattached.lifecycle, LifeOsEntityLifecycle.active);
  });

  testWidgets('blocks duplicate quick create and recovers from failure', (
    tester,
  ) async {
    final harness = _Harness.seeded();
    harness.creationStore.taskGate = Completer<void>();
    harness.creationStore.failTaskCreate = true;
    await _pump(tester, harness);
    await _openSeededWorkspace(tester, harness);

    await tester.tap(find.byKey(const Key('workspace-add-task-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workspace-task-title-field')),
      'Delayed Task',
    );
    await tester.tap(find.byKey(const Key('confirm-workspace-member-create')));
    await tester.pump();
    expect(harness.creationStore.taskCreateCalls, 1);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('confirm-workspace-member-create')),
          )
          .onPressed,
      isNull,
    );

    harness.creationStore.taskGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Unable to create Task in Workspace'), findsOneWidget);

    harness.creationStore.failTaskCreate = false;
    harness.creationStore.taskGate = null;
    await tester.tap(find.byKey(const Key('confirm-workspace-member-create')));
    await tester.pumpAndSettle();
    expect(find.text('Delayed Task'), findsOneWidget);
    expect(harness.creationStore.taskCreateCalls, 2);
  });

  testWidgets('global Task lifecycle refreshes ordinary Workspace projection', (
    tester,
  ) async {
    final harness = _Harness.seeded();
    await _pump(tester, harness);
    await _openSeededWorkspace(tester, harness);
    expect(find.text('Seed Task'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkspacePage)),
    );
    final task = harness.taskRepository.values.single;
    await container.read(taskListControllerProvider.future);
    await container
        .read(taskListControllerProvider.notifier)
        .deleteTask(task.id);
    await tester.pumpAndSettle();
    expect(find.text('Seed Task'), findsNothing);
    expect(
      (await harness.membershipRepository.getActiveForMember(task.id)),
      hasLength(1),
    );

    await container.read(taskTrashControllerProvider.future);
    await container
        .read(taskTrashControllerProvider.notifier)
        .restoreTask(task.id);
    await tester.pumpAndSettle();
    expect(find.text('Seed Task'), findsOneWidget);
  });

  for (final size in [const Size(1280, 800), const Size(640, 600)]) {
    testWidgets('is usable without overflow at ${size.width}x${size.height}', (
      tester,
    ) async {
      final harness = _Harness.seeded(extraMembers: 12);
      await _pump(tester, harness, size: size);
      await _openSeededWorkspace(tester, harness);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('workspace-detail-scroll')), findsOneWidget);
      await tester.drag(
        find.byKey(const Key('workspace-detail-scroll')),
        const Offset(0, -800),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('renders new static strings in Russian', (tester) async {
    final harness = _Harness.seeded();
    await _pump(tester, harness, locale: const Locale('ru'));
    expect(find.text('Рабочие пространства'), findsOneWidget);
    expect(find.text('Новое рабочее пространство'), findsOneWidget);
    await _openSeededWorkspace(tester, harness);
    expect(find.text('Добавить существующее'), findsOneWidget);
    expect(find.text('Убрать из рабочего пространства'), findsWidgets);
  });
}

Future<void> _pump(
  WidgetTester tester,
  _Harness harness, {
  Locale locale = const Locale('en'),
  Size size = const Size(1280, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: harness.overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: WorkspacePage()),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _openSeededWorkspace(WidgetTester tester, _Harness harness) async {
  await tester.pumpAndSettle();
  final id = harness.workspaceRepository.values.single.id.value;
  await tester.tap(find.byKey(Key('workspace-$id')));
  await tester.pumpAndSettle();
}

final class _Harness {
  _Harness()
    : workspaceRepository = _WorkspaceRepository(),
      membershipRepository = _MembershipRepository(),
      taskRepository = _TaskRepository(),
      noteRepository = _NoteRepository() {
    _initialize();
  }

  factory _Harness.seeded({
    bool includeUnattached = false,
    int extraMembers = 0,
  }) {
    final harness = _Harness();
    final workspace = _workspace('workspace-1', 'Work');
    final task = _task('task-1', 'Seed Task', completed: true);
    final note = _note('note-1', 'Seed Note', 'Seed body');
    harness.workspaceRepository.values.add(workspace);
    harness.taskRepository.values.add(task);
    harness.noteRepository.values.add(note);
    harness.membershipRepository.values.addAll([
      _membership('membership-1', workspace.id, task.id),
      _membership('membership-2', workspace.id, note.id),
    ]);
    if (includeUnattached) {
      harness.taskRepository.values.add(_task('task-2', 'Unattached Task'));
      harness.noteRepository.values.add(
        _note('note-2', 'Unattached Note', 'Body'),
      );
    }
    for (var index = 0; index < extraMembers; index++) {
      final extra = _task('extra-$index', 'Extra Task $index');
      harness.taskRepository.values.add(extra);
      harness.membershipRepository.values.add(
        _membership('extra-membership-$index', workspace.id, extra.id),
      );
    }
    return harness;
  }

  final _WorkspaceRepository workspaceRepository;
  final _MembershipRepository membershipRepository;
  final _TaskRepository taskRepository;
  final _NoteRepository noteRepository;
  late final _ContextReader contextReader;
  late final _CreationStore creationStore;
  late final dynamic overrides;
  var _id = 100;
  var _seconds = 100;

  String _nextId() => 'generated-${_id++}';
  DateTime _clock() => _time.add(Duration(seconds: _seconds++));

  void _initialize() {
    contextReader = _ContextReader(
      workspaceRepository,
      membershipRepository,
      taskRepository,
      noteRepository,
    );
    creationStore = _CreationStore(
      membershipRepository,
      taskRepository,
      noteRepository,
    );
    overrides = [
      createLifeOsWorkspaceProvider.overrideWithValue(
        CreateLifeOsWorkspace(
          repository: workspaceRepository,
          entityIdGenerator: _nextId,
          utcClock: _clock,
        ),
      ),
      editLifeOsWorkspaceProvider.overrideWithValue(
        EditLifeOsWorkspace(repository: workspaceRepository, utcClock: _clock),
      ),
      getLifeOsWorkspacesProvider.overrideWithValue(
        GetLifeOsWorkspaces(workspaceRepository),
      ),
      getDeletedLifeOsWorkspacesProvider.overrideWithValue(
        GetDeletedLifeOsWorkspaces(workspaceRepository),
      ),
      deleteLifeOsWorkspaceProvider.overrideWithValue(
        DeleteLifeOsWorkspace(
          repository: workspaceRepository,
          utcClock: _clock,
        ),
      ),
      restoreLifeOsWorkspaceProvider.overrideWithValue(
        RestoreLifeOsWorkspace(
          repository: workspaceRepository,
          utcClock: _clock,
        ),
      ),
      getLifeOsWorkspaceMembersProvider.overrideWithValue(
        GetLifeOsWorkspaceMembers(contextReader),
      ),
      getUnassignedLifeOsWorkspaceMembersProvider.overrideWithValue(
        GetUnassignedLifeOsWorkspaceMembers(contextReader),
      ),
      attachLifeOsWorkspaceMemberProvider.overrideWithValue(
        AttachLifeOsWorkspaceMember(
          repository: membershipRepository,
          entityIdGenerator: _nextId,
          utcClock: _clock,
        ),
      ),
      detachLifeOsWorkspaceMemberProvider.overrideWithValue(
        DetachLifeOsWorkspaceMember(
          repository: membershipRepository,
          utcClock: _clock,
        ),
      ),
      createLifeOsTaskInWorkspaceProvider.overrideWithValue(
        CreateLifeOsTaskInWorkspace(
          workspaceRepository: workspaceRepository,
          store: creationStore,
          entityIdGenerator: _nextId,
          utcClock: _clock,
        ),
      ),
      createLifeOsNoteInWorkspaceProvider.overrideWithValue(
        CreateLifeOsNoteInWorkspace(
          workspaceRepository: workspaceRepository,
          store: creationStore,
          entityIdGenerator: _nextId,
          utcClock: _clock,
        ),
      ),
      lifeOsTaskRepositoryProvider.overrideWithValue(taskRepository),
      lifeOsNoteRepositoryProvider.overrideWithValue(noteRepository),
      deleteLifeOsTaskProvider.overrideWithValue(
        DeleteLifeOsTask(repository: taskRepository, utcClock: _clock),
      ),
      restoreLifeOsTaskProvider.overrideWithValue(
        RestoreLifeOsTask(repository: taskRepository, utcClock: _clock),
      ),
    ];
  }
}

final class _WorkspaceRepository implements LifeOsWorkspaceRepository {
  final values = <LifeOsWorkspace>[];
  Completer<void>? readGate;
  int failReads = 0;
  int failSaves = 0;

  @override
  Future<List<LifeOsWorkspace>> getAll() async => List.of(values);

  @override
  Future<LifeOsWorkspace?> getById(LifeOsEntityId id) async =>
      values.where((item) => item.id == id).firstOrNull;

  @override
  Future<List<LifeOsWorkspace>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async {
    final gate = readGate;
    if (gate != null) {
      await gate.future;
      readGate = null;
    }
    if (failReads > 0) {
      failReads--;
      throw StateError('read failed');
    }
    return values.where((item) => item.lifecycle == lifecycle).toList();
  }

  @override
  Future<void> save(LifeOsWorkspace workspace) async {
    if (failSaves > 0) {
      failSaves--;
      throw StateError('save failed');
    }
    values.removeWhere((item) => item.id == workspace.id);
    values.add(workspace);
  }
}

final class _TaskRepository implements LifeOsTaskRepository {
  final values = <LifeOsTask>[];

  @override
  Future<List<LifeOsTask>> getAll() async => List.of(values);

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async =>
      values.where((item) => item.id == id).firstOrNull;

  @override
  Future<List<LifeOsTask>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async => values.where((item) => item.lifecycle == lifecycle).toList();

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async => values
      .where((item) => item.title.toLowerCase().contains(query.toLowerCase()))
      .toList();

  @override
  Future<void> save(LifeOsTask task) async {
    values.removeWhere((item) => item.id == task.id);
    values.add(task);
  }
}

final class _NoteRepository implements LifeOsNoteRepository {
  final values = <LifeOsNote>[];

  @override
  Future<List<LifeOsNote>> getAll() async => List.of(values);

  @override
  Future<LifeOsNote?> getById(LifeOsEntityId id) async =>
      values.where((item) => item.id == id).firstOrNull;

  @override
  Future<List<LifeOsNote>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async => values.where((item) => item.lifecycle == lifecycle).toList();

  @override
  Future<void> save(LifeOsNote note) async {
    values.removeWhere((item) => item.id == note.id);
    values.add(note);
  }
}

final class _MembershipRepository
    implements LifeOsWorkspaceMembershipRepository {
  final values = <LifeOsWorkspaceMembership>[];

  @override
  Future<List<LifeOsWorkspaceMembership>> getAll() async => List.of(values);

  @override
  Future<LifeOsWorkspaceMembership?> getById(LifeOsEntityId id) async =>
      values.where((item) => item.id == id).firstOrNull;

  @override
  Future<LifeOsWorkspaceMembership?> getByPair(
    LifeOsEntityId workspaceId,
    LifeOsEntityId memberEntityId,
  ) async => values
      .where(
        (item) =>
            item.workspaceId == workspaceId &&
            item.memberEntityId == memberEntityId,
      )
      .firstOrNull;

  @override
  Future<List<LifeOsWorkspaceMembership>> getActiveForMember(
    LifeOsEntityId memberEntityId,
  ) async => values
      .where(
        (item) =>
            item.memberEntityId == memberEntityId &&
            item.lifecycle == LifeOsEntityLifecycle.active,
      )
      .toList();

  @override
  Future<List<LifeOsWorkspaceMembership>> getActiveForWorkspace(
    LifeOsEntityId workspaceId,
  ) async => values
      .where(
        (item) =>
            item.workspaceId == workspaceId &&
            item.lifecycle == LifeOsEntityLifecycle.active,
      )
      .toList();

  @override
  Future<LifeOsWorkspaceMembership> attach({
    required LifeOsEntityId workspaceId,
    required LifeOsEntityId memberEntityId,
    required LifeOsEntityId newMembershipId,
    required DateTime timestamp,
  }) async {
    final existing = await getByPair(workspaceId, memberEntityId);
    if (existing != null) {
      final attached = existing.reattach(updatedAt: timestamp);
      values.remove(existing);
      values.add(attached);
      return attached;
    }
    final membership = LifeOsWorkspaceMembership.createUserMembership(
      id: newMembershipId,
      workspaceId: workspaceId,
      memberEntityId: memberEntityId,
      timestamp: timestamp,
    );
    values.add(membership);
    return membership;
  }

  @override
  Future<LifeOsWorkspaceMembership?> remove({
    required LifeOsEntityId membershipId,
    required DateTime timestamp,
  }) async {
    final existing = await getById(membershipId);
    if (existing == null) return null;
    final removed = existing.remove(updatedAt: timestamp);
    values.remove(existing);
    values.add(removed);
    return removed;
  }
}

final class _ContextReader implements LifeOsWorkspaceContextReader {
  _ContextReader(this.workspaces, this.memberships, this.tasks, this.notes);

  final _WorkspaceRepository workspaces;
  final _MembershipRepository memberships;
  final _TaskRepository tasks;
  final _NoteRepository notes;
  int failUnassignedReads = 0;

  @override
  Future<List<LifeOsWorkspaceMember>> getDirectMembers(
    LifeOsEntityId workspaceId,
  ) async {
    final result = <LifeOsWorkspaceMember>[];
    for (final membership in await memberships.getActiveForWorkspace(
      workspaceId,
    )) {
      if (membership.memberEntityId.entityType == LifeOsEntityType.task) {
        final task = await tasks.getById(membership.memberEntityId);
        if (task?.lifecycle == LifeOsEntityLifecycle.active) {
          result.add(
            LifeOsWorkspaceTaskMember(membershipId: membership.id, task: task!),
          );
        }
      } else {
        final note = await notes.getById(membership.memberEntityId);
        if (note?.lifecycle == LifeOsEntityLifecycle.active) {
          result.add(
            LifeOsWorkspaceNoteMember(membershipId: membership.id, note: note!),
          );
        }
      }
    }
    return result;
  }

  @override
  Future<List<LifeOsWorkspaceMember>> getUnassigned() async {
    if (failUnassignedReads > 0) {
      failUnassignedReads--;
      throw StateError('unassigned failed');
    }
    final activeWorkspaceIds = <LifeOsEntityId>{
      for (final workspace in workspaces.values)
        if (workspace.lifecycle == LifeOsEntityLifecycle.active) workspace.id,
    };
    bool isAssigned(LifeOsEntityId memberId) => memberships.values.any(
      (membership) =>
          membership.memberEntityId == memberId &&
          membership.lifecycle == LifeOsEntityLifecycle.active &&
          activeWorkspaceIds.contains(membership.workspaceId),
    );
    return [
      for (final task in tasks.values)
        if (task.lifecycle == LifeOsEntityLifecycle.active &&
            !isAssigned(task.id))
          LifeOsWorkspaceTaskMember(membershipId: null, task: task),
      for (final note in notes.values)
        if (note.lifecycle == LifeOsEntityLifecycle.active &&
            !isAssigned(note.id))
          LifeOsWorkspaceNoteMember(membershipId: null, note: note),
    ];
  }
}

final class _CreationStore implements LifeOsWorkspaceMemberCreationStore {
  _CreationStore(this.memberships, this.tasks, this.notes);

  final _MembershipRepository memberships;
  final _TaskRepository tasks;
  final _NoteRepository notes;
  Completer<void>? taskGate;
  bool failTaskCreate = false;
  int taskCreateCalls = 0;
  int noteCreateCalls = 0;

  @override
  Future<void> createTaskInWorkspace(
    LifeOsTask task,
    LifeOsWorkspaceMembership membership,
  ) async {
    taskCreateCalls++;
    final gate = taskGate;
    if (gate != null) await gate.future;
    if (failTaskCreate) throw StateError('create failed');
    await tasks.save(task);
    memberships.values.add(membership);
  }

  @override
  Future<void> createNoteInWorkspace(
    LifeOsNote note,
    LifeOsWorkspaceMembership membership,
  ) async {
    noteCreateCalls++;
    await notes.save(note);
    memberships.values.add(membership);
  }
}

final _time = DateTime.utc(2026, 9, 20, 12);

LifeOsWorkspace _workspace(String id, String title) =>
    LifeOsWorkspace.createUserWorkspace(
      id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.workspace),
      title: title,
      description: 'Workspace description',
      timestamp: _time,
    );

LifeOsTask _task(String id, String title, {bool completed = false}) =>
    LifeOsTask(
      id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.task),
      title: title,
      isCompleted: completed,
      createdAt: _time,
      updatedAt: _time,
      lifecycle: LifeOsEntityLifecycle.active,
      version: 1,
      source: LifeOsEntitySource.user,
    );

LifeOsNote _note(String id, String title, String content) =>
    LifeOsNote.createUserNote(
      id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.note),
      title: title,
      content: content,
      timestamp: _time,
    );

LifeOsWorkspaceMembership _membership(
  String id,
  LifeOsEntityId workspaceId,
  LifeOsEntityId memberId,
) => LifeOsWorkspaceMembership.createUserMembership(
  id: LifeOsEntityId(
    value: id,
    entityType: LifeOsEntityType.workspaceMembership,
  ),
  workspaceId: workspaceId,
  memberEntityId: memberId,
  timestamp: _time,
);
