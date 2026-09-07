import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_completion_providers.dart';

class TaskCompletionCard extends ConsumerWidget {
  const TaskCompletionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskCompletionControllerProvider);

    return taskState.when(
      data: (task) => CheckboxListTile(
        title: Text(task.title),
        value: task.isCompleted,
        onChanged: (_) {
          ref.read(taskCompletionControllerProvider.notifier).toggle();
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Text('Task unavailable'),
    );
  }
}
