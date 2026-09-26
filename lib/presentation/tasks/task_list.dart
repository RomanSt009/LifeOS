import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_task.dart';
import '../navigation/lifeos_feature_command.dart';
import '../relationships/related_entities_section.dart';
import 'task_list_providers.dart';

class TaskList extends ConsumerStatefulWidget {
  const TaskList({
    this.featureCommand,
    this.onFeatureCommandHandled,
    this.onOpenTask,
    this.onOpenNote,
    super.key,
  });

  final LifeOsFeatureCommand? featureCommand;
  final ValueChanged<int>? onFeatureCommandHandled;
  final ValueChanged<LifeOsEntityId>? onOpenTask;
  final ValueChanged<LifeOsEntityId>? onOpenNote;

  @override
  ConsumerState<TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<TaskList> {
  final _featureFocusNode = FocusNode(debugLabel: 'Task feature actions');
  final _creationFocusNode = FocusNode(debugLabel: 'Task creation title');
  final _expansionControllers = <LifeOsEntityId, ExpansibleController>{};
  final _relationshipKeys = <LifeOsEntityId, GlobalKey>{};
  bool _showTrash = false;
  TaskCompletionFilter _completionFilter = TaskCompletionFilter.all;
  bool _isMutating = false;
  bool _restoreFailed = false;
  final _completionMutations = <LifeOsEntityId>{};
  LifeOsEntityId? _completionFailedTaskId;
  LifeOsEntityId? _selectedTaskId;
  int? _latestFeatureCommandId;

  @override
  void didUpdateWidget(covariant TaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final command = widget.featureCommand;
    if (command == null || command.id == oldWidget.featureCommand?.id) return;
    _latestFeatureCommandId = command.id;
    switch (command.type) {
      case LifeOsFeatureCommandType.newTask:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || widget.featureCommand?.id != command.id) return;
          widget.onFeatureCommandHandled?.call(command.id);
          setState(() {
            _showTrash = false;
            _selectedTaskId = null;
            _restoreFailed = false;
            _completionFailedTaskId = null;
          });
          _focusCreation();
        });
      case LifeOsFeatureCommandType.openTask:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _latestFeatureCommandId != command.id) return;
          _openTaskFromShell(command);
        });
      case LifeOsFeatureCommandType.newNote:
      case LifeOsFeatureCommandType.openNote:
      case LifeOsFeatureCommandType.newWorkspace:
      case LifeOsFeatureCommandType.openWorkspace:
      case LifeOsFeatureCommandType.openUnassigned:
        break;
    }
  }

  Future<void> _openTaskFromShell(LifeOsFeatureCommand command) async {
    widget.onFeatureCommandHandled?.call(command.id);
    LifeOsTask? target;
    try {
      final tasks = await ref.read(taskListControllerProvider.future);
      target = tasks.where((task) => task.id == command.entityId).firstOrNull;
    } catch (_) {
      target = null;
    }
    if (!mounted || _latestFeatureCommandId != command.id) return;
    setState(() {
      _showTrash = false;
      _completionFilter = TaskCompletionFilter.all;
      _selectedTaskId = target?.id;
      _restoreFailed = false;
      _completionFailedTaskId = null;
    });
    _featureFocusNode.requestFocus();
  }

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
    final task = ref
        .read(taskListControllerProvider)
        .asData
        ?.value
        .where((task) => task.id == selectedId)
        .firstOrNull;
    return task != null && _completionFilter.includes(task) ? task : null;
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
            child: IconButton(
              key: const Key('task-trash-toggle'),
              tooltip: _showTrash
                  ? localizations.backToTasksAction
                  : localizations.trashAction,
              onPressed: _isMutating
                  ? null
                  : () => setState(() {
                      _showTrash = !_showTrash;
                      _selectedTaskId = null;
                      _restoreFailed = false;
                      _completionFailedTaskId = null;
                    }),
              icon: Icon(
                _showTrash ? Icons.arrow_back : Icons.delete_outline,
                semanticLabel: _showTrash
                    ? localizations.backToTasksAction
                    : localizations.trashAction,
              ),
            ),
          ),
          if (!_showTrash) TaskCreationForm(titleFocusNode: _creationFocusNode),
          if (!_showTrash) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<TaskCompletionFilter>(
                key: const Key('task-completion-filter'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: TaskCompletionFilter.all,
                    label: Text(localizations.taskFilterAll),
                  ),
                  ButtonSegment(
                    value: TaskCompletionFilter.open,
                    label: Text(localizations.taskFilterOpen),
                  ),
                  ButtonSegment(
                    value: TaskCompletionFilter.completed,
                    label: Text(localizations.taskFilterCompleted),
                  ),
                ],
                selected: {_completionFilter},
                onSelectionChanged: _isMutating
                    ? null
                    : (selection) {
                        setState(() {
                          _completionFilter = selection.single;
                          _selectedTaskId = null;
                          _completionFailedTaskId = null;
                        });
                        _featureFocusNode.requestFocus();
                      },
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_restoreFailed)
            Text(
              localizations.taskRestoreError,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (!_showTrash && _completionFailedTaskId != null)
            Text(
              localizations.taskCompletionError,
              key: const Key('task-completion-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          Expanded(
            child: tasks.when(
              data: (tasks) {
                final visibleTasks = _showTrash
                    ? tasks
                    : tasks.where(_completionFilter.includes).toList();
                _reconcileSelection(visibleTasks);
                if (visibleTasks.isEmpty) {
                  return Center(
                    child: Text(
                      _showTrash
                          ? localizations.taskTrashEmpty
                          : switch (_completionFilter) {
                              TaskCompletionFilter.all =>
                                localizations.taskListEmpty,
                              TaskCompletionFilter.open =>
                                localizations.taskFilterOpenEmpty,
                              TaskCompletionFilter.completed =>
                                localizations.taskFilterCompletedEmpty,
                            },
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: visibleTasks.length,
                  itemBuilder: (context, index) {
                    final task = visibleTasks[index];
                    if (_showTrash) {
                      return GestureDetector(
                        onSecondaryTapDown: (details) =>
                            _showDeletedTaskMenu(task, details.globalPosition),
                        child: ListTile(
                          key: ValueKey('deleted-task-${task.id.value}'),
                          title: Text(task.title),
                          trailing: IconButton(
                            key: ValueKey('restore-task-${task.id.value}'),
                            tooltip: localizations.restoreTaskAction,
                            onPressed: _isMutating
                                ? null
                                : () => _restoreTask(task),
                            icon: Icon(
                              Icons.restore,
                              semanticLabel: localizations.restoreTaskAction,
                            ),
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
                          key: ValueKey('toggle-task-${task.id.value}'),
                          tooltip: task.isCompleted
                              ? localizations.taskCompletionMarkIncomplete
                              : localizations.taskCompletionMarkComplete,
                          icon: Icon(
                            task.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            semanticLabel: task.isCompleted
                                ? localizations.taskCompletionMarkIncomplete
                                : localizations.taskCompletionMarkComplete,
                          ),
                          onPressed: _completionMutations.contains(task.id)
                              ? null
                              : () => _toggleCompletion(task),
                        ),
                        title: Row(
                          children: [
                            Expanded(child: Text(task.title)),
                            IconButton(
                              key: ValueKey('edit-task-${task.id.value}'),
                              tooltip: localizations.taskEditAction,
                              icon: Icon(
                                Icons.edit_outlined,
                                semanticLabel: localizations.taskEditAction,
                              ),
                              onPressed:
                                  task.lifecycle == LifeOsEntityLifecycle.active
                                  ? () => _editTask(task)
                                  : null,
                            ),
                            IconButton(
                              key: ValueKey('delete-task-${task.id.value}'),
                              tooltip: localizations.deleteTaskAction,
                              icon: Icon(
                                Icons.delete_outline,
                                semanticLabel: localizations.deleteTaskAction,
                              ),
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
                            onOpenTask: widget.onOpenTask,
                            onOpenNote: widget.onOpenNote,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(localizations.taskLoadError),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      key: const Key('retry-task-list'),
                      onPressed: _retryLoad,
                      icon: const Icon(Icons.refresh),
                      label: Text(localizations.retryAction),
                    ),
                  ],
                ),
              ),
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
    if (_completionMutations.contains(task.id)) return;
    _selectTask(task.id);
    setState(() {
      _completionMutations.add(task.id);
      _completionFailedTaskId = null;
    });
    try {
      await ref
          .read(taskListControllerProvider.notifier)
          .toggleCompletion(task.id);
    } catch (_) {
      if (mounted) setState(() => _completionFailedTaskId = task.id);
    } finally {
      if (mounted) {
        setState(() => _completionMutations.remove(task.id));
        _featureFocusNode.requestFocus();
      }
    }
  }

  void _retryLoad() {
    ref.invalidate(
      _showTrash ? taskTrashControllerProvider : taskListControllerProvider,
    );
  }

  void _reconcileSelection(List<LifeOsTask> tasks) {
    final selectedId = _selectedTaskId;
    if (_showTrash ||
        selectedId == null ||
        tasks.any((task) => task.id == selectedId)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedTaskId == selectedId) {
        setState(() => _selectedTaskId = null);
      }
    });
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
          enabled: !_completionMutations.contains(task.id),
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
      _restoreFailed = false;
    });
    try {
      await ref.read(taskTrashControllerProvider.notifier).restoreTask(task.id);
    } catch (_) {
      if (mounted) setState(() => _restoreFailed = true);
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

enum TaskCompletionFilter {
  all,
  open,
  completed;

  bool includes(LifeOsTask task) => switch (this) {
    TaskCompletionFilter.all => true,
    TaskCompletionFilter.open => !task.isCompleted,
    TaskCompletionFilter.completed => task.isCompleted,
  };
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
