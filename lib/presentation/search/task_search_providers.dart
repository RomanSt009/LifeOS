import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/search_lifeos_tasks.dart';

final searchLifeOsTasksProvider = Provider<SearchLifeOsTasks>((ref) {
  throw UnimplementedError(
    'searchLifeOsTasksProvider must be overridden by app composition.',
  );
});

final taskSearchRevisionProvider =
    NotifierProvider<TaskSearchRevisionController, int>(
      TaskSearchRevisionController.new,
    );

class TaskSearchRevisionController extends Notifier<int> {
  @override
  int build() => 0;

  void advance() => state += 1;
}
