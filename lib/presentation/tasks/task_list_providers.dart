import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/get_lifeos_tasks.dart';
import '../../domain/entities/lifeos_task.dart';
import 'task_completion_providers.dart';

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
}
