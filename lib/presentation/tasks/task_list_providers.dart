import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/create_lifeos_task.dart';
import '../../application/use_cases/edit_lifeos_task_title.dart';
import '../../application/use_cases/delete_lifeos_task.dart';
import '../../application/use_cases/restore_lifeos_task.dart';
import '../../application/use_cases/get_lifeos_tasks.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_task.dart';
import '../relationships/relationship_providers.dart';
import '../search/task_search_providers.dart';
import '../workspaces/workspace_member_refresh.dart';
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

final deleteLifeOsTaskProvider = Provider<DeleteLifeOsTask>((ref) {
  throw UnimplementedError(
    'deleteLifeOsTaskProvider must be overridden by app composition.',
  );
});

final restoreLifeOsTaskProvider = Provider<RestoreLifeOsTask>((ref) {
  throw UnimplementedError(
    'restoreLifeOsTaskProvider must be overridden by app composition.',
  );
});

final getLifeOsTasksProvider = Provider<GetLifeOsTasks>((ref) {
  return GetLifeOsTasks(ref.watch(lifeOsTaskRepositoryProvider));
});

final getDeletedLifeOsTasksProvider = Provider<GetDeletedLifeOsTasks>((ref) {
  return GetDeletedLifeOsTasks(ref.watch(lifeOsTaskRepositoryProvider));
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
    ref.invalidate(directLifeOsRelatedNeighborsProvider);
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
    ref.invalidate(directLifeOsRelatedNeighborsProvider);
    return updatedTask;
  }

  Future<void> deleteTask(LifeOsEntityId id) async {
    final deleted = await ref.read(deleteLifeOsTaskProvider)(id);
    if (deleted == null) {
      throw StateError('The selected Task no longer exists.');
    }
    state = AsyncData([
      for (final task in state.requireValue)
        if (task.id != id) task,
    ]);
    ref.invalidate(taskTrashControllerProvider);
    ref.invalidate(directLifeOsRelatedNeighborsProvider);
    ref.read(taskSearchRevisionProvider.notifier).advance();
    ref.read(workspaceMemberRevisionProvider.notifier).advance();
  }
}

final taskTrashControllerProvider =
    AsyncNotifierProvider<TaskTrashController, List<LifeOsTask>>(
      TaskTrashController.new,
    );

class TaskTrashController extends AsyncNotifier<List<LifeOsTask>> {
  @override
  Future<List<LifeOsTask>> build() =>
      ref.watch(getDeletedLifeOsTasksProvider)();

  Future<void> restoreTask(LifeOsEntityId id) async {
    final restored = await ref.read(restoreLifeOsTaskProvider)(id);
    if (restored == null) {
      throw StateError('The selected Task no longer exists.');
    }
    state = AsyncData([
      for (final task in state.requireValue)
        if (task.id != id) task,
    ]);
    ref.invalidate(taskListControllerProvider);
    ref.invalidate(directLifeOsRelatedNeighborsProvider);
    ref.read(taskSearchRevisionProvider.notifier).advance();
    ref.read(workspaceMemberRevisionProvider.notifier).advance();
  }
}
