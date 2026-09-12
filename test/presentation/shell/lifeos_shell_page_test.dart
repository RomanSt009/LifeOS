import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/search_lifeos_tasks.dart';
import 'package:lifeos/application/use_cases/create_lifeos_note.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_note_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/navigation/lifeos_destination.dart';
import 'package:lifeos/presentation/notes/note_providers.dart';
import 'package:lifeos/presentation/shell/lifeos_shell_page.dart';
import 'package:lifeos/presentation/search/task_search_page.dart';
import 'package:lifeos/presentation/search/task_search_providers.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';
import 'package:lifeos/presentation/tasks/task_list.dart';

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

      final searchLabel = scenario.locale.languageCode == 'ru'
          ? 'Поиск'
          : 'Search';
      await tester.tap(find.text(searchLabel));
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

      final settingsLabel = scenario.locale.languageCode == 'ru'
          ? 'Настройки'
          : 'Settings';
      await tester.tap(find.text(settingsLabel));
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
      LifeOsDestination.tasks,
      LifeOsDestination.notes,
      LifeOsDestination.search,
      LifeOsDestination.settings,
    ]);
    expect(navigationRail.destinations, hasLength(5));
    expect(destinationLabels(navigationRail), [
      'Home',
      'Tasks',
      'Notes',
      'Search',
      'Settings',
    ]);
  });

  testWidgets('shows a persistent desktop frame with Tasks selected', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const Locale('en')));
    await tester.pumpAndSettle();

    final navigationRail = tester.widget<NavigationRail>(
      find.byType(NavigationRail),
    );

    expect(navigationRail.selectedIndex, LifeOsDestination.tasks.index);
    expect(navigationRail.labelType, NavigationRailLabelType.all);
    expect(destinationLabels(navigationRail), [
      'Home',
      'Tasks',
      'Notes',
      'Search',
      'Settings',
    ]);
    expect(find.byType(TaskList), findsOneWidget);
    expect(find.byKey(const Key('task-title-field')), findsOneWidget);
  });

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
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskSearchPage), findsOneWidget);

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
    await tester.tap(find.text('Search'));
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

  testWidgets('switches between Tasks, Search, and Tasks', (tester) async {
    await tester.pumpWidget(testApp(const Locale('en')));
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
    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-title-field')))
          .controller
          ?.text,
      'Unsaved Note',
    );
  });

  testWidgets('localizes shell navigation labels in Russian', (tester) async {
    await tester.pumpWidget(testApp(const Locale('ru')));
    await tester.pumpAndSettle();

    final navigationRail = tester.widget<NavigationRail>(
      find.byType(NavigationRail),
    );

    expect(destinationLabels(navigationRail), [
      'Главная',
      'Задачи',
      'Заметки',
      'Поиск',
      'Настройки',
    ]);
  });
}

List<String> destinationLabels(NavigationRail navigationRail) {
  return [
    for (final destination in navigationRail.destinations)
      (destination.label as Text).data!,
  ];
}

Widget testApp(Locale locale, {EmptyLifeOsTaskRepository? repository}) {
  final taskRepository = repository ?? EmptyLifeOsTaskRepository();
  final noteRepository = EmptyLifeOsNoteRepository();

  return ProviderScope(
    overrides: [
      lifeOsTaskRepositoryProvider.overrideWithValue(taskRepository),
      lifeOsNoteRepositoryProvider.overrideWithValue(noteRepository),
      createLifeOsNoteProvider.overrideWithValue(
        CreateLifeOsNote(
          repository: noteRepository,
          entityIdGenerator: () => 'note-test',
          utcClock: () => DateTime.utc(2026, 9, 12),
        ),
      ),
      editLifeOsNoteProvider.overrideWithValue(
        EditLifeOsNote(
          repository: noteRepository,
          utcClock: () => DateTime.utc(2026, 9, 12, 1),
        ),
      ),
      searchLifeOsTasksProvider.overrideWithValue(
        SearchLifeOsTasks(taskRepository),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LifeosShellPage(),
    ),
  );
}

class EmptyLifeOsNoteRepository implements LifeOsNoteRepository {
  @override
  Future<List<LifeOsNote>> getAll() async => [];

  @override
  Future<LifeOsNote?> getById(LifeOsEntityId id) async => null;

  @override
  Future<void> save(LifeOsNote note) async {}
}

class EmptyLifeOsTaskRepository implements LifeOsTaskRepository {
  EmptyLifeOsTaskRepository({this.searchResults = const []});

  final List<LifeOsTask> searchResults;
  int getAllCallCount = 0;
  int searchByTitleCallCount = 0;

  @override
  Future<List<LifeOsTask>> getAll() async {
    getAllCallCount += 1;
    return [];
  }

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async => null;

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async {
    searchByTitleCallCount += 1;
    return searchResults;
  }

  @override
  Future<void> save(LifeOsTask task) async {}
}
