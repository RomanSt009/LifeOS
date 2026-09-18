import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({
    required this.onNewTask,
    required this.onNewNote,
    required this.onSearch,
    required this.onSettings,
    super.key,
  });

  final VoidCallback onNewTask;
  final VoidCallback onNewNote;
  final VoidCallback onSearch;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return ListView(
      children: [
        Text(
          localizations.appTitle,
          key: const Key('home-placeholder-title'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          localizations.homeAlphaDescription,
          key: const Key('home-alpha-description'),
        ),
        const SizedBox(height: 32),
        Text(
          localizations.homeQuickActionsTitle,
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
