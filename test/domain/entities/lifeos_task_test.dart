import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';

void main() {
  test('LifeOsTask exposes task data and the shared entity contract', () {
    final createdAt = DateTime.utc(2026, 9, 5, 10);
    final updatedAt = DateTime.utc(2026, 9, 5, 11);
    const id = LifeOsEntityId(
      value: 'task-1',
      entityType: LifeOsEntityType.task,
    );
    final task = LifeOsTask(
      id: id,
      title: 'Define the first task model',
      isCompleted: false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lifecycle: LifeOsEntityLifecycle.active,
      version: 1,
      source: LifeOsEntitySource.user,
    );

    expect(task, isA<LifeOsEntity>());
    expect(task.id, id);
    expect(task.id.entityType, LifeOsEntityType.task);
    expect(task.entityType, LifeOsEntityType.task);
    expect(task.title, 'Define the first task model');
    expect(task.isCompleted, isFalse);
    expect(task.createdAt, createdAt);
    expect(task.updatedAt, updatedAt);
    expect(task.lifecycle, LifeOsEntityLifecycle.active);
    expect(task.version, 1);
    expect(task.source, LifeOsEntitySource.user);
  });

  test('toggles completion immutably and advances entity metadata', () {
    final createdAt = DateTime.utc(2026, 9, 5, 10);
    final initialUpdatedAt = DateTime.utc(2026, 9, 5, 11);
    final toggledAt = DateTime.utc(2026, 9, 5, 12);
    final task = LifeOsTask(
      id: const LifeOsEntityId(
        value: 'task-1',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Keep completion behavior in Domain',
      isCompleted: false,
      createdAt: createdAt,
      updatedAt: initialUpdatedAt,
      lifecycle: LifeOsEntityLifecycle.active,
      version: 1,
      source: LifeOsEntitySource.user,
    );

    final completed = task.toggleCompletion(updatedAt: toggledAt);
    final reopened = completed.toggleCompletion(updatedAt: toggledAt);

    expect(completed.isCompleted, isTrue);
    expect(completed.id, task.id);
    expect(completed.title, task.title);
    expect(completed.createdAt, task.createdAt);
    expect(completed.updatedAt, toggledAt);
    expect(completed.lifecycle, task.lifecycle);
    expect(completed.version, 2);
    expect(completed.source, task.source);
    expect(reopened.isCompleted, isFalse);
    expect(reopened.version, 3);
    expect(task.isCompleted, isFalse);
    expect(task.updatedAt, initialUpdatedAt);
    expect(task.version, 1);
    expect(completed, isNot(same(task)));
  });

  test('creates a valid user Task with the required initial metadata', () {
    final timestamp = DateTime.utc(2026, 9, 9, 14);

    final task = LifeOsTask.createUserTask(
      id: const LifeOsEntityId(
        value: 'task-created',
        entityType: LifeOsEntityType.task,
      ),
      title: '  Create a Task  ',
      timestamp: timestamp,
    );

    expect(task.title, 'Create a Task');
    expect(task.isCompleted, isFalse);
    expect(task.createdAt, timestamp);
    expect(task.updatedAt, same(timestamp));
    expect(task.lifecycle, LifeOsEntityLifecycle.active);
    expect(task.version, 1);
    expect(task.source, LifeOsEntitySource.user);
  });

  test('rejects invalid user Task creation input', () {
    expect(
      () => LifeOsTask.createUserTask(
        id: const LifeOsEntityId(
          value: 'task-created',
          entityType: LifeOsEntityType.task,
        ),
        title: '   ',
        timestamp: DateTime.utc(2026, 9, 9, 14),
      ),
      throwsArgumentError,
    );
    expect(
      () => LifeOsTask.createUserTask(
        id: const LifeOsEntityId(
          value: 'task-created',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Create a Task',
        timestamp: DateTime(2026, 9, 9, 14),
      ),
      throwsArgumentError,
    );
  });

  test('edits a title immutably and advances metadata', () {
    final task = LifeOsTask.createUserTask(
      id: const LifeOsEntityId(
        value: 'task-edit',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Original title',
      timestamp: DateTime.utc(2026, 9, 13, 10),
    );
    final updatedAt = DateTime.utc(2026, 9, 13, 11);

    final edited = task.editTitle(
      title: '  Updated title  ',
      updatedAt: updatedAt,
    );

    expect(edited.title, 'Updated title');
    expect(edited.updatedAt, updatedAt);
    expect(edited.version, 2);
    expect(edited.isCompleted, task.isCompleted);
    expect(edited.id, task.id);
    expect(task.title, 'Original title');
    expect(edited, isNot(same(task)));
  });

  test('returns the same Task for a normalized no-op edit', () {
    final task = LifeOsTask.createUserTask(
      id: const LifeOsEntityId(
        value: 'task-no-op',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Same title',
      timestamp: DateTime.utc(2026, 9, 13, 10),
    );

    final result = task.editTitle(
      title: '  Same title  ',
      updatedAt: DateTime.utc(2026, 9, 13, 11),
    );

    expect(result, same(task));
  });

  test('rejects invalid and inactive title edits', () {
    final task = LifeOsTask.createUserTask(
      id: const LifeOsEntityId(
        value: 'task-validation',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Valid title',
      timestamp: DateTime.utc(2026, 9, 13, 10),
    );
    final archived = LifeOsTask(
      id: task.id,
      title: task.title,
      isCompleted: task.isCompleted,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      lifecycle: LifeOsEntityLifecycle.archived,
      version: task.version,
      source: task.source,
    );
    final deleted = LifeOsTask(
      id: task.id,
      title: task.title,
      isCompleted: task.isCompleted,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      lifecycle: LifeOsEntityLifecycle.deleted,
      version: task.version,
      source: task.source,
    );

    expect(
      () => task.editTitle(
        title: '   ',
        updatedAt: DateTime.utc(2026, 9, 13, 11),
      ),
      throwsArgumentError,
    );
    expect(
      () => task.editTitle(
        title: task.title,
        updatedAt: DateTime(2026, 9, 13, 11),
      ),
      throwsArgumentError,
    );
    expect(
      () => task.editTitle(
        title: task.title,
        updatedAt: DateTime.utc(2026, 9, 13, 9),
      ),
      throwsArgumentError,
    );
    expect(
      () => archived.editTitle(
        title: 'Changed',
        updatedAt: DateTime.utc(2026, 9, 13, 11),
      ),
      throwsStateError,
    );
    expect(
      () => deleted.editTitle(
        title: 'Changed',
        updatedAt: DateTime.utc(2026, 9, 13, 11),
      ),
      throwsStateError,
    );
  });

  test('rejects hydrated Task state that violates invariants', () {
    LifeOsTask hydrate({
      LifeOsEntityId id = const LifeOsEntityId(
        value: 'task-hydrated',
        entityType: LifeOsEntityType.task,
      ),
      String title = 'Hydrated title',
      DateTime? createdAt,
      DateTime? updatedAt,
      int version = 1,
    }) => LifeOsTask(
      id: id,
      title: title,
      isCompleted: false,
      createdAt: createdAt ?? DateTime.utc(2026, 9, 13, 10),
      updatedAt: updatedAt ?? DateTime.utc(2026, 9, 13, 11),
      lifecycle: LifeOsEntityLifecycle.active,
      version: version,
      source: LifeOsEntitySource.user,
    );

    expect(() => hydrate(title: ' padded '), throwsArgumentError);
    expect(() => hydrate(title: ''), throwsArgumentError);
    expect(() => hydrate(version: 0), throwsArgumentError);
    expect(
      () => hydrate(createdAt: DateTime(2026, 9, 13, 10)),
      throwsArgumentError,
    );
    expect(
      () => hydrate(updatedAt: DateTime.utc(2026, 9, 13, 9)),
      throwsArgumentError,
    );
    expect(
      () => hydrate(
        id: const LifeOsEntityId(
          value: 'note-id',
          entityType: LifeOsEntityType.note,
        ),
      ),
      throwsArgumentError,
    );
  });
}
