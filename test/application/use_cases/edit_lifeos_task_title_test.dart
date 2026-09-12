import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_task_title.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';

void main() {
  const id = LifeOsEntityId(
    value: 'task-edit',
    entityType: LifeOsEntityType.task,
  );
  final original = LifeOsTask.createUserTask(
    id: id,
    title: 'Original',
    timestamp: DateTime.utc(2026, 9, 13, 10),
  );

  test('loads, edits, saves, and returns the Task', () async {
    final repository = _FakeTaskRepository(original);
    final useCase = EditLifeOsTaskTitle(
      repository: repository,
      utcClock: () => DateTime.utc(2026, 9, 13, 11),
    );

    final result = await useCase(id, title: '  Updated  ');

    expect(repository.requestedIds, [id]);
    expect(result?.title, 'Updated');
    expect(result?.version, 2);
    expect(result?.updatedAt, DateTime.utc(2026, 9, 13, 11));
    expect(repository.savedTasks, [result]);
  });

  test('does not save a normalized no-op edit', () async {
    final repository = _FakeTaskRepository(original);
    final useCase = EditLifeOsTaskTitle(
      repository: repository,
      utcClock: () => DateTime.utc(2026, 9, 13, 11),
    );

    final result = await useCase(id, title: ' Original ');

    expect(result, same(original));
    expect(repository.savedTasks, isEmpty);
  });

  test('returns null without saving when the Task is missing', () async {
    final repository = _FakeTaskRepository(null);
    final useCase = EditLifeOsTaskTitle(
      repository: repository,
      utcClock: () => DateTime.utc(2026, 9, 13, 11),
    );

    expect(await useCase(id, title: 'Updated'), isNull);
    expect(repository.savedTasks, isEmpty);
  });

  test('propagates Domain validation without saving', () async {
    final repository = _FakeTaskRepository(original);
    final useCase = EditLifeOsTaskTitle(
      repository: repository,
      utcClock: () => DateTime.utc(2026, 9, 13, 11),
    );

    await expectLater(useCase(id, title: '   '), throwsArgumentError);
    expect(repository.savedTasks, isEmpty);
  });
}

class _FakeTaskRepository implements LifeOsTaskRepository {
  _FakeTaskRepository(this.task);

  final LifeOsTask? task;
  final List<LifeOsEntityId> requestedIds = [];
  final List<LifeOsTask> savedTasks = [];

  @override
  Future<List<LifeOsTask>> getAll() async => [?task];

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async {
    requestedIds.add(id);
    return task;
  }

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async => [];

  @override
  Future<void> save(LifeOsTask task) async => savedTasks.add(task);
}
