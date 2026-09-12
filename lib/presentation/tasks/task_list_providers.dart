import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/create_lifeos_task.dart';
import '../../application/use_cases/edit_lifeos_task_title.dart';
import '../../application/use_cases/get_lifeos_tasks.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_task.dart';
import 'task_completion_providers.dart';

final createLifeOsTaskProvider = Provider<CreateLifeOsTask>((ref) {
  throw UnimplementedError(
    'createLifeOsTaskProvider must be overridden by app composition.',
  );
});

final editLifeOsTaskTitleProvider = Provider<EditLifeOsTaskTitle>((ref) {
  throw UnimplementedError(
    'editLifeOsTaskTitleProvider must be overridden by app composition.',
  );
});

final getLifeOsTasksProvider = Provider<GetLifeOsTasks>((ref) {
  return GetLifeOsTasks(ref.watch(lifeOsTaskRepositoryProvider));
});

final taskListControllerProvider =
    AsyncNotifierProvider<TaskListController, List<LifeOsTask>>(
      TaskListController.new,
    );

class TaskListController extends AsyncNotifier<List<LifeOsTask>> {
  @override
  Future<List<LifeOsTask>> build() {
    return ref.watch(getLifeOsTasksProvider)();
  }

  Future<LifeOsTask> createTask(String title) async {
    final currentTasks = state.requireValue;
    final createdTask = await ref.read(createLifeOsTaskProvider)(title);
    state = AsyncData([...currentTasks, createdTask]);
    return createdTask;
  }

  Future<void> toggleCompletion(LifeOsEntityId id) async {
    final currentTasks = state.requireValue;
    final updatedTask = await ref.read(toggleStoredTaskCompletionProvider)(
      id,
      updatedAt: DateTime.now().toUtc(),
    );
    if (updatedTask == null) {
      throw StateError('The selected Task no longer exists.');
    }

    state = AsyncData([
      for (final task in currentTasks)
        if (task.id == id) updatedTask else task,
    ]);
  }

  Future<LifeOsTask> editTitle(LifeOsEntityId id, String title) async {
    final updatedTask = await ref.read(editLifeOsTaskTitleProvider)(
      id,
      title: title,
    );
    if (updatedTask == null) {
      throw StateError('The selected Task no longer exists.');
    }

    final currentTasks = state.requireValue;
    state = AsyncData([
      for (final task in currentTasks)
        if (task.id == id) updatedTask else task,
    ]);
    return updatedTask;
  }
}
