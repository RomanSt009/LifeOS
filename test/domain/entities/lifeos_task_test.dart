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
}
