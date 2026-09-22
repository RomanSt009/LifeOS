import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lifeos_entity.dart';
import '../../l10n/app_localizations.dart';
import '../workspaces/workspace_providers.dart';

class HomePlaceholder extends ConsumerWidget {
  const HomePlaceholder({
    required this.onOpenWorkspace,
    required this.onNewWorkspace,
    required this.onUnassigned,
    required this.onNewTask,
    required this.onNewNote,
    required this.onSearch,
    required this.onSettings,
    super.key,
  });

  final ValueChanged<LifeOsEntityId> onOpenWorkspace;
  final VoidCallback onNewWorkspace;
  final VoidCallback onUnassigned;
  final VoidCallback onNewTask;
  final VoidCallback onNewNote;
  final VoidCallback onSearch;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final workspaces = ref.watch(workspaceListControllerProvider);
    return ListView(
      children: [
        Text(
          localizations.appTitle,
          key: const Key('home-placeholder-title'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          localizations.homeContextDescription,
          key: const Key('home-alpha-description'),
        ),
        const SizedBox(height: 24),
        Text(
          localizations.homeWorkspacesTitle,
          key: const Key('home-workspaces-title'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        workspaces.when(
          loading: () => const LinearProgressIndicator(
            key: Key('home-workspaces-loading'),
          ),
          error: (_, _) => Row(
            children: [
              Expanded(child: Text(localizations.workspaceLoadError)),
              TextButton.icon(
                key: const Key('home-retry-workspaces'),
                onPressed: () =>
                    ref.invalidate(workspaceListControllerProvider),
                icon: const Icon(Icons.refresh),
                label: Text(localizations.retryAction),
              ),
            ],
          ),
          data: (items) => items.isEmpty
              ? Text(localizations.homeWorkspacesEmpty)
              : Column(
                  children: [
                    for (final workspace in items)
                      Card(
                        child: ListTile(
                          key: ValueKey('home-workspace-${workspace.id.value}'),
                          leading: const Icon(Icons.workspaces_outline),
                          title: Text(workspace.title),
                          subtitle: workspace.description?.isNotEmpty == true
                              ? Text(
                                  workspace.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: Icon(
                            Icons.arrow_forward,
                            semanticLabel: localizations.workspaceOpenAction,
                          ),
                          onTap: () => onOpenWorkspace(workspace.id),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              key: const Key('home-new-workspace-action'),
              onPressed: onNewWorkspace,
              icon: const Icon(Icons.create_new_folder_outlined),
              label: Text(localizations.workspaceCreateAction),
            ),
            OutlinedButton.icon(
              key: const Key('home-unassigned-action'),
              onPressed: onUnassigned,
              icon: const Icon(Icons.inbox_outlined),
              label: Text(localizations.unassignedTitle),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          localizations.homeSecondaryActionsTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final actionWidth = constraints.maxWidth < 500
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _HomeQuickAction(
                  key: const Key('home-new-task-action'),
                  width: actionWidth,
                  icon: Icons.add_task,
                  label: localizations.homeNewTaskAction,
                  onPressed: onNewTask,
                ),
                _HomeQuickAction(
                  key: const Key('home-new-note-action'),
                  width: actionWidth,
                  icon: Icons.note_add_outlined,
                  label: localizations.homeNewNoteAction,
                  onPressed: onNewNote,
                ),
                _HomeQuickAction(
                  key: const Key('home-search-action'),
                  width: actionWidth,
                  icon: Icons.search,
                  label: localizations.homeSearchAction,
                  onPressed: onSearch,
                ),
                _HomeQuickAction(
                  key: const Key('home-settings-action'),
                  width: actionWidth,
                  icon: Icons.settings_outlined,
                  label: localizations.homeSettingsAction,
                  onPressed: onSettings,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _HomeQuickAction extends StatefulWidget {
  const _HomeQuickAction({
    required this.width,
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_HomeQuickAction> createState() => _HomeQuickActionState();
}

class _HomeQuickActionState extends State<_HomeQuickAction> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: FilledButton.tonalIcon(
        focusNode: _focusNode,
        onPressed: widget.onPressed,
        icon: Icon(widget.icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
