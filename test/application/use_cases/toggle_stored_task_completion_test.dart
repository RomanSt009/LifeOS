import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/toggle_stored_task_completion.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';

void main() {
  final createdAt = DateTime.utc(2026, 9, 6, 10);
  final initialUpdatedAt = DateTime.utc(2026, 9, 6, 11);
  final toggledAt = DateTime.utc(2026, 9, 6, 12);
  const id = LifeOsEntityId(
    value: 'task-1',
    entityType: LifeOsEntityType.task,
  );

  LifeOsTask createTask({required bool isCompleted}) {
    return LifeOsTask(
      id: id,
      title: 'Verify the repository boundary',
      isCompleted: isCompleted,
      createdAt: createdAt,
      updatedAt: initialUpdatedAt,
      lifecycle: LifeOsEntityLifecycle.active,
      version: 1,
      source: LifeOsEntitySource.user,
    );
  }

  test('loads an incomplete task, toggles it, saves it, and returns it', () async {
    final original = createTask(isCompleted: false);
    final repository = FakeLifeOsTaskRepository(taskToReturn: original);
    final toggleStoredTaskCompletion = ToggleStoredTaskCompletion(
      repository: repository,
    );

    final result = await toggleStoredTaskCompletion(id, updatedAt: toggledAt);

    expect(repository.requestedIds, [id]);
    expect(result, isNotNull);
    expect(result!.isCompleted, isTrue);
    expect(result.version, 2);
    expect(result.updatedAt, toggledAt);
    expect(repository.savedTasks, [result]);
    expect(original.isCompleted, isFalse);
    expect(original.version, 1);
    expect(original.updatedAt, initialUpdatedAt);
    expect(result, isNot(same(original)));
  });

  test('loads a complete task and toggles it to incomplete', () async {
    final original = createTask(isCompleted: true);
    final repository = FakeLifeOsTaskRepository(taskToReturn: original);
    final toggleStoredTaskCompletion = ToggleStoredTaskCompletion(
      repository: repository,
    );

    final result = await toggleStoredTaskCompletion(id, updatedAt: toggledAt);

    expect(result, isNotNull);
    expect(result!.isCompleted, isFalse);
    expect(repository.savedTasks, [result]);
    expect(original.isCompleted, isTrue);
  });

  test('returns null and does not save when the task is missing', () async {
    final repository = FakeLifeOsTaskRepository();
    final toggleStoredTaskCompletion = ToggleStoredTaskCompletion(
      repository: repository,
    );

    final result = await toggleStoredTaskCompletion(id, updatedAt: toggledAt);

    expect(repository.requestedIds, [id]);
    expect(result, isNull);
    expect(repository.savedTasks, isEmpty);
  });
}

class FakeLifeOsTaskRepository implements LifeOsTaskRepository {
  FakeLifeOsTaskRepository({this.taskToReturn});

  final LifeOsTask? taskToReturn;
  final List<LifeOsEntityId> requestedIds = [];
  final List<LifeOsTask> savedTasks = [];

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async {
    requestedIds.add(id);
    return taskToReturn;
  }

  @override
  Future<void> save(LifeOsTask task) async {
    savedTasks.add(task);
  }
}
