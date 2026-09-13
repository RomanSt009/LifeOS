import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/get_lifeos_tasks.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';

void main() {
  test(
    'returns the Task collection supplied by the Domain repository',
    () async {
      final tasks = [
        LifeOsTask(
          id: const LifeOsEntityId(
            value: 'task-1',
            entityType: LifeOsEntityType.task,
          ),
          title: 'Read Tasks',
          isCompleted: false,
          createdAt: DateTime.utc(2026, 9, 8, 13),
          updatedAt: DateTime.utc(2026, 9, 8, 13),
          lifecycle: LifeOsEntityLifecycle.active,
          version: 1,
          source: LifeOsEntitySource.user,
        ),
        LifeOsTask(
          id: const LifeOsEntityId(
            value: 'task-deleted',
            entityType: LifeOsEntityType.task,
          ),
          title: 'Deleted Task',
          isCompleted: false,
          createdAt: DateTime.utc(2026, 9, 8, 13),
          updatedAt: DateTime.utc(2026, 9, 8, 14),
          lifecycle: LifeOsEntityLifecycle.deleted,
          version: 2,
          source: LifeOsEntitySource.user,
        ),
      ];
      final repository = FakeLifeOsTaskRepository(tasks);

      final result = await GetLifeOsTasks(repository)();

      expect(result, [tasks.first]);
    },
  );
}

class FakeLifeOsTaskRepository implements LifeOsTaskRepository {
  FakeLifeOsTaskRepository(this.tasks);

  final List<LifeOsTask> tasks;

  @override
  Future<List<LifeOsTask>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async => tasks.where((task) => task.lifecycle == lifecycle).toList();

  @override
  Future<List<LifeOsTask>> getAll() async => tasks;

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async => null;

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async => [];

  @override
  Future<void> save(LifeOsTask task) async {}
}
