import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/workspaces/lifeos_workspace_context_reader.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../domain/entities/lifeos_task.dart';
import '../../domain/entities/lifeos_workspace.dart';
import '../../l10n/app_localizations.dart';
import '../notes/note_providers.dart';
import '../tasks/task_list_providers.dart';
import 'workspace_member_refresh.dart';
import 'workspace_providers.dart';

class WorkspacePage extends ConsumerStatefulWidget {
  const WorkspacePage({super.key});

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  LifeOsEntityId? _selectedWorkspaceId;
  bool _showTrash = false;
  bool _restoreFailed = false;
  LifeOsEntityId? _restoringId;

  void _select(LifeOsEntityId id) {
    if (_selectedWorkspaceId != id) {
      setState(() => _selectedWorkspaceId = id);
    }
  }

  void _showActive() {
    setState(() {
      _showTrash = false;
      _restoreFailed = false;
      _selectedWorkspaceId = null;
    });
  }

  void _showDeleted() {
    setState(() {
      _showTrash = true;
      _restoreFailed = false;
      _selectedWorkspaceId = null;
    });
  }

  Future<void> _create() async {
    final created = await showDialog<LifeOsWorkspace>(
      context: context,
      builder: (context) => _WorkspaceFormDialog(
        onSave: ({required title, required description}) => ref
            .read(workspaceListControllerProvider.notifier)
            .create(title: title, description: description),
      ),
    );
    if (mounted && created != null) {
      setState(() {
        _showTrash = false;
        _selectedWorkspaceId = created.id;
      });
    }
  }

  Future<void> _edit(LifeOsWorkspace workspace) async {
    await showDialog<LifeOsWorkspace>(
      context: context,
      builder: (context) => _WorkspaceFormDialog(
        workspace: workspace,
        onSave: ({required title, required description}) => ref
            .read(workspaceListControllerProvider.notifier)
            .edit(workspace.id, title: title, description: description),
      ),
    );
  }

  Future<void> _delete(LifeOsWorkspace workspace) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (context) => _WorkspaceDeleteDialog(
        workspace: workspace,
        onDelete: () => ref
            .read(workspaceListControllerProvider.notifier)
            .delete(workspace.id),
      ),
    );
    if (mounted && deleted == true) {
      setState(() => _selectedWorkspaceId = null);
    }
  }

  Future<void> _restore(LifeOsWorkspace workspace) async {
    if (_restoringId != null) return;
    setState(() {
      _restoringId = workspace.id;
      _restoreFailed = false;
    });
    try {
      await ref
          .read(workspaceTrashControllerProvider.notifier)
          .restore(workspace.id);
    } catch (_) {
      if (mounted) setState(() => _restoreFailed = true);
    } finally {
      if (mounted) setState(() => _restoringId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final workspaces = ref.watch(
      _showTrash
          ? workspaceTrashControllerProvider
          : workspaceListControllerProvider,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Text(
                _showTrash
                    ? localizations.workspaceTrashTitle
                    : localizations.workspaceListTitle,
                key: const Key('workspace-page-title'),
                style: Theme.of(context).textTheme.headlineSmall,
              );
              final actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_showTrash)
                    FilledButton.icon(
                      key: const Key('new-workspace-action'),
                      onPressed: _create,
                      icon: const Icon(Icons.add),
                      label: Text(localizations.workspaceCreateAction),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('workspace-trash-toggle'),
                    tooltip: _showTrash
                        ? localizations.backToWorkspacesAction
                        : localizations.workspaceTrashTitle,
                    onPressed: _showTrash ? _showActive : _showDeleted,
                    icon: Icon(
                      _showTrash ? Icons.arrow_back : Icons.delete_outline,
                      semanticLabel: _showTrash
                          ? localizations.backToWorkspacesAction
                          : localizations.workspaceTrashTitle,
                    ),
                  ),
                ],
              );
              if (constraints.maxWidth < 620) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: actions),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  actions,
                ],
              );
            },
          ),
          if (_restoreFailed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                localizations.workspaceRestoreError,
                key: const Key('workspace-restore-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: workspaces.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _WorkspaceLoadError(
                onRetry: () => ref.invalidate(
                  _showTrash
                      ? workspaceTrashControllerProvider
                      : workspaceListControllerProvider,
                ),
              ),
              data: (items) => _workspaceContent(items, localizations),
            ),
          ),
        ],
      ),
    );
  }

  Widget _workspaceContent(
    List<LifeOsWorkspace> workspaces,
    AppLocalizations localizations,
  ) {
    if (_showTrash) {
      if (workspaces.isEmpty) {
        return Center(child: Text(localizations.workspaceTrashEmpty));
      }
      return ListView.builder(
        key: const Key('workspace-trash-list'),
        itemCount: workspaces.length,
        itemBuilder: (context, index) {
          final workspace = workspaces[index];
          return ListTile(
            key: ValueKey('deleted-workspace-${workspace.id.value}'),
            leading: const Icon(Icons.workspaces_outline),
            title: Text(workspace.title),
            subtitle: _descriptionPreview(workspace.description),
            trailing: IconButton(
              key: ValueKey('restore-workspace-${workspace.id.value}'),
              tooltip: localizations.workspaceRestoreAction,
              onPressed: _restoringId == null
                  ? () => _restore(workspace)
                  : null,
              icon: Icon(
                Icons.restore,
                semanticLabel: localizations.workspaceRestoreAction,
              ),
            ),
          );
        },
      );
    }

    _reconcileSelection(workspaces);
    if (workspaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizations.workspaceListEmpty),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: Text(localizations.workspaceCreateAction),
            ),
          ],
        ),
      );
    }

    final selected = workspaces
        .where((workspace) => workspace.id == _selectedWorkspaceId)
        .firstOrNull;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 300,
                child: _WorkspaceList(
                  workspaces: workspaces,
                  selectedId: _selectedWorkspaceId,
                  onSelect: _select,
                  onEdit: _edit,
                  onDelete: _delete,
                ),
              ),
              const VerticalDivider(width: 25),
              Expanded(
                child: selected == null
                    ? Center(child: Text(localizations.workspaceSelectPrompt))
                    : _WorkspaceDetail(
                        key: ValueKey('workspace-detail-${selected.id.value}'),
                        workspace: selected,
                        onEdit: () => _edit(selected),
                        onDelete: () => _delete(selected),
                      ),
              ),
            ],
          );
        }

        if (selected != null) {
          return _WorkspaceDetail(
            key: ValueKey('workspace-detail-${selected.id.value}'),
            workspace: selected,
            onBack: () => setState(() => _selectedWorkspaceId = null),
            onEdit: () => _edit(selected),
            onDelete: () => _delete(selected),
          );
        }
        return _WorkspaceList(
          workspaces: workspaces,
          selectedId: null,
          onSelect: _select,
          onEdit: _edit,
          onDelete: _delete,
        );
      },
    );
  }

  Widget? _descriptionPreview(String? description) {
    if (description == null || description.isEmpty) return null;
    return Text(description, maxLines: 2, overflow: TextOverflow.ellipsis);
  }

  void _reconcileSelection(List<LifeOsWorkspace> workspaces) {
    final selectedId = _selectedWorkspaceId;
    if (selectedId == null || workspaces.any((item) => item.id == selectedId)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedWorkspaceId == selectedId) {
        setState(() => _selectedWorkspaceId = null);
      }
    });
  }
}

class _WorkspaceLoadError extends StatelessWidget {
  const _WorkspaceLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(localizations.workspaceLoadError),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('retry-workspaces'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(localizations.retryAction),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceList extends StatelessWidget {
  const _WorkspaceList({
    required this.workspaces,
    required this.selectedId,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final List<LifeOsWorkspace> workspaces;
  final LifeOsEntityId? selectedId;
  final ValueChanged<LifeOsEntityId> onSelect;
  final ValueChanged<LifeOsWorkspace> onEdit;
  final ValueChanged<LifeOsWorkspace> onDelete;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return ListView.builder(
      key: const Key('workspace-list'),
      itemCount: workspaces.length,
      itemBuilder: (context, index) {
        final workspace = workspaces[index];
        return ListTile(
          key: ValueKey('workspace-${workspace.id.value}'),
          selected: workspace.id == selectedId,
          leading: const Icon(Icons.workspaces_outline),
          title: Text(workspace.title),
          subtitle:
              workspace.description == null || workspace.description!.isEmpty
              ? null
              : Text(
                  workspace.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          onTap: () => onSelect(workspace.id),
          trailing: PopupMenuButton<_WorkspaceListAction>(
            tooltip: localizations.workspaceActionsTooltip,
            onSelected: (action) => switch (action) {
              _WorkspaceListAction.edit => onEdit(workspace),
              _WorkspaceListAction.delete => onDelete(workspace),
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _WorkspaceListAction.edit,
                child: Text(localizations.workspaceEditAction),
              ),
              PopupMenuItem(
                value: _WorkspaceListAction.delete,
                child: Text(localizations.workspaceMoveToTrashAction),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _WorkspaceListAction { edit, delete }

class _WorkspaceDetail extends ConsumerWidget {
  const _WorkspaceDetail({
    required this.workspace,
    required this.onEdit,
    required this.onDelete,
    this.onBack,
    super.key,
  });

  final LifeOsWorkspace workspace;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final members = ref.watch(workspaceMembersProvider(workspace.id));
    return ListView(
      key: const Key('workspace-detail-scroll'),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBack != null)
              IconButton(
                key: const Key('back-to-workspace-list'),
                tooltip: localizations.backToWorkspacesAction,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workspace.title,
                    key: const Key('workspace-detail-title'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    workspace.description?.isNotEmpty == true
                        ? workspace.description!
                        : localizations.workspaceNoDescription,
                    key: const Key('workspace-detail-description'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('edit-workspace-action'),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: Text(localizations.workspaceEditAction),
            ),
            OutlinedButton.icon(
              key: const Key('delete-workspace-action'),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: Text(localizations.workspaceMoveToTrashAction),
            ),
            FilledButton.tonalIcon(
              key: const Key('workspace-add-task-action'),
              onPressed: () => _showTaskCreation(context, ref),
              icon: const Icon(Icons.add_task),
              label: Text(localizations.workspaceAddTaskAction),
            ),
            FilledButton.tonalIcon(
              key: const Key('workspace-add-note-action'),
              onPressed: () => _showNoteCreation(context, ref),
              icon: const Icon(Icons.note_add_outlined),
              label: Text(localizations.workspaceAddNoteAction),
            ),
            FilledButton.tonalIcon(
              key: const Key('workspace-attach-action'),
              onPressed: members.hasValue
                  ? () => _showAttach(context, ref, members.requireValue)
                  : null,
              icon: const Icon(Icons.add_link),
              label: Text(localizations.workspaceAttachExistingAction),
            ),
          ],
        ),
        const SizedBox(height: 20),
        members.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => _WorkspaceMembersError(
            onRetry: () =>
                ref.invalidate(workspaceMembersProvider(workspace.id)),
          ),
          data: (items) =>
              _WorkspaceMembers(workspaceId: workspace.id, members: items),
        ),
      ],
    );
  }

  Future<void> _showTaskCreation(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _TaskInWorkspaceDialog(workspaceId: workspace.id),
    );
  }

  Future<void> _showNoteCreation(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _NoteInWorkspaceDialog(workspaceId: workspace.id),
    );
  }

  Future<void> _showAttach(
    BuildContext context,
    WidgetRef ref,
    List<LifeOsWorkspaceMember> members,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _AttachWorkspaceMemberDialog(
        workspaceId: workspace.id,
        attachedIds: {for (final member in members) member.entityId},
      ),
    );
  }
}

class _WorkspaceMembersError extends StatelessWidget {
  const _WorkspaceMembersError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(localizations.workspaceMembersLoadError),
        TextButton.icon(
          key: const Key('retry-workspace-members'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(localizations.retryAction),
        ),
      ],
    );
  }
}

class _WorkspaceMembers extends ConsumerWidget {
  const _WorkspaceMembers({required this.workspaceId, required this.members});

  final LifeOsEntityId workspaceId;
  final List<LifeOsWorkspaceMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = members.whereType<LifeOsWorkspaceTaskMember>().toList();
    final notes = members.whereType<LifeOsWorkspaceNoteMember>().toList();
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          localizations.navigationTasks,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        if (tasks.isEmpty)
          Text(localizations.workspaceTasksEmpty)
        else
          for (final member in tasks)
            _WorkspaceMemberTile(
              key: ValueKey('workspace-task-${member.task.id.value}'),
              icon: member.task.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              title: member.task.title,
              completed: member.task.isCompleted,
              onDetach: member.membershipId == null
                  ? null
                  : () => _detach(context, ref, member.membershipId!),
            ),
        const SizedBox(height: 16),
        Text(
          localizations.navigationNotes,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        if (notes.isEmpty)
          Text(localizations.workspaceNotesEmpty)
        else
          for (final member in notes)
            _WorkspaceMemberTile(
              key: ValueKey('workspace-note-${member.note.id.value}'),
              icon: Icons.notes_outlined,
              title: member.note.title.isEmpty
                  ? localizations.noteUntitled
                  : member.note.title,
              onDetach: member.membershipId == null
                  ? null
                  : () => _detach(context, ref, member.membershipId!),
            ),
      ],
    );
  }

  Future<void> _detach(
    BuildContext context,
    WidgetRef ref,
    LifeOsEntityId membershipId,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _DetachWorkspaceMemberDialog(
        workspaceId: workspaceId,
        membershipId: membershipId,
      ),
    );
  }
}

class _WorkspaceMemberTile extends StatelessWidget {
  const _WorkspaceMemberTile({
    required this.icon,
    required this.title,
    required this.onDetach,
    this.completed = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final bool completed;
  final VoidCallback? onDetach;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(
        title,
        style: completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      trailing: TextButton.icon(
        onPressed: onDetach,
        icon: const Icon(Icons.link_off),
        label: Text(localizations.workspaceDetachAction),
      ),
    );
  }
}

typedef _SaveWorkspace = Future<LifeOsWorkspace> Function({
  required String title,
  required String? description,
});

class _WorkspaceFormDialog extends StatefulWidget {
  const _WorkspaceFormDialog({required this.onSave, this.workspace});

  final LifeOsWorkspace? workspace;
  final _SaveWorkspace onSave;

  @override
  State<_WorkspaceFormDialog> createState() => _WorkspaceFormDialogState();
}

class _WorkspaceFormDialogState extends State<_WorkspaceFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _titleFocusNode = FocusNode();
  bool _saving = false;
  bool _failed = false;
  bool _titleMissing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.workspace?.title);
    _descriptionController = TextEditingController(
      text: widget.workspace?.description,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final title = _titleController.text;
    if (title.trim().isEmpty) {
      setState(() => _titleMissing = true);
      _titleFocusNode.requestFocus();
      return;
    }
    setState(() {
      _saving = true;
      _failed = false;
      _titleMissing = false;
    });
    final rawDescription = _descriptionController.text;
    final description =
        rawDescription.isEmpty && widget.workspace?.description == null
        ? null
        : rawDescription;
    try {
      final workspace = await widget.onSave(
        title: title,
        description: description,
      );
      if (mounted) Navigator.of(context).pop(workspace);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        title: Text(
          widget.workspace == null
              ? localizations.workspaceCreateAction
              : localizations.workspaceEditAction,
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('workspace-title-field'),
                controller: _titleController,
                focusNode: _titleFocusNode,
                autofocus: true,
                enabled: !_saving,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: localizations.workspaceTitleFieldLabel,
                  errorText: _titleMissing
                      ? localizations.workspaceTitleRequired
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('workspace-description-field'),
                controller: _descriptionController,
                enabled: !_saving,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: localizations.workspaceDescriptionFieldLabel,
                ),
              ),
              if (_failed) ...[
                const SizedBox(height: 8),
                Text(
                  localizations.workspaceSaveError,
                  key: const Key('workspace-save-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(localizations.cancelAction),
          ),
          FilledButton(
            key: const Key('save-workspace-action'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(localizations.taskSaveAction),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceDeleteDialog extends StatefulWidget {
  const _WorkspaceDeleteDialog({
    required this.workspace,
    required this.onDelete,
  });

  final LifeOsWorkspace workspace;
  final Future<void> Function() onDelete;

  @override
  State<_WorkspaceDeleteDialog> createState() => _WorkspaceDeleteDialogState();
}

class _WorkspaceDeleteDialogState extends State<_WorkspaceDeleteDialog> {
  bool _deleting = false;
  bool _failed = false;

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _failed = false;
    });
    try {
      await widget.onDelete();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PopScope(
      canPop: !_deleting,
      child: AlertDialog(
        title: Text(localizations.workspaceDeleteDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.workspaceMoveToTrashConfirmation(
                widget.workspace.title,
              ),
            ),
            if (_failed) ...[
              const SizedBox(height: 8),
              Text(
                localizations.workspaceDeleteError,
                key: const Key('workspace-delete-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _deleting
                ? null
                : () => Navigator.of(context).pop(false),
            child: Text(localizations.cancelAction),
          ),
          FilledButton(
            key: const Key('confirm-delete-workspace'),
            onPressed: _deleting ? null : _delete,
            child: Text(localizations.workspaceMoveToTrashAction),
          ),
        ],
      ),
    );
  }
}

class _TaskInWorkspaceDialog extends ConsumerStatefulWidget {
  const _TaskInWorkspaceDialog({required this.workspaceId});

  final LifeOsEntityId workspaceId;

  @override
  ConsumerState<_TaskInWorkspaceDialog> createState() =>
      _TaskInWorkspaceDialogState();
}

class _TaskInWorkspaceDialogState
    extends ConsumerState<_TaskInWorkspaceDialog> {
  final _controller = TextEditingController();
  bool _saving = false;
  bool _missing = false;
  bool _failed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_controller.text.trim().isEmpty) {
      setState(() => _missing = true);
      return;
    }
    setState(() {
      _saving = true;
      _missing = false;
      _failed = false;
    });
    try {
      await ref.read(createLifeOsTaskInWorkspaceProvider)(
        workspaceId: widget.workspaceId,
        title: _controller.text,
      );
      ref.invalidate(taskListControllerProvider);
      ref.read(workspaceMemberRevisionProvider.notifier).advance();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return _SimpleCreationDialog(
      title: localizations.workspaceAddTaskAction,
      saving: _saving,
      failed: _failed,
      errorText: localizations.workspaceTaskCreateError,
      onCancel: () => Navigator.of(context).pop(),
      onSave: _save,
      child: TextField(
        key: const Key('workspace-task-title-field'),
        controller: _controller,
        autofocus: true,
        enabled: !_saving,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: localizations.taskTitleFieldLabel,
          errorText: _missing ? localizations.taskTitleRequired : null,
        ),
      ),
    );
  }
}

class _NoteInWorkspaceDialog extends ConsumerStatefulWidget {
  const _NoteInWorkspaceDialog({required this.workspaceId});

  final LifeOsEntityId workspaceId;

  @override
  ConsumerState<_NoteInWorkspaceDialog> createState() =>
      _NoteInWorkspaceDialogState();
}

class _NoteInWorkspaceDialogState
    extends ConsumerState<_NoteInWorkspaceDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _saving = false;
  bool _missing = false;
  bool _failed = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.isEmpty) {
      setState(() => _missing = true);
      return;
    }
    setState(() {
      _saving = true;
      _missing = false;
      _failed = false;
    });
    try {
      await ref.read(createLifeOsNoteInWorkspaceProvider)(
        workspaceId: widget.workspaceId,
        title: _titleController.text,
        content: _contentController.text,
      );
      ref.invalidate(noteListControllerProvider);
      ref.read(workspaceMemberRevisionProvider.notifier).advance();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return _SimpleCreationDialog(
      title: localizations.workspaceAddNoteAction,
      saving: _saving,
      failed: _failed,
      errorText: localizations.workspaceNoteCreateError,
      onCancel: () => Navigator.of(context).pop(),
      onSave: _save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('workspace-note-title-field'),
            controller: _titleController,
            autofocus: true,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: localizations.noteTitleFieldLabel,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('workspace-note-content-field'),
            controller: _contentController,
            enabled: !_saving,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: localizations.noteContentFieldLabel,
              errorText: _missing ? localizations.noteContentRequired : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleCreationDialog extends StatelessWidget {
  const _SimpleCreationDialog({
    required this.title,
    required this.saving,
    required this.failed,
    required this.errorText,
    required this.onCancel,
    required this.onSave,
    required this.child,
  });

  final String title;
  final bool saving;
  final bool failed;
  final String errorText;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PopScope(
      canPop: !saving,
      child: AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              child,
              if (failed) ...[
                const SizedBox(height: 8),
                Text(
                  errorText,
                  key: const Key('workspace-member-create-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : onCancel,
            child: Text(localizations.cancelAction),
          ),
          FilledButton(
            key: const Key('confirm-workspace-member-create'),
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(localizations.taskSaveAction),
          ),
        ],
      ),
    );
  }
}

class _AttachWorkspaceMemberDialog extends ConsumerStatefulWidget {
  const _AttachWorkspaceMemberDialog({
    required this.workspaceId,
    required this.attachedIds,
  });

  final LifeOsEntityId workspaceId;
  final Set<LifeOsEntityId> attachedIds;

  @override
  ConsumerState<_AttachWorkspaceMemberDialog> createState() =>
      _AttachWorkspaceMemberDialogState();
}

class _AttachWorkspaceMemberDialogState
    extends ConsumerState<_AttachWorkspaceMemberDialog> {
  Future<List<_AttachChoice>>? _choices;
  LifeOsEntityId? _attachingId;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _choices ??= _loadChoices();
  }

  Future<List<_AttachChoice>> _loadChoices() async {
    final untitledNote = AppLocalizations.of(context).noteUntitled;
    final results = await Future.wait([
      ref.read(getLifeOsTasksProvider)(),
      ref.read(getLifeOsNotesProvider)(),
    ]);
    final tasks = results[0] as List<LifeOsTask>;
    final notes = results[1] as List<LifeOsNote>;
    return [
      for (final task in tasks)
        if (!widget.attachedIds.contains(task.id))
          _AttachChoice(task.id, task.title, Icons.task_alt_outlined),
      for (final note in notes)
        if (!widget.attachedIds.contains(note.id))
          _AttachChoice(
            note.id,
            note.title.isEmpty ? untitledNote : note.title,
            Icons.notes_outlined,
          ),
    ];
  }

  void _retry() {
    setState(() {
      _failed = false;
      _choices = _loadChoices();
    });
  }

  Future<void> _attach(_AttachChoice choice) async {
    if (_attachingId != null) return;
    setState(() {
      _attachingId = choice.id;
      _failed = false;
    });
    try {
      await ref.read(attachLifeOsWorkspaceMemberProvider)(
        workspaceId: widget.workspaceId,
        memberEntityId: choice.id,
      );
      ref.read(workspaceMemberRevisionProvider.notifier).advance();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _attachingId = null;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(localizations.workspaceAttachPickerTitle),
      content: SizedBox(
        width: 480,
        height: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FutureBuilder<List<_AttachChoice>>(
                future: _choices,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: TextButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: Text(localizations.retryAction),
                      ),
                    );
                  }
                  final choices = snapshot.data!;
                  if (choices.isEmpty) {
                    return Center(
                      child: Text(localizations.workspaceAttachPickerEmpty),
                    );
                  }
                  return ListView.builder(
                    key: const Key('workspace-attach-choices'),
                    itemCount: choices.length,
                    itemBuilder: (context, index) {
                      final choice = choices[index];
                      return ListTile(
                        key: ValueKey(
                          'attach-${choice.id.entityType.name}-${choice.id.value}',
                        ),
                        leading: Icon(choice.icon),
                        title: Text(choice.title),
                        enabled: _attachingId == null,
                        onTap: () => _attach(choice),
                      );
                    },
                  );
                },
              ),
            ),
            if (_failed)
              Text(
                localizations.workspaceAttachError,
                key: const Key('workspace-attach-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _attachingId == null
              ? () => Navigator.of(context).pop()
              : null,
          child: Text(localizations.cancelAction),
        ),
      ],
    );
  }
}

class _DetachWorkspaceMemberDialog extends ConsumerStatefulWidget {
  const _DetachWorkspaceMemberDialog({
    required this.workspaceId,
    required this.membershipId,
  });

  final LifeOsEntityId workspaceId;
  final LifeOsEntityId membershipId;

  @override
  ConsumerState<_DetachWorkspaceMemberDialog> createState() =>
      _DetachWorkspaceMemberDialogState();
}

class _DetachWorkspaceMemberDialogState
    extends ConsumerState<_DetachWorkspaceMemberDialog> {
  bool _detaching = false;
  bool _failed = false;

  Future<void> _detach() async {
    if (_detaching) return;
    setState(() {
      _detaching = true;
      _failed = false;
    });
    try {
      final membership = await ref.read(detachLifeOsWorkspaceMemberProvider)(
        widget.membershipId,
      );
      if (membership == null) {
        throw StateError('The selected membership no longer exists.');
      }
      ref.read(workspaceMemberRevisionProvider.notifier).advance();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _detaching = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PopScope(
      canPop: !_detaching,
      child: AlertDialog(
        title: Text(localizations.workspaceDetachDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.workspaceDetachDialogMessage),
            if (_failed) ...[
              const SizedBox(height: 8),
              Text(
                localizations.workspaceDetachError,
                key: const Key('workspace-detach-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _detaching ? null : () => Navigator.of(context).pop(),
            child: Text(localizations.cancelAction),
          ),
          FilledButton(
            key: const Key('confirm-workspace-detach'),
            onPressed: _detaching ? null : _detach,
            child: Text(localizations.workspaceDetachAction),
          ),
        ],
      ),
    );
  }
}

final class _AttachChoice {
  const _AttachChoice(this.id, this.title, this.icon);

  final LifeOsEntityId id;
  final String title;
  final IconData icon;
}
