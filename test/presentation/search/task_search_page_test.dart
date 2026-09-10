import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/search_lifeos_tasks.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/search/task_search_page.dart';
import 'package:lifeos/presentation/search/task_search_providers.dart';

void main() {
  testWidgets('shows the localized initial state without searching', (
    tester,
  ) async {
    final repository = StubLifeOsTaskRepository();

    await tester.pumpWidget(searchTestApp(repository));

    expect(find.text('Search'), findsNWidgets(2));
    expect(find.text('Task title'), findsOneWidget);
    expect(find.text('Enter a Task title to search'), findsOneWidget);
    expect(repository.queries, isEmpty);
  });

  testWidgets('passes input through Application and displays ordered Tasks', (
    tester,
  ) async {
    final completedTask = task(
      id: 'task-completed',
      title: 'Completed Task',
      isCompleted: true,
    );
    final activeTask = task(
      id: 'task-active',
      title: 'Active Task',
      isCompleted: false,
    );
    final repository = StubLifeOsTaskRepository(
      results: [completedTask, activeTask],
    );
    await tester.pumpWidget(searchTestApp(repository));

    await tester.enterText(
      find.byKey(const Key('search-query-field')),
      '  Task  ',
    );
    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();

    expect(repository.queries, ['Task']);
    expect(find.text('Completed Task'), findsOneWidget);
    expect(find.text('Active Task'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Completed Task')).dy,
      lessThan(tester.getTopLeft(find.text('Active Task')).dy),
    );
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Completed Task')).style?.decoration,
      TextDecoration.lineThrough,
    );
    expect(tester.widget<Text>(find.text('Active Task')).style, isNull);
  });

  testWidgets('shows no-results state for an unmatched query', (tester) async {
    final repository = StubLifeOsTaskRepository();
    await tester.pumpWidget(searchTestApp(repository));

    await tester.enterText(
      find.byKey(const Key('search-query-field')),
      'missing',
    );
    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();

    expect(repository.queries, ['missing']);
    expect(find.text('No Tasks found'), findsOneWidget);
    expect(find.text('Enter a Task title to search'), findsNothing);
  });

  testWidgets('uses Application empty-query behavior for whitespace input', (
    tester,
  ) async {
    final repository = StubLifeOsTaskRepository(
      results: [task(id: 'task-1', title: 'Must not appear')],
    );
    await tester.pumpWidget(searchTestApp(repository));

    await tester.enterText(
      find.byKey(const Key('search-query-field')),
      '   ',
    );
    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();

    expect(repository.queries, isEmpty);
    expect(find.text('No Tasks found'), findsOneWidget);
    expect(find.text('Must not appear'), findsNothing);
  });

  testWidgets('shows a localized error without exposing Infrastructure', (
    tester,
  ) async {
    final repository = StubLifeOsTaskRepository(shouldFail: true);
    await tester.pumpWidget(searchTestApp(repository));

    await tester.enterText(
      find.byKey(const Key('search-query-field')),
      'failure',
    );
    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Unable to search Tasks'), findsOneWidget);
    expect(find.textContaining('repository failure'), findsNothing);
  });

  testWidgets('localizes the Search Presentation in Russian', (tester) async {
    final repository = StubLifeOsTaskRepository();
    await tester.pumpWidget(
      searchTestApp(repository, locale: const Locale('ru')),
    );

    expect(find.text('Поиск'), findsOneWidget);
    expect(find.text('Найти'), findsOneWidget);
    expect(find.text('Название задачи'), findsOneWidget);
    expect(find.text('Введите название задачи для поиска'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('search-query-field')),
      'нет результата',
    );
    await tester.tap(find.byKey(const Key('search-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Задачи не найдены'), findsOneWidget);
  });
}

Widget searchTestApp(
  StubLifeOsTaskRepository repository, {
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      searchLifeOsTasksProvider.overrideWithValue(SearchLifeOsTasks(repository)),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: TaskSearchPage()),
    ),
  );
}

LifeOsTask task({
  required String id,
  required String title,
  bool isCompleted = false,
}) {
  return LifeOsTask(
    id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.task),
    title: title,
    isCompleted: isCompleted,
    createdAt: DateTime.utc(2026, 9, 10, 10),
    updatedAt: DateTime.utc(2026, 9, 10, 11),
    lifecycle: LifeOsEntityLifecycle.active,
    version: 1,
    source: LifeOsEntitySource.user,
  );
}

class StubLifeOsTaskRepository implements LifeOsTaskRepository {
  StubLifeOsTaskRepository({
    this.results = const [],
    this.shouldFail = false,
  });

  final List<LifeOsTask> results;
  final bool shouldFail;
  final List<String> queries = [];

  @override
  Future<List<LifeOsTask>> getAll() async => [];

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async => null;

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async {
    queries.add(query);
    if (shouldFail) {
      throw StateError('repository failure with private content');
    }
    return results;
  }

  @override
  Future<void> save(LifeOsTask task) async {}
}
