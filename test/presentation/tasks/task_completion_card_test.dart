import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/toggle_stored_task_completion.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/tasks/task_completion_card.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';

void main() {
  testWidgets('toggles Task completion through the Application use case', (
    tester,
  ) async {
    final task = LifeOsTask(
      id: const LifeOsEntityId(
        value: 'task-1',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Verify the Riverpod boundary',
      isCompleted: false,
      createdAt: DateTime.utc(2026, 9, 6, 10),
      updatedAt: DateTime.utc(2026, 9, 6, 10),
      lifecycle: LifeOsEntityLifecycle.active,
      version: 1,
      source: LifeOsEntitySource.user,
    );
    final repository = FakeLifeOsTaskRepository(task);
    final applicationAction = ToggleStoredTaskCompletion(
      repository: repository,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          displayedTaskProvider.overrideWithValue(task),
          toggleStoredTaskCompletionProvider.overrideWithValue(
            applicationAction,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TaskCompletionCard()),
        ),
      ),
    );

    expect(find.text('Verify the Riverpod boundary'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(repository.savedTasks, hasLength(1));
    expect(repository.savedTasks.single.isCompleted, isTrue);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(repository.savedTasks, hasLength(2));
    expect(repository.savedTasks.last.isCompleted, isFalse);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });
}

class FakeLifeOsTaskRepository implements LifeOsTaskRepository {
  FakeLifeOsTaskRepository(this.task);

  LifeOsTask task;
  final List<LifeOsTask> savedTasks = [];

  @override
  Future<List<LifeOsTask>> getAll() async => [task];

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async {
    return id == task.id ? task : null;
  }

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async => [];

  @override
  Future<void> save(LifeOsTask task) async {
    this.task = task;
    savedTasks.add(task);
  }
}
