import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'task_list_providers.dart';

class TaskList extends ConsumerWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListControllerProvider);

    return Column(
      children: [
        const TaskCreationForm(),
        const SizedBox(height: 12),
        Expanded(
          child: tasks.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return const Center(child: Text('No Tasks yet'));
              }

              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return ListTile(
                    leading: IconButton(
                      tooltip: task.isCompleted
                          ? 'Mark incomplete'
                          : 'Mark complete',
                      icon: Icon(
                        task.isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      onPressed: () async {
                        await ref
                            .read(taskListControllerProvider.notifier)
                            .toggleCompletion(task.id);
                      },
                    ),
                    title: Text(task.title),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                const Center(child: Text('Unable to load Tasks')),
          ),
        ),
      ],
    );
  }
}

class TaskCreationForm extends ConsumerStatefulWidget {
  const TaskCreationForm({super.key});

  @override
  ConsumerState<TaskCreationForm> createState() => _TaskCreationFormState();
}

class _TaskCreationFormState extends ConsumerState<TaskCreationForm> {
  final _titleController = TextEditingController();
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorText = 'Enter a Task title');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await ref
          .read(taskListControllerProvider.notifier)
          .createTask(_titleController.text);
      _titleController.clear();
    } catch (_) {
      if (mounted) {
        setState(() => _errorText = 'Unable to create Task');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: const Key('task-title-field'),
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Task title',
              errorText: _errorText,
            ),
            onSubmitted: _isSaving ? null : (_) => _createTask(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          key: const Key('create-task-button'),
          onPressed: _isSaving ? null : _createTask,
          child: const Text('Add Task'),
        ),
      ],
    );
  }
}
