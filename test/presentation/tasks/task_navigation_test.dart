import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/create_lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/shell/lifeos_shell_page.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';
import 'package:lifeos/presentation/tasks/task_list_providers.dart';

void main() {
  testWidgets(
    'keeps list, create, and completion working across shell navigation',
    (tester) async {
      final existingTask = LifeOsTask.createUserTask(
        id: const LifeOsEntityId(
          value: 'task-existing',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Persisted Task',
        timestamp: DateTime.utc(2026, 9, 11, 10),
      );
      final repository = FakeLifeOsTaskRepository([existingTask]);
      final createTask = CreateLifeOsTask(
        repository: repository,
        entityIdGenerator: () => 'task-created-through-shell',
        utcClock: () => DateTime.utc(2026, 9, 11, 11),
      );

      await tester.pumpWidget(testApp(repository, createTask));
      await tester.pumpAndSettle();

      expect(find.text('Persisted Task'), findsOneWidget);

      await navigate(tester, 'Home');
      await navigate(tester, 'Tasks');
      await navigate(tester, 'Home');
      await navigate(tester, 'Tasks');

      expect(find.text('Persisted Task'), findsOneWidget);

      await tester.tap(find.byTooltip('Mark complete'));
      await tester.pumpAndSettle();

      expect(repository.tasks.first.isCompleted, isTrue);
      expect(repository.tasks.first.version, 2);
      expect(find.byTooltip('Mark incomplete'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('task-title-field')),
        'Created through shell',
      );
      await tester.tap(find.byKey(const Key('create-task-button')));
      await tester.pumpAndSettle();

      expect(find.text('Created through shell'), findsOneWidget);
      expect(repository.tasks, hasLength(2));

      await navigate(tester, 'Home');
      await navigate(tester, 'Tasks');

      expect(find.text('Persisted Task'), findsOneWidget);
      expect(find.text('Created through shell'), findsOneWidget);
      expect(find.byTooltip('Mark incomplete'), findsOneWidget);
    },
  );
}

Future<void> navigate(WidgetTester tester, String destination) async {
  await tester.tap(find.text(destination));
  await tester.pumpAndSettle();
}

Widget testApp(LifeOsTaskRepository repository, CreateLifeOsTask createTask) {
  return ProviderScope(
    overrides: [
      lifeOsTaskRepositoryProvider.overrideWithValue(repository),
      createLifeOsTaskProvider.overrideWithValue(createTask),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LifeosShellPage(),
    ),
  );
}

class FakeLifeOsTaskRepository implements LifeOsTaskRepository {
  FakeLifeOsTaskRepository(this.tasks);

  final List<LifeOsTask> tasks;

  @override
  Future<List<LifeOsTask>> getAll() async => List.unmodifiable(tasks);

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async {
    for (final task in tasks) {
      if (task.id == id) {
        return task;
      }
    }
    return null;
  }

  @override
  Future<void> save(LifeOsTask task) async {
    final index = tasks.indexWhere((storedTask) => storedTask.id == task.id);
    if (index == -1) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }
  }
}
