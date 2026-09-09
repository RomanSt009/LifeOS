import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';
import 'package:lifeos/presentation/tasks/task_list.dart';

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
}

Widget testApp(LifeOsTaskRepository repository) {
  return ProviderScope(
    overrides: [lifeOsTaskRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: Scaffold(body: TaskList())),
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
  FakeLifeOsTaskRepository(this._loadTasks);

  final Future<List<LifeOsTask>> Function() _loadTasks;

  @override
  Future<List<LifeOsTask>> getAll() => _loadTasks();

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async => null;

  @override
  Future<void> save(LifeOsTask task) async {}
}
