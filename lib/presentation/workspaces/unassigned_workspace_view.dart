import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/workspaces/lifeos_workspace_context_reader.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_workspace.dart';
import '../../l10n/app_localizations.dart';
import 'workspace_member_refresh.dart';
import 'workspace_providers.dart';

class UnassignedWorkspaceView extends ConsumerWidget {
  const UnassignedWorkspaceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final members = ref.watch(unassignedWorkspaceMembersProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(localizations.unassignedDescription),
        const SizedBox(height: 12),
        Expanded(
          child: members.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(localizations.unassignedLoadError),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: const Key('retry-unassigned'),
                    onPressed: () =>
                        ref.invalidate(unassignedWorkspaceMembersProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(localizations.retryAction),
                  ),
                ],
              ),
            ),
            data: (items) => items.isEmpty
                ? Center(child: Text(localizations.unassignedEmpty))
                : ListView.builder(
                    key: const Key('unassigned-list'),
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _UnassignedTile(member: items[index]),
                  ),
          ),
        ),
      ],
    );
  }
}

class _UnassignedTile extends ConsumerWidget {
  const _UnassignedTile({required this.member});

  final LifeOsWorkspaceMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final (icon, title, completed) = switch (member) {
      LifeOsWorkspaceTaskMember(:final task) => (
        task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        task.title,
        task.isCompleted,
      ),
      LifeOsWorkspaceNoteMember(:final note) => (
        Icons.notes_outlined,
        note.title.isEmpty ? localizations.noteUntitled : note.title,
        false,
      ),
    };
    return ListTile(
      key: ValueKey(
        'unassigned-${member.entityId.entityType.name}-${member.entityId.value}',
      ),
      leading: Icon(icon),
      title: Text(
        title,
        style: completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(
        member is LifeOsWorkspaceTaskMember
            ? localizations.navigationTasks
            : localizations.navigationNotes,
      ),
      trailing: TextButton.icon(
        key: ValueKey(
          'assign-${member.entityId.entityType.name}-${member.entityId.value}',
        ),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) =>
              _AssignWorkspaceDialog(memberId: member.entityId),
        ),
        icon: const Icon(Icons.add_link),
        label: Text(localizations.assignToWorkspaceAction),
      ),
    );
  }
}

class _AssignWorkspaceDialog extends ConsumerStatefulWidget {
  const _AssignWorkspaceDialog({required this.memberId});

  final LifeOsEntityId memberId;

  @override
  ConsumerState<_AssignWorkspaceDialog> createState() =>
      _AssignWorkspaceDialogState();
}

class _AssignWorkspaceDialogState
    extends ConsumerState<_AssignWorkspaceDialog> {
  Future<List<LifeOsWorkspace>>? _workspaces;
  LifeOsEntityId? _assigningId;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _workspaces ??= ref.read(getLifeOsWorkspacesProvider)();
  }

  void _retryLoad() {
    setState(() {
      _failed = false;
      _workspaces = ref.read(getLifeOsWorkspacesProvider)();
    });
  }

  Future<void> _assign(LifeOsWorkspace workspace) async {
    if (_assigningId != null) return;
    setState(() {
      _assigningId = workspace.id;
      _failed = false;
    });
    try {
      await ref.read(attachLifeOsWorkspaceMemberProvider)(
        workspaceId: workspace.id,
        memberEntityId: widget.memberId,
      );
      ref.read(workspaceMemberRevisionProvider.notifier).advance();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _assigningId = null;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PopScope(
      canPop: _assigningId == null,
      child: AlertDialog(
        title: Text(localizations.assignToWorkspaceAction),
        content: SizedBox(
          width: 440,
          height: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: FutureBuilder<List<LifeOsWorkspace>>(
                  future: _workspaces,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: TextButton.icon(
                          key: const Key('retry-assignment-workspaces'),
                          onPressed: _retryLoad,
                          icon: const Icon(Icons.refresh),
                          label: Text(localizations.retryAction),
                        ),
                      );
                    }
                    final workspaces = snapshot.data!;
                    if (workspaces.isEmpty) {
                      return Center(
                        child: Text(localizations.assignWorkspaceEmpty),
                      );
                    }
                    return ListView.builder(
                      key: const Key('assignment-workspace-list'),
                      itemCount: workspaces.length,
                      itemBuilder: (context, index) {
                        final workspace = workspaces[index];
                        return ListTile(
                          key: ValueKey('assign-to-${workspace.id.value}'),
                          leading: const Icon(Icons.workspaces_outline),
                          title: Text(workspace.title),
                          enabled: _assigningId == null,
                          onTap: () => _assign(workspace),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_failed)
                Text(
                  localizations.assignWorkspaceError,
                  key: const Key('assign-workspace-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _assigningId == null
                ? () => Navigator.of(context).pop()
                : null,
            child: Text(localizations.cancelAction),
          ),
        ],
      ),
    );
  }
}
