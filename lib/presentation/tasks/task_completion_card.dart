import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'task_completion_providers.dart';

class TaskCompletionCard extends ConsumerWidget {
  const TaskCompletionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskCompletionControllerProvider);
    final localizations = AppLocalizations.of(context);

    return taskState.when(
      data: (task) => CheckboxListTile(
        title: Text(task.title),
        value: task.isCompleted,
        onChanged: (_) {
          ref.read(taskCompletionControllerProvider.notifier).toggle();
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text(localizations.taskUnavailable),
    );
  }
}
