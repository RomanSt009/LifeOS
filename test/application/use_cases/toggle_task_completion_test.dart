import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/toggle_task_completion.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';

void main() {
  final createdAt = DateTime.utc(2026, 9, 5, 10);
  final firstUpdatedAt = DateTime.utc(2026, 9, 5, 11);
  final secondUpdatedAt = DateTime.utc(2026, 9, 5, 12);
  const id = LifeOsEntityId(
    value: 'task-1',
    entityType: LifeOsEntityType.task,
  );
  const toggleTaskCompletion = ToggleTaskCompletion();

  LifeOsTask createTask({required bool isCompleted}) {
    return LifeOsTask(
      id: id,
      title: 'Implement completion behavior',
      isCompleted: isCompleted,
      createdAt: createdAt,
      updatedAt: firstUpdatedAt,
      lifecycle: LifeOsEntityLifecycle.active,
      version: 1,
      source: LifeOsEntitySource.user,
    );
  }

  test('changes an incomplete task to complete', () {
    final original = createTask(isCompleted: false);

    final result = toggleTaskCompletion(original, updatedAt: secondUpdatedAt);

    expect(result.isCompleted, isTrue);
    expect(result.id, original.id);
    expect(result.createdAt, original.createdAt);
    expect(result.updatedAt, secondUpdatedAt);
    expect(result.version, 2);
  });

  test('changes a complete task to incomplete', () {
    final original = createTask(isCompleted: true);

    final result = toggleTaskCompletion(original, updatedAt: secondUpdatedAt);

    expect(result.isCompleted, isFalse);
  });

  test('leaves the original task unchanged', () {
    final original = createTask(isCompleted: false);

    final result = toggleTaskCompletion(original, updatedAt: secondUpdatedAt);

    expect(original.isCompleted, isFalse);
    expect(original.updatedAt, firstUpdatedAt);
    expect(original.version, 1);
    expect(result, isNot(same(original)));
  });
}
