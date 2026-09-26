import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/relationships/lifeos_related_entity_reader.dart';
import 'package:lifeos/application/use_cases/get_direct_lifeos_related_neighbors.dart';
import 'package:lifeos/application/search/lifeos_search_result.dart';
import 'package:lifeos/application/search/lifeos_unified_search_reader.dart';
import 'package:lifeos/application/use_cases/search_lifeos_entities.dart';
import 'package:lifeos/application/use_cases/create_lifeos_note.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_note.dart';
import 'package:lifeos/application/use_cases/get_lifeos_workspace_context.dart';
import 'package:lifeos/application/use_cases/get_lifeos_workspaces.dart';
import 'package:lifeos/application/workspaces/lifeos_workspace_context_reader.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_relationship.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_workspace.dart';
import 'package:lifeos/domain/repositories/lifeos_note_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_workspace_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/navigation/lifeos_destination.dart';
import 'package:lifeos/presentation/notes/note_providers.dart';
import 'package:lifeos/presentation/relationships/relationship_providers.dart';
import 'package:lifeos/presentation/shell/lifeos_shell_page.dart';
import 'package:lifeos/presentation/search/unified_search_page.dart';
import 'package:lifeos/presentation/search/unified_search_providers.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';
import 'package:lifeos/presentation/tasks/task_list.dart';
import 'package:lifeos/presentation/workspaces/workspace_page.dart';
import 'package:lifeos/presentation/workspaces/workspace_providers.dart';

void main() {
  for (final scenario in [
    (
      name: 'wide desktop window',
      size: const Size(1280, 800),
      locale: const Locale('en'),
      taskAction: 'Add Task',
    ),
    (
      name: 'moderately narrow desktop window',
      size: const Size(640, 600),
      locale: const Locale('ru'),
      taskAction: 'Добавить задачу',
    ),
  ]) {
    testWidgets('keeps shell and Task UI usable in a ${scenario.name}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(scenario.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(testApp(scenario.locale));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('navigation-tasks-label')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail).hitTestable(), findsOneWidget);
      expect(
        find.byKey(const Key('task-title-field')).hitTestable(),
        findsOneWidget,
      );
      expect(find.text(scenario.taskAction).hitTestable(), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Layout check',
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Layout check'), findsOneWidget);

      await tester.tap(find.byKey(const Key('navigation-home-label')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('home-new-task-action')).hitTestable(),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const Key('home-settings-action')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('home-settings-action')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('navigation-tasks-label')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('task-trash-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('task-trash-toggle')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('navigation-notes-label')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('note-title-field')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('note-trash-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('note-trash-toggle')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('navigation-search-label')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('search-query-field')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('search-submit-button')).hitTestable(),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('navigation-settings-label')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('backup-settings-page')).hitTestable(),
        findsOneWidget,
      );
    });
  }

  testWidgets('exposes only the justified initial destinations', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const Locale('en')));
    await tester.pumpAndSettle();

    final navigationRail = tester.widget<NavigationRail>(
      find.byType(NavigationRail),
    );

    expect(LifeOsDestination.values, [
      LifeOsDestination.home,
      LifeOsDestination.workspaces,
      LifeOsDestination.tasks,
      LifeOsDestination.notes,
      LifeOsDestination.search,
      LifeOsDestination.settings,
    ]);
    expect(navigationRail.destinations, hasLength(6));
    expect(destinationLabels(navigationRail), [
      'Home',
      'Workspaces',
      'Tasks',
      'Notes',
      'Search',
      'Settings',
    ]);
  });

  testWidgets('shows a persistent desktop frame with Home selected', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const Locale('en')));
    await tester.pumpAndSettle();

    final navigationRail = tester.widget<NavigationRail>(
      find.byType(NavigationRail),
    );

    expect(navigationRail.selectedIndex, LifeOsDestination.home.index);
    expect(navigationRail.labelType, NavigationRailLabelType.all);
    expect(destinationLabels(navigationRail), [
      'Home',
      'Workspaces',
      'Tasks',
      'Notes',
      'Search',
      'Settings',
    ]);
    expect(find.byKey(const Key('home-placeholder-title')), findsOneWidget);
    expect(find.byType(TaskList), findsNothing);
    expect(find.byType(TaskList, skipOffstage: false), findsOneWidget);
  });

  testWidgets(
    'Home opens active Workspace, create flow, and Unassigned exactly once',
    (tester) async {
      final active = LifeOsWorkspace.createUserWorkspace(
        id: const LifeOsEntityId(
          value: 'workspace-shell',
          entityType: LifeOsEntityType.workspace,
        ),
        title: 'Personal',
        description: 'Personal context',
        timestamp: DateTime.utc(2026, 9, 22),
      );
      final deleted = LifeOsWorkspace.createUserWorkspace(
        id: const LifeOsEntityId(
          value: 'workspace-deleted',
          entityType: LifeOsEntityType.workspace,
        ),
        title: 'Deleted context',
        description: '',
        timestamp: DateTime.utc(2026, 9, 22),
      ).delete(updatedAt: DateTime.utc(2026, 9, 22, 1));
      final workspaces = ShellWorkspaceRepository([active, deleted]);

      await tester.pumpWidget(
        testApp(const Locale('en'), workspaceRepository: workspaces),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Personal context'), findsOneWidget);
      expect(find.text('Deleted context'), findsNothing);

      await tester.tap(find.byKey(const Key('home-workspace-workspace-shell')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        LifeOsDestination.workspaces.index,
      );
      expect(find.byType(WorkspacePage), findsOneWidget);
      expect(find.byKey(const Key('workspace-detail-title')), findsOneWidget);

      await tester.tap(find.byKey(const Key('navigation-home-label')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-new-workspace-action')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workspace-title-field')), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('navigation-home-label')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('navigation-workspaces-label')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('workspace-title-field')), findsNothing);

      await tester.tap(find.byKey(const Key('navigation-home-label')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('home-unassigned-action')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        LifeOsDestination.workspaces.index,
      );
      expect(find.text('Unassigned'), findsWidgets);
      expect(find.text('No unassigned Tasks or Notes'), findsOneWidget);
    },
  );

  testWidgets('opens Search and preserves its state across navigation', (
    tester,
  ) async {
    final repository = EmptyLifeOsTaskRepository(
      searchResults: [
        LifeOsTask.createUserTask(
          id: const LifeOsEntityId(
            value: 'task-search-result',
            entityType: LifeOsEntityType.task,
          ),
          title: 'Search result',
          timestamp: DateTime.utc(2026, 9, 10),
        ),
      ],
    );
    await tester.pumpWidget(
      testApp(const Locale('en'), repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('navigation-search-label')));
    await tester.pumpAndSettle();
    expect(find.byType(UnifiedSearchPage), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('search-query-field')),
      'result',
    );
    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();
    expect(find.text('Search result'), findsOneWidget);
    expect(repository.searchByTitleCallCount, 1);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('navigation-search-label')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('search-query-field')))
          .controller
          ?.text,
      'result',
    );
    expect(find.text('Search result'), findsOneWidget);
    expect(repository.searchByTitleCallCount, 1);
  });

  testWidgets('Unified Search opens Task, Note, and Workspace by typed ID', (
    tester,
  ) async {
    final task = LifeOsTask.createUserTask(
      id: const LifeOsEntityId(
        value: 'search-task',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Found Task',
      timestamp: DateTime.utc(2026, 9, 26, 10),
    );
    final note = LifeOsNote.createUserNote(
      id: const LifeOsEntityId(
        value: 'search-note',
        entityType: LifeOsEntityType.note,
      ),
      title: 'Found Note',
      content: 'Found content',
      timestamp: DateTime.utc(2026, 9, 26, 9),
    );
    final workspace = LifeOsWorkspace.createUserWorkspace(
      id: const LifeOsEntityId(
        value: 'search-workspace',
        entityType: LifeOsEntityType.workspace,
      ),
      title: 'Found Workspace',
      description: 'Found context',
      timestamp: DateTime.utc(2026, 9, 26, 8),
    );
    final reader = _FixedUnifiedSearchReader([
      LifeOsTaskSearchResult(task),
      LifeOsNoteSearchResult(note),
      LifeOsWorkspaceSearchResult(workspace),
    ]);

    await tester.pumpWidget(
      testApp(
        const Locale('en'),
        repository: EmptyLifeOsTaskRepository(tasks: [task]),
        noteRepository: EmptyLifeOsNoteRepository([note]),
        workspaceRepository: ShellWorkspaceRepository([workspace]),
        unifiedSearchReader: reader,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('navigation-search-label')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search-query-field')), 'find');
    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('search-result-task-search-task')),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      LifeOsDestination.tasks.index,
    );
    expect(find.text('Found Task'), findsOneWidget);

    await tester.tap(find.byKey(const Key('navigation-search-label')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('search-result-note-search-note')),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      LifeOsDestination.notes.index,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-title-field')))
          .controller
          ?.text,
      'Found Note',
    );

    await tester.tap(find.byKey(const Key('navigation-search-label')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('search-result-workspace-search-workspace')),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      LifeOsDestination.workspaces.index,
    );
    expect(find.byKey(const Key('workspace-detail-title')), findsOneWidget);
    expect(find.text('Found Workspace'), findsOneWidget);
  });

  testWidgets('switches between Tasks, Search, and Tasks', (tester) async {
    await tester.pumpWidget(testApp(const Locale('en')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task-title-field')), findsOneWidget);
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-query-field')), findsOneWidget);
    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task-title-field')), findsOneWidget);
  });

  testWidgets('switches shell-local destination state and keeps Task content', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const Locale('en')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      LifeOsDestination.home.index,
    );
    expect(find.byKey(const Key('home-placeholder-title')), findsOneWidget);
    expect(find.byKey(const Key('home-alpha-description')), findsOneWidget);
    expect(
      find.text(
        'Organize Tasks and Notes around the life contexts that matter to you.',
      ),
      findsOneWidget,
    );
    expect(find.byType(TaskList), findsNothing);
    expect(find.byType(TaskList, skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      LifeOsDestination.tasks.index,
    );
    expect(find.byKey(const Key('task-title-field')), findsOneWidget);
  });

  testWidgets('preserves Task draft and provider state across navigation', (
    tester,
  ) async {
    final repository = EmptyLifeOsTaskRepository();

    await tester.pumpWidget(
      testApp(const Locale('en'), repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Unsubmitted draft',
    );
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(repository.getAllCallCount, 1);
    expect(
      find.byKey(const Key('task-title-field'), skipOffstage: false),
      findsOneWidget,
    );

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    final titleField = tester.widget<TextField>(
      find.byKey(const Key('task-title-field')),
    );
    expect(titleField.controller?.text, 'Unsubmitted draft');
    expect(repository.getAllCallCount, 1);
  });

  testWidgets('opens Notes and preserves its editor state in IndexedStack', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const Locale('en')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      'Unsaved Note',
    );
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Save changes to this Note?'), findsNothing);
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-title-field')))
          .controller
          ?.text,
      'Unsaved Note',
    );
    expect(find.byKey(const Key('note-unsaved-indicator')), findsOneWidget);
  });

  testWidgets('localizes shell navigation labels in Russian', (tester) async {
    await tester.pumpWidget(testApp(const Locale('ru')));
    await tester.pumpAndSettle();

    final navigationRail = tester.widget<NavigationRail>(
      find.byType(NavigationRail),
    );

    expect(destinationLabels(navigationRail), [
      'Главная',
      'Пространства',
      'Задачи',
      'Заметки',
      'Поиск',
      'Настройки',
    ]);
  });

  testWidgets('Home quick actions navigate and initiate Task and Note flows', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const Locale('en')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Other actions'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-new-task-action')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      LifeOsDestination.tasks.index,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('task-title-field')))
          .focusNode
          ?.hasFocus,
      isTrue,
    );

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-new-note-action')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      LifeOsDestination.notes.index,
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-title-field')))
          .focusNode
          ?.hasFocus,
      isTrue,
    );

    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      'One-shot draft',
    );
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-title-field')))
          .controller
          ?.text,
      'One-shot draft',
    );
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Home New Note preserves dirty drafts through every guard path', (
    tester,
  ) async {
    final notes = EmptyLifeOsNoteRepository();
    await tester.pumpWidget(testApp(const Locale('en'), noteRepository: notes));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      'Protected draft',
    );
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-new-note-action')));
    await tester.pumpAndSettle();
    expect(find.text('Save changes to this Note?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-title-field')))
          .controller
          ?.text,
      'Protected draft',
    );

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-new-note-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-title-field')))
          .controller
          ?.text,
      isEmpty,
    );

    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      'Saved before New',
    );
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-new-note-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-save')));
    await tester.pumpAndSettle();
    expect(notes.notes.single.title, 'Saved before New');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-title-field')))
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('Home Search and Settings actions support keyboard activation', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const Locale('en')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    final newTaskAction = find.byKey(const Key('home-new-task-action'));
    final newTaskButton = tester.widget<FilledButton>(
      find
          .descendant(of: newTaskAction, matching: find.byType(FilledButton))
          .first,
    );
    newTaskButton.focusNode!.requestFocus();
    await tester.pump();
    expect(newTaskButton.focusNode!.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task-title-field')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('task-title-field')))
          .focusNode
          ?.hasFocus,
      isTrue,
    );

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-search-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-query-field')), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-settings-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('backup-settings-page')), findsOneWidget);
  });

  testWidgets('Home quick actions localize without overflow at 640x600', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(640, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testApp(const Locale('ru')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Главная'));
    await tester.pumpAndSettle();

    expect(find.text('Другие действия'), findsOneWidget);
    expect(find.text('Новая задача'), findsOneWidget);
    expect(find.text('Новая заметка'), findsOneWidget);
    expect(find.text('Поиск'), findsWidgets);
    expect(find.text('Настройки / резервная копия'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps Task selection local and inactive destinations inert', (
    tester,
  ) async {
    final task = LifeOsTask.createUserTask(
      id: const LifeOsEntityId(
        value: 'selected-task',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Selected Task',
      timestamp: DateTime.utc(2026, 9, 13),
    );
    final repository = EmptyLifeOsTaskRepository(tasks: [task]);
    await tester.pumpWidget(
      testApp(const Locale('en'), repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Selected Task'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ExpansionTile>(
            find.byKey(const ValueKey('task-selected-task')),
          )
          .collapsedBackgroundColor,
      isNotNull,
    );

    for (final destination in [
      const Key('navigation-home-label'),
      const Key('navigation-search-label'),
      const Key('navigation-settings-label'),
    ]) {
      await tester.tap(find.byKey(destination));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(repository.saveCallCount, 0);
    }

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ExpansionTile>(
            find.byKey(const ValueKey('task-selected-task')),
          )
          .collapsedBackgroundColor,
      isNotNull,
    );
  });

  testWidgets(
    'typed openTask selects an active target, reveals it, and consumes once',
    (tester) async {
      final openTask = LifeOsTask.createUserTask(
        id: const LifeOsEntityId(
          value: 'task-open',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Open Task',
        timestamp: DateTime.utc(2026, 9, 10),
      );
      final completedTask = LifeOsTask.createUserTask(
        id: const LifeOsEntityId(
          value: 'task-completed',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Completed Target',
        timestamp: DateTime.utc(2026, 9, 10),
      ).toggleCompletion(updatedAt: DateTime.utc(2026, 9, 25, 1));
      final deletedTask = LifeOsTask.createUserTask(
        id: const LifeOsEntityId(
          value: 'task-deleted',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Deleted Target',
        timestamp: DateTime.utc(2026, 9, 10),
      ).delete(updatedAt: DateTime.utc(2026, 9, 10, 1));
      final archivedTask = LifeOsTask.createUserTask(
        id: const LifeOsEntityId(
          value: 'task-archived',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Archived Target',
        timestamp: DateTime.utc(2026, 9, 10),
      ).archive(updatedAt: DateTime.utc(2026, 9, 10, 1));
      final shellKey = GlobalKey<LifeosShellPageState>();
      final repository = EmptyLifeOsTaskRepository(
        tasks: [openTask, completedTask, deletedTask, archivedTask],
      );
      await tester.pumpWidget(
        testApp(const Locale('en'), repository: repository, shellKey: shellKey),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('navigation-tasks-label')));
      await tester.pumpAndSettle();
      final filter = tester.widget<SegmentedButton<TaskCompletionFilter>>(
        find.byKey(const Key('task-completion-filter')),
      );
      filter.onSelectionChanged!({TaskCompletionFilter.open});
      await tester.pumpAndSettle();
      expect(find.text('Completed Target'), findsNothing);

      shellKey.currentState!.openTask(completedTask.id);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        LifeOsDestination.tasks.index,
      );
      expect(find.text('Completed Target'), findsOneWidget);
      expect(
        tester
            .widget<ExpansionTile>(
              find.byKey(const ValueKey('task-task-completed')),
            )
            .collapsedBackgroundColor,
        isNotNull,
      );
      expect(
        tester
            .widget<SegmentedButton<TaskCompletionFilter>>(
              find.byKey(const Key('task-completion-filter')),
            )
            .selected,
        {TaskCompletionFilter.all},
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('navigation-home-label')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('navigation-tasks-label')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ExpansionTile>(
              find.byKey(const ValueKey('task-task-completed')),
            )
            .collapsedBackgroundColor,
        isNull,
      );

      shellKey.currentState!.openTask(deletedTask.id);
      await tester.pumpAndSettle();
      expect(find.text('Deleted Target'), findsNothing);
      expect(tester.takeException(), isNull);

      shellKey.currentState!.openTask(archivedTask.id);
      await tester.pumpAndSettle();
      expect(find.text('Archived Target'), findsNothing);
      expect(tester.takeException(), isNull);

      shellKey.currentState!.openTask(
        const LifeOsEntityId(
          value: 'task-missing',
          entityType: LifeOsEntityType.task,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'typed openNote preserves dirty drafts through Save, Discard, and Cancel',
    (tester) async {
      final first = LifeOsNote.createUserNote(
        id: const LifeOsEntityId(
          value: 'note-first',
          entityType: LifeOsEntityType.note,
        ),
        title: 'First Note',
        content: 'First body',
        timestamp: DateTime.utc(2026, 9, 10),
      );
      final second = LifeOsNote.createUserNote(
        id: const LifeOsEntityId(
          value: 'note-second',
          entityType: LifeOsEntityType.note,
        ),
        title: 'Second Note',
        content: 'Second body',
        timestamp: DateTime.utc(2026, 9, 10),
      );
      final deleted = LifeOsNote.createUserNote(
        id: const LifeOsEntityId(
          value: 'note-deleted',
          entityType: LifeOsEntityType.note,
        ),
        title: 'Deleted Note',
        content: 'Deleted body',
        timestamp: DateTime.utc(2026, 9, 10),
      ).delete(updatedAt: DateTime.utc(2026, 9, 10, 1));
      final archived = LifeOsNote.createUserNote(
        id: const LifeOsEntityId(
          value: 'note-archived',
          entityType: LifeOsEntityType.note,
        ),
        title: 'Archived Note',
        content: 'Archived body',
        timestamp: DateTime.utc(2026, 9, 10),
      ).archive(updatedAt: DateTime.utc(2026, 9, 10, 1));
      final notes = EmptyLifeOsNoteRepository([
        first,
        second,
        deleted,
        archived,
      ]);
      final shellKey = GlobalKey<LifeosShellPageState>();
      await tester.pumpWidget(
        testApp(const Locale('en'), noteRepository: notes, shellKey: shellKey),
      );
      await tester.pumpAndSettle();

      shellKey.currentState!.openNote(first.id);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-title-field')))
            .controller
            ?.text,
        'First Note',
      );

      await tester.enterText(
        find.byKey(const Key('note-content-field')),
        'Protected draft',
      );
      shellKey.currentState!.openNote(second.id);
      await tester.pumpAndSettle();
      expect(find.text('Save changes to this Note?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-content-field')))
            .controller
            ?.text,
        'Protected draft',
      );
      await tester.tap(find.byKey(const Key('navigation-home-label')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('navigation-notes-label')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-content-field')))
            .controller
            ?.text,
        'Protected draft',
      );

      shellKey.currentState!.openNote(second.id);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-title-field')))
            .controller
            ?.text,
        'Second Note',
      );

      await tester.enterText(
        find.byKey(const Key('note-content-field')),
        'Saved second body',
      );
      shellKey.currentState!.openNote(first.id);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unsaved-note-save')));
      await tester.pumpAndSettle();
      expect(
        notes.notes.singleWhere((note) => note.id == second.id).content,
        'Saved second body',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-title-field')))
            .controller
            ?.text,
        'First Note',
      );

      await tester.enterText(
        find.byKey(const Key('note-content-field')),
        'Still protected',
      );
      shellKey.currentState!.openNote(deleted.id);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-content-field')))
            .controller
            ?.text,
        'Still protected',
      );
      shellKey.currentState!.openNote(archived.id);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-content-field')))
            .controller
            ?.text,
        'Still protected',
      );
      shellKey.currentState!.openNote(
        const LifeOsEntityId(
          value: 'note-missing',
          entityType: LifeOsEntityType.note,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Related Task rows navigate to typed Task and Note targets', (
    tester,
  ) async {
    final source = _shellTask('related-source', 'Source Task');
    final taskTarget = _shellTask('related-task', 'Related Task');
    final noteTarget = _shellNote('related-note', 'Related Note', 'Body');
    final taskRelationship = _shellRelationship(
      'relationship-task',
      source.id,
      taskTarget.id,
    );
    final noteRelationship = _shellRelationship(
      'relationship-note',
      source.id,
      noteTarget.id,
    );
    final reader = ShellRelatedEntityReader({
      source.id: [
        LifeOsRelatedTaskNeighbor(
          sourceId: source.id,
          relationship: taskRelationship,
          task: taskTarget,
        ),
        LifeOsRelatedNoteNeighbor(
          sourceId: source.id,
          relationship: noteRelationship,
          note: noteTarget,
        ),
      ],
    });
    final shellKey = GlobalKey<LifeosShellPageState>();
    await tester.pumpWidget(
      testApp(
        const Locale('en'),
        repository: EmptyLifeOsTaskRepository(tasks: [source, taskTarget]),
        noteRepository: EmptyLifeOsNoteRepository([noteTarget]),
        shellKey: shellKey,
        relatedReader: reader,
      ),
    );
    await tester.pumpAndSettle();

    shellKey.currentState!.openTask(source.id);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-related-source')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Task: Related Task'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(ListView).hitTestable().first,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ExpansionTile>(
            find.byKey(const ValueKey('task-related-task')),
          )
          .collapsedBackgroundColor,
      isNotNull,
    );

    shellKey.currentState!.openTask(source.id);
    await tester.pumpAndSettle();
    if (find.text('Note: Related Note').evaluate().isEmpty) {
      await tester.tap(find.byKey(const ValueKey('task-related-source')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Note: Related Note'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-title-field')))
          .controller
          ?.text,
      'Related Note',
    );
  });

  testWidgets('Related Note navigation preserves every dirty-draft decision', (
    tester,
  ) async {
    final source = _shellNote('note-source', 'Source Note', 'Original');
    final noteTarget = _shellNote('note-target', 'Target Note', 'Target');
    final taskTarget = _shellTask('task-target', 'Target Task');
    final noteRelationship = _shellRelationship(
      'relationship-note-target',
      source.id,
      noteTarget.id,
    );
    final taskRelationship = _shellRelationship(
      'relationship-task-target',
      source.id,
      taskTarget.id,
    );
    final reader = ShellRelatedEntityReader({
      source.id: [
        LifeOsRelatedNoteNeighbor(
          sourceId: source.id,
          relationship: noteRelationship,
          note: noteTarget,
        ),
        LifeOsRelatedTaskNeighbor(
          sourceId: source.id,
          relationship: taskRelationship,
          task: taskTarget,
        ),
      ],
    });
    final notes = EmptyLifeOsNoteRepository([source, noteTarget]);
    final shellKey = GlobalKey<LifeosShellPageState>();
    await tester.pumpWidget(
      testApp(
        const Locale('en'),
        repository: EmptyLifeOsTaskRepository(tasks: [taskTarget]),
        noteRepository: notes,
        shellKey: shellKey,
        relatedReader: reader,
      ),
    );
    await tester.pumpAndSettle();

    Future<void> openSource() async {
      shellKey.currentState!.openNote(source.id);
      await tester.pumpAndSettle();
    }

    await openSource();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Save this',
    );
    await tester.tap(
      find.byKey(const ValueKey('open-related-relationship-note-target')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-save')));
    await tester.pumpAndSettle();
    expect(
      notes.notes.singleWhere((note) => note.id == source.id).content,
      'Save this',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-title-field')))
          .controller
          ?.text,
      'Target Note',
    );

    await openSource();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Discard this',
    );
    await tester.tap(
      find.byKey(const ValueKey('open-related-relationship-note-target')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-discard')));
    await tester.pumpAndSettle();
    expect(
      notes.notes.singleWhere((note) => note.id == source.id).content,
      'Save this',
    );

    await openSource();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Keep this draft',
    );
    await tester.tap(
      find.byKey(const ValueKey('open-related-relationship-note-target')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-cancel')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-content-field')))
          .controller
          ?.text,
      'Keep this draft',
    );
    await tester.tap(find.byKey(const Key('navigation-home-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('navigation-notes-label')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      LifeOsDestination.notes.index,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-content-field')))
          .controller
          ?.text,
      'Keep this draft',
    );

    final relatedTask = find.text('Task: Target Task');
    await tester.ensureVisible(relatedTask);
    await tester.pumpAndSettle();
    await tester.tap(relatedTask);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.byKey(const Key('unsaved-note-discard')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      LifeOsDestination.tasks.index,
    );
    expect(
      tester
          .widget<ExpansionTile>(find.byKey(const ValueKey('task-task-target')))
          .collapsedBackgroundColor,
      isNotNull,
    );
  });
}

LifeOsTask _shellTask(String id, String title) => LifeOsTask.createUserTask(
  id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.task),
  title: title,
  timestamp: DateTime.utc(2026, 9, 10),
);

LifeOsNote _shellNote(String id, String title, String content) =>
    LifeOsNote.createUserNote(
      id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.note),
      title: title,
      content: content,
      timestamp: DateTime.utc(2026, 9, 10),
    );

LifeOsRelationship _shellRelationship(
  String id,
  LifeOsEntityId first,
  LifeOsEntityId second,
) => LifeOsRelationship.createUserRelationship(
  id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.relationship),
  firstEndpoint: first,
  secondEndpoint: second,
  timestamp: DateTime.utc(2026, 9, 10),
);

List<String> destinationLabels(NavigationRail navigationRail) {
  return [
    for (final destination in navigationRail.destinations)
      (destination.label as Text).data!,
  ];
}

Widget testApp(
  Locale locale, {
  EmptyLifeOsTaskRepository? repository,
  EmptyLifeOsNoteRepository? noteRepository,
  ShellWorkspaceRepository? workspaceRepository,
  GlobalKey<LifeosShellPageState>? shellKey,
  LifeOsRelatedEntityReader? relatedReader,
  LifeOsUnifiedSearchReader? unifiedSearchReader,
}) {
  final taskRepository = repository ?? EmptyLifeOsTaskRepository();
  final notes = noteRepository ?? EmptyLifeOsNoteRepository();
  final workspaces = workspaceRepository ?? ShellWorkspaceRepository();
  final workspaceContext = EmptyWorkspaceContextReader();

  return ProviderScope(
    overrides: [
      lifeOsTaskRepositoryProvider.overrideWithValue(taskRepository),
      lifeOsNoteRepositoryProvider.overrideWithValue(notes),
      getDirectLifeOsRelatedNeighborsProvider.overrideWithValue(
        GetDirectLifeOsRelatedNeighbors(
          relatedReader ?? const EmptyRelatedEntityReader(),
        ),
      ),
      createLifeOsNoteProvider.overrideWithValue(
        CreateLifeOsNote(
          repository: notes,
          entityIdGenerator: () => 'note-test',
          utcClock: () => DateTime.utc(2026, 9, 12),
        ),
      ),
      editLifeOsNoteProvider.overrideWithValue(
        EditLifeOsNote(
          repository: notes,
          utcClock: () => DateTime.utc(2026, 9, 12, 1),
        ),
      ),
      searchLifeOsEntitiesProvider.overrideWithValue(
        SearchLifeOsEntities(
          unifiedSearchReader ??
              _TaskRepositoryUnifiedSearchReader(taskRepository),
        ),
      ),
      getLifeOsWorkspacesProvider.overrideWithValue(
        GetLifeOsWorkspaces(workspaces),
      ),
      getDeletedLifeOsWorkspacesProvider.overrideWithValue(
        GetDeletedLifeOsWorkspaces(workspaces),
      ),
      getLifeOsWorkspaceMembersProvider.overrideWithValue(
        GetLifeOsWorkspaceMembers(workspaceContext),
      ),
      getUnassignedLifeOsWorkspaceMembersProvider.overrideWithValue(
        GetUnassignedLifeOsWorkspaceMembers(workspaceContext),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LifeosShellPage(key: shellKey),
    ),
  );
}

class EmptyRelatedEntityReader implements LifeOsRelatedEntityReader {
  const EmptyRelatedEntityReader();

  @override
  Future<List<LifeOsRelatedNeighbor>> getDirectNeighbors({
    required LifeOsEntityId sourceId,
    required int limit,
  }) async => const [];
}

class _TaskRepositoryUnifiedSearchReader implements LifeOsUnifiedSearchReader {
  const _TaskRepositoryUnifiedSearchReader(this.repository);

  final LifeOsTaskRepository repository;

  @override
  Future<List<LifeOsSearchResult>> search({
    required String query,
    required int limit,
  }) async {
    final tasks = await repository.searchByTitle(query);
    return tasks.take(limit).map(LifeOsTaskSearchResult.new).toList();
  }
}

class _FixedUnifiedSearchReader implements LifeOsUnifiedSearchReader {
  const _FixedUnifiedSearchReader(this.results);

  final List<LifeOsSearchResult> results;

  @override
  Future<List<LifeOsSearchResult>> search({
    required String query,
    required int limit,
  }) async => results.take(limit).toList();
}

class ShellRelatedEntityReader implements LifeOsRelatedEntityReader {
  ShellRelatedEntityReader(this.neighbors);

  final Map<LifeOsEntityId, List<LifeOsRelatedNeighbor>> neighbors;

  @override
  Future<List<LifeOsRelatedNeighbor>> getDirectNeighbors({
    required LifeOsEntityId sourceId,
    required int limit,
  }) async => (neighbors[sourceId] ?? const []).take(limit).toList();
}

class ShellWorkspaceRepository implements LifeOsWorkspaceRepository {
  ShellWorkspaceRepository([Iterable<LifeOsWorkspace> values = const []])
    : values = List.of(values);

  final List<LifeOsWorkspace> values;

  @override
  Future<List<LifeOsWorkspace>> getAll() async => List.of(values);

  @override
  Future<LifeOsWorkspace?> getById(LifeOsEntityId id) async =>
      values.where((workspace) => workspace.id == id).firstOrNull;

  @override
  Future<List<LifeOsWorkspace>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async =>
      values.where((workspace) => workspace.lifecycle == lifecycle).toList();

  @override
  Future<void> save(LifeOsWorkspace workspace) async {
    values.removeWhere((item) => item.id == workspace.id);
    values.add(workspace);
  }
}

class EmptyWorkspaceContextReader implements LifeOsWorkspaceContextReader {
  @override
  Future<List<LifeOsWorkspaceMember>> getDirectMembers(
    LifeOsEntityId workspaceId,
  ) async => const [];

  @override
  Future<List<LifeOsWorkspaceMember>> getUnassigned() async => const [];
}

class EmptyLifeOsNoteRepository implements LifeOsNoteRepository {
  EmptyLifeOsNoteRepository([Iterable<LifeOsNote> values = const []]) {
    notes.addAll(values);
  }

  final List<LifeOsNote> notes = [];

  @override
  Future<List<LifeOsNote>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async => notes.where((note) => note.lifecycle == lifecycle).toList();

  @override
  Future<List<LifeOsNote>> getAll() async => List.of(notes);

  @override
  Future<LifeOsNote?> getById(LifeOsEntityId id) async =>
      notes.where((note) => note.id == id).firstOrNull;

  @override
  Future<void> save(LifeOsNote note) async {
    notes.removeWhere((item) => item.id == note.id);
    notes.add(note);
  }
}

class EmptyLifeOsTaskRepository implements LifeOsTaskRepository {
  EmptyLifeOsTaskRepository({
    this.searchResults = const [],
    this.tasks = const [],
  });

  final List<LifeOsTask> searchResults;
  final List<LifeOsTask> tasks;
  int getAllCallCount = 0;
  int searchByTitleCallCount = 0;
  int saveCallCount = 0;

  @override
  Future<List<LifeOsTask>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async {
    getAllCallCount += 1;
    return tasks.where((task) => task.lifecycle == lifecycle).toList();
  }

  @override
  Future<List<LifeOsTask>> getAll() async {
    return List.of(tasks);
  }

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async =>
      tasks.where((task) => task.id == id).firstOrNull;

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async {
    searchByTitleCallCount += 1;
    return searchResults;
  }

  @override
  Future<void> save(LifeOsTask task) async {
    saveCallCount += 1;
  }
}
