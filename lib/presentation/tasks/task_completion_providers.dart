import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/toggle_stored_task_completion.dart';
import '../../domain/entities/lifeos_task.dart';
import '../../domain/repositories/lifeos_task_repository.dart';

final lifeOsTaskRepositoryProvider = Provider<LifeOsTaskRepository>((ref) {
  throw UnimplementedError(
    'lifeOsTaskRepositoryProvider must be overridden by app composition.',
  );
});

final displayedTaskProvider = Provider<LifeOsTask>((ref) {
  throw UnimplementedError(
    'displayedTaskProvider must be overridden by app composition.',
  );
});

final toggleStoredTaskCompletionProvider = Provider<ToggleStoredTaskCompletion>(
  (ref) {
    return ToggleStoredTaskCompletion(
      repository: ref.watch(lifeOsTaskRepositoryProvider),
    );
  },
);

final taskCompletionControllerProvider =
    AsyncNotifierProvider<TaskCompletionController, LifeOsTask>(
      TaskCompletionController.new,
    );

class TaskCompletionController extends AsyncNotifier<LifeOsTask> {
  @override
  FutureOr<LifeOsTask> build() => ref.watch(displayedTaskProvider);

  Future<void> toggle() async {
    final currentTask = state.requireValue;
    final toggleStoredTaskCompletion = ref.read(
      toggleStoredTaskCompletionProvider,
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updatedTask = await toggleStoredTaskCompletion(
        currentTask.id,
        updatedAt: DateTime.now().toUtc(),
      );
      if (updatedTask == null) {
        throw StateError('The displayed Task no longer exists.');
      }
      return updatedTask;
    });
  }
}
