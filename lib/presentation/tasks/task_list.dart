import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_task.dart';
import '../relationships/related_entities_section.dart';
import 'task_list_providers.dart';

class TaskList extends ConsumerStatefulWidget {
  const TaskList({super.key});

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList> {
  bool _showTrash = false;
  bool _isMutating = false;
  bool _operationFailed = false;

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(
      _showTrash ? taskTrashControllerProvider : taskListControllerProvider,
    );
    final localizations = AppLocalizations.of(context);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const Key('task-trash-toggle'),
            onPressed: _isMutating
                ? null
                : () => setState(() {
                    _showTrash = !_showTrash;
                    _operationFailed = false;
                  }),
            icon: Icon(_showTrash ? Icons.arrow_back : Icons.delete_outline),
            label: Text(
              _showTrash
                  ? localizations.backToTasksAction
                  : localizations.trashAction,
            ),
          ),
        ),
        if (!_showTrash) const TaskCreationForm(),
        const SizedBox(height: 12),
        if (_operationFailed)
          Text(
            localizations.taskRestoreError,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        Expanded(
          child: tasks.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return Center(
                  child: Text(
                    _showTrash
                        ? localizations.taskTrashEmpty
                        : localizations.taskListEmpty,
                  ),
                );
              }

              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  if (_showTrash) {
                    return ListTile(
                      key: ValueKey('deleted-task-${task.id.value}'),
                      title: Text(task.title),
                      trailing: TextButton.icon(
                        key: ValueKey('restore-task-${task.id.value}'),
                        onPressed: _isMutating
                            ? null
                            : () => _restoreTask(task),
                        icon: const Icon(Icons.restore),
                        label: Text(localizations.restoreTaskAction),
                      ),
                    );
                  }
                  return ExpansionTile(
                    key: ValueKey('task-${task.id.value}'),
                    leading: IconButton(
                      tooltip: task.isCompleted
                          ? localizations.taskCompletionMarkIncomplete
                          : localizations.taskCompletionMarkComplete,
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
                    title: Row(
                      children: [
                        Expanded(child: Text(task.title)),
                        IconButton(
                          key: ValueKey('edit-task-${task.id.value}'),
                          tooltip: localizations.taskEditAction,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed:
                              task.lifecycle == LifeOsEntityLifecycle.active
                              ? () => _showTaskEditDialog(
                                  context: context,
                                  ref: ref,
                                  task: task,
                                )
                              : null,
                        ),
                        IconButton(
                          key: ValueKey('delete-task-${task.id.value}'),
                          tooltip: localizations.deleteTaskAction,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDeleteTask(task),
                        ),
                      ],
                    ),
                    children: [RelatedEntitiesSection(entityId: task.id)],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                Center(child: Text(localizations.taskLoadError)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteTask(LifeOsTask task) => showDialog<void>(
    context: context,
    builder: (context) => _TaskDeleteDialog(
      task: task,
      onDelete: () =>
          ref.read(taskListControllerProvider.notifier).deleteTask(task.id),
    ),
  );

  Future<void> _restoreTask(LifeOsTask task) async {
    setState(() {
      _isMutating = true;
      _operationFailed = false;
    });
    try {
      await ref.read(taskTrashControllerProvider.notifier).restoreTask(task.id);
    } catch (_) {
      if (mounted) setState(() => _operationFailed = true);
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
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
  _TaskCreationError? _error;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = _TaskCreationError.titleRequired);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref
          .read(taskListControllerProvider.notifier)
          .createTask(_titleController.text);
      _titleController.clear();
    } catch (_) {
      if (mounted) {
        setState(() => _error = _TaskCreationError.saveFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final errorText = switch (_error) {
      _TaskCreationError.titleRequired => localizations.taskTitleRequired,
      _TaskCreationError.saveFailed => localizations.taskCreateError,
      null => null,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            key: const Key('task-title-field'),
            controller: _titleController,
            decoration: InputDecoration(
              labelText: localizations.taskTitleFieldLabel,
              errorText: errorText,
            ),
            onSubmitted: _isSaving ? null : (_) => _createTask(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          key: const Key('create-task-button'),
          onPressed: _isSaving ? null : _createTask,
          child: Text(localizations.taskCreateAction),
        ),
      ],
    );
  }
}

enum _TaskCreationError { titleRequired, saveFailed }

Future<void> _showTaskEditDialog({
  required BuildContext context,
  required WidgetRef ref,
  required LifeOsTask task,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _TaskEditDialog(
      task: task,
      onSave: (title) => ref
          .read(taskListControllerProvider.notifier)
          .editTitle(task.id, title),
    ),
  );
}

class _TaskEditDialog extends StatefulWidget {
  const _TaskEditDialog({required this.task, required this.onSave});

  final LifeOsTask task;
  final Future<LifeOsTask> Function(String title) onSave;

  @override
  State<_TaskEditDialog> createState() => _TaskEditDialogState();
}

class _TaskEditDialogState extends State<_TaskEditDialog> {
  late final TextEditingController _titleController;
  bool _isSaving = false;
  _TaskEditError? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = _TaskEditError.titleRequired);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.onSave(_titleController.text);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = _TaskEditError.saveFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final errorText = switch (_error) {
      _TaskEditError.titleRequired => localizations.taskTitleRequired,
      _TaskEditError.saveFailed => localizations.taskEditError,
      null => null,
    };

    return AlertDialog(
      title: Text(localizations.taskEditDialogTitle),
      content: TextField(
        key: const Key('task-edit-title-field'),
        controller: _titleController,
        autofocus: true,
        enabled: !_isSaving,
        decoration: InputDecoration(
          labelText: localizations.taskTitleFieldLabel,
          errorText: errorText,
        ),
        onSubmitted: _isSaving ? null : (_) => _save(),
      ),
      actions: [
        TextButton(
          key: const Key('cancel-task-edit-button'),
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(localizations.cancelAction),
        ),
        FilledButton(
          key: const Key('save-task-edit-button'),
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(localizations.taskSaveAction),
        ),
      ],
    );
  }
}

enum _TaskEditError { titleRequired, saveFailed }

class _TaskDeleteDialog extends StatefulWidget {
  const _TaskDeleteDialog({required this.task, required this.onDelete});

  final LifeOsTask task;
  final Future<void> Function() onDelete;

  @override
  State<_TaskDeleteDialog> createState() => _TaskDeleteDialogState();
}

class _TaskDeleteDialogState extends State<_TaskDeleteDialog> {
  bool _isDeleting = false;
  bool _failed = false;

  Future<void> _delete() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _failed = false;
    });
    try {
      await widget.onDelete();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(localizations.deleteTaskDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localizations.moveTaskToTrashConfirmation(widget.task.title)),
          if (_failed) ...[
            const SizedBox(height: 8),
            Text(
              localizations.taskDeleteError,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: Text(localizations.cancelAction),
        ),
        FilledButton(
          key: const Key('confirm-delete-task-button'),
          onPressed: _isDeleting ? null : _delete,
          child: _isDeleting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(localizations.moveToTrashAction),
        ),
      ],
    );
  }
}
