import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/create_lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';

void main() {
  test('creates and saves a deterministic valid user Task', () async {
    final repository = FakeLifeOsTaskRepository();
    final timestamp = DateTime.utc(2026, 9, 9, 15);
    var idGenerationCount = 0;
    var clockReadCount = 0;
    final createTask = CreateLifeOsTask(
      repository: repository,
      entityIdGenerator: () {
        idGenerationCount += 1;
        return 'task-created';
      },
      utcClock: () {
        clockReadCount += 1;
        return timestamp;
      },
    );

    final task = await createTask('  Write the first Task  ');

    expect(
      task.id,
      const LifeOsEntityId(
        value: 'task-created',
        entityType: LifeOsEntityType.task,
      ),
    );
    expect(task.title, 'Write the first Task');
    expect(task.isCompleted, isFalse);
    expect(task.createdAt, timestamp);
    expect(task.updatedAt, same(timestamp));
    expect(task.lifecycle, LifeOsEntityLifecycle.active);
    expect(task.version, 1);
    expect(task.source, LifeOsEntitySource.user);
    expect(repository.savedTasks, [task]);
    expect(idGenerationCount, 1);
    expect(clockReadCount, 1);
  });
}

class FakeLifeOsTaskRepository implements LifeOsTaskRepository {
  final List<LifeOsTask> savedTasks = [];

  @override
  Future<List<LifeOsTask>> getAll() async => savedTasks;

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async => null;

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async => [];

  @override
  Future<void> save(LifeOsTask task) async {
    savedTasks.add(task);
  }
}
