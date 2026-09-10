import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/create_lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';
import 'package:lifeos/presentation/tasks/task_list.dart';
import 'package:lifeos/presentation/tasks/task_list_providers.dart';

void main() {
  testWidgets('renders loading and empty Task states', (tester) async {
    final pendingTasks = Completer<List<LifeOsTask>>();
    final repository = FakeLifeOsTaskRepository(() => pendingTasks.future);

    await tester.pumpWidget(testApp(repository));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pendingTasks.complete([]);
    await tester.pumpAndSettle();

    expect(find.text('No Tasks yet'), findsOneWidget);
  });

  testWidgets('renders persisted Tasks', (tester) async {
    final repository = FakeLifeOsTaskRepository(
      () async => [
        createTask('task-1', 'Plan the day', isCompleted: false),
        createTask('task-2', 'Review progress', isCompleted: true),
      ],
    );

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Plan the day'), findsOneWidget);
    expect(find.text('Review progress'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('renders a bounded Task loading error', (tester) async {
    final repository = FakeLifeOsTaskRepository(
      () => Future.error(StateError('database details')),
    );

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load Tasks'), findsOneWidget);
    expect(find.textContaining('database details'), findsNothing);
  });

  testWidgets('creates a Task and adds the persisted result to the list', (
    tester,
  ) async {
    final repository = FakeLifeOsTaskRepository(() async => []);

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Create through the UI',
    );
    await tester.tap(find.byKey(const Key('create-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Create through the UI'), findsOneWidget);
    expect(repository.savedTasks, hasLength(1));
    expect(repository.savedTasks.single.id.value, 'task-created');
    expect(repository.savedTasks.single.createdAt.isUtc, isTrue);
    expect(
      repository.savedTasks.single.updatedAt,
      DateTime.utc(2026, 9, 9, 16),
    );
  });

  testWidgets('toggles persisted completion from the Task list', (
    tester,
  ) async {
    final task = createTask(
      'task-1',
      'Toggle from the list',
      isCompleted: false,
    );
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
    );

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mark complete'));
    await tester.pumpAndSettle();

    expect(repository.savedTasks.last.isCompleted, isTrue);
    expect(find.byTooltip('Mark incomplete'), findsOneWidget);

    await tester.tap(find.byTooltip('Mark incomplete'));
    await tester.pumpAndSettle();

    expect(repository.savedTasks.last.isCompleted, isFalse);
    expect(find.byTooltip('Mark complete'), findsOneWidget);
  });
}

Widget testApp(LifeOsTaskRepository repository) {
  final createTask = CreateLifeOsTask(
    repository: repository,
    entityIdGenerator: () => 'task-created',
    utcClock: () => DateTime.utc(2026, 9, 9, 16),
  );

  return ProviderScope(
    overrides: [
      lifeOsTaskRepositoryProvider.overrideWithValue(repository),
      createLifeOsTaskProvider.overrideWithValue(createTask),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: TaskList()),
    ),
  );
}

LifeOsTask createTask(String id, String title, {required bool isCompleted}) {
  return LifeOsTask(
    id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.task),
    title: title,
    isCompleted: isCompleted,
    createdAt: DateTime.utc(2026, 9, 9, 10),
    updatedAt: DateTime.utc(2026, 9, 9, 10),
    lifecycle: LifeOsEntityLifecycle.active,
    version: 1,
    source: LifeOsEntitySource.user,
  );
}

class FakeLifeOsTaskRepository implements LifeOsTaskRepository {
  FakeLifeOsTaskRepository(this._loadTasks, {this.storedTask});

  final Future<List<LifeOsTask>> Function() _loadTasks;
  LifeOsTask? storedTask;
  final List<LifeOsTask> savedTasks = [];

  @override
  Future<List<LifeOsTask>> getAll() => _loadTasks();

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async {
    return storedTask?.id == id ? storedTask : null;
  }

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async => [];

  @override
  Future<void> save(LifeOsTask task) async {
    storedTask = task;
    savedTasks.add(task);
  }
}
