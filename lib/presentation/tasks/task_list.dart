import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _featureFocusNode = FocusNode(debugLabel: 'Task feature actions');
  final _creationFocusNode = FocusNode(debugLabel: 'Task creation title');
  final _expansionControllers = <LifeOsEntityId, ExpansibleController>{};
  final _relationshipKeys = <LifeOsEntityId, GlobalKey>{};
  bool _showTrash = false;
  bool _isMutating = false;
  bool _operationFailed = false;
  LifeOsEntityId? _selectedTaskId;

  @override
  void dispose() {
    _featureFocusNode.dispose();
    _creationFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleFeatureKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyN) {
      if (!_showTrash && !_isMutating) _focusCreation();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete &&
        !_showTrash &&
        !_isMutating &&
        !_hasEditableTextFocus()) {
      final selected = _selectedTask();
      if (selected != null) _confirmDeleteTask(selected);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        _selectedTaskId != null &&
        !_hasEditableTextFocus()) {
      setState(() => _selectedTaskId = null);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _hasEditableTextFocus() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context?.widget is EditableText ||
        context?.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  LifeOsTask? _selectedTask() {
    final selectedId = _selectedTaskId;
    if (selectedId == null) return null;
    return ref
        .read(taskListControllerProvider)
        .asData
        ?.value
        .where((task) => task.id == selectedId)
        .firstOrNull;
  }

  void _focusCreation() {
    _creationFocusNode.requestFocus();
  }

  void _selectTask(LifeOsEntityId id) {
    if (_selectedTaskId != id) setState(() => _selectedTaskId = id);
    _featureFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(
      _showTrash ? taskTrashControllerProvider : taskListControllerProvider,
    );
    final localizations = AppLocalizations.of(context);

    return Focus(
      focusNode: _featureFocusNode,
      autofocus: true,
      onKeyEvent: _handleFeatureKeyEvent,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('task-trash-toggle'),
              onPressed: _isMutating
                  ? null
                  : () => setState(() {
                      _showTrash = !_showTrash;
                      _selectedTaskId = null;
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
          if (!_showTrash) TaskCreationForm(titleFocusNode: _creationFocusNode),
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
                      return GestureDetector(
                        onSecondaryTapDown: (details) =>
                            _showDeletedTaskMenu(task, details.globalPosition),
                        child: ListTile(
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
                        ),
                      );
                    }
                    final isSelected = task.id == _selectedTaskId;
                    return GestureDetector(
                      onSecondaryTapDown: (details) =>
                          _showActiveTaskMenu(task, details.globalPosition),
                      child: ExpansionTile(
                        key: ValueKey('task-${task.id.value}'),
                        controller: _expansionControllers.putIfAbsent(
                          task.id,
                          ExpansibleController.new,
                        ),
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : null,
                        collapsedBackgroundColor: isSelected
                            ? Theme.of(context).colorScheme.secondaryContainer
                            : null,
                        onExpansionChanged: (_) => _selectTask(task.id),
                        leading: IconButton(
                          tooltip: task.isCompleted
                              ? localizations.taskCompletionMarkIncomplete
                              : localizations.taskCompletionMarkComplete,
                          icon: Icon(
                            task.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                          ),
                          onPressed: () => _toggleCompletion(task),
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
                                  ? () => _editTask(task)
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
                        children: [
                          RelatedEntitiesSection(
                            key: _relationshipKeys.putIfAbsent(
                              task.id,
                              GlobalKey.new,
                            ),
                            entityId: task.id,
                          ),
                        ],
                      ),
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
      ),
    );
  }

  Future<void> _editTask(LifeOsTask task) async {
    _selectTask(task.id);
    await _showTaskEditDialog(context: context, ref: ref, task: task);
    if (mounted) _featureFocusNode.requestFocus();
  }

  Future<void> _toggleCompletion(LifeOsTask task) async {
    _selectTask(task.id);
    await ref
        .read(taskListControllerProvider.notifier)
        .toggleCompletion(task.id);
    if (mounted) _featureFocusNode.requestFocus();
  }

  Future<void> _showRelationships(LifeOsTask task) async {
    _selectTask(task.id);
    _expansionControllers
        .putIfAbsent(task.id, ExpansibleController.new)
        .expand();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final relationshipContext = _relationshipKeys[task.id]?.currentContext;
      if (relationshipContext != null) {
        Scrollable.ensureVisible(
          relationshipContext,
          duration: const Duration(milliseconds: 150),
        );
      }
    });
  }

  Future<void> _showActiveTaskMenu(LifeOsTask task, Offset position) async {
    _selectTask(task.id);
    final localizations = AppLocalizations.of(context);
    final action = await showMenu<_TaskContextAction>(
      context: context,
      position: _menuPosition(context, position),
      items: [
        PopupMenuItem(
          key: const Key('task-context-edit'),
          value: _TaskContextAction.edit,
          child: Text(localizations.taskEditAction),
        ),
        PopupMenuItem(
          key: const Key('task-context-toggle-completion'),
          value: _TaskContextAction.toggleCompletion,
          child: Text(
            task.isCompleted
                ? localizations.taskCompletionMarkIncomplete
                : localizations.taskCompletionMarkComplete,
          ),
        ),
        PopupMenuItem(
          key: const Key('task-context-relationships'),
          value: _TaskContextAction.relationships,
          child: Text(localizations.relationshipSectionTitle),
        ),
        PopupMenuItem(
          key: const Key('task-context-move-to-trash'),
          value: _TaskContextAction.moveToTrash,
          child: Text(localizations.moveToTrashAction),
        ),
      ],
    );
    if (!mounted) return;
    switch (action) {
      case _TaskContextAction.edit:
        await _editTask(task);
      case _TaskContextAction.toggleCompletion:
        await _toggleCompletion(task);
      case _TaskContextAction.relationships:
        await _showRelationships(task);
      case _TaskContextAction.moveToTrash:
        await _confirmDeleteTask(task);
      case _TaskContextAction.restore:
        break;
      case null:
        _featureFocusNode.requestFocus();
    }
  }

  Future<void> _showDeletedTaskMenu(LifeOsTask task, Offset position) async {
    final action = await showMenu<_TaskContextAction>(
      context: context,
      position: _menuPosition(context, position),
      items: [
        PopupMenuItem(
          key: const Key('task-context-restore'),
          value: _TaskContextAction.restore,
          child: Text(AppLocalizations.of(context).restoreTaskAction),
        ),
      ],
    );
    if (action == _TaskContextAction.restore && mounted) {
      await _restoreTask(task);
    }
  }

  Future<void> _confirmDeleteTask(LifeOsTask task) async {
    _selectTask(task.id);
    final deleted = await showDialog<bool>(
      context: context,
      builder: (context) => _TaskDeleteDialog(
        task: task,
        onDelete: () =>
            ref.read(taskListControllerProvider.notifier).deleteTask(task.id),
      ),
    );
    if (!mounted) return;
    if (deleted == true) setState(() => _selectedTaskId = null);
    _featureFocusNode.requestFocus();
  }

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
      if (mounted) {
        setState(() => _isMutating = false);
        _featureFocusNode.requestFocus();
      }
    }
  }
}

enum _TaskContextAction {
  edit,
  toggleCompletion,
  relationships,
  moveToTrash,
  restore,
}

RelativeRect _menuPosition(BuildContext context, Offset globalPosition) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  return RelativeRect.fromRect(
    Rect.fromPoints(globalPosition, globalPosition),
    Offset.zero & overlay.size,
  );
}

class TaskCreationForm extends ConsumerStatefulWidget {
  const TaskCreationForm({this.titleFocusNode, super.key});

  final FocusNode? titleFocusNode;

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
            focusNode: widget.titleFocusNode,
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
      if (mounted) Navigator.of(context).pop(true);
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
