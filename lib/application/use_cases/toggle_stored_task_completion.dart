import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_task.dart';
import '../../domain/repositories/lifeos_task_repository.dart';
import 'toggle_task_completion.dart';

class ToggleStoredTaskCompletion {
  const ToggleStoredTaskCompletion({
    required this.repository,
    this.toggleTaskCompletion = const ToggleTaskCompletion(),
  });

  final LifeOsTaskRepository repository;
  final ToggleTaskCompletion toggleTaskCompletion;

  Future<LifeOsTask?> call(
    LifeOsEntityId id, {
    required DateTime updatedAt,
  }) async {
    final task = await repository.getById(id);
    if (task == null) {
      return null;
    }

    final updatedTask = toggleTaskCompletion(task, updatedAt: updatedAt);
    await repository.save(updatedTask);
    return updatedTask;
  }
}
