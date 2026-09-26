import 'package:flutter/material.dart';

import '../../domain/entities/lifeos_entity.dart';
import '../../l10n/app_localizations.dart';
import '../home/home_placeholder.dart';
import '../navigation/lifeos_destination.dart';
import '../navigation/lifeos_feature_command.dart';
import '../notes/note_page.dart';
import '../search/unified_search_page.dart';
import '../settings/backup_settings_page.dart';
import '../tasks/task_page.dart';
import '../workspaces/workspace_page.dart';

class LifeosShellPage extends StatefulWidget {
  const LifeosShellPage({super.key});

  @override
  State<LifeosShellPage> createState() => LifeosShellPageState();
}

class LifeosShellPageState extends State<LifeosShellPage> {
  LifeOsDestination _selectedDestination = LifeOsDestination.home;
  LifeOsFeatureCommand? _featureCommand;
  int _nextFeatureCommandId = 0;

  void _selectDestination(LifeOsDestination destination) {
    setState(() => _selectedDestination = destination);
  }

  void _issueFeatureCommand(
    LifeOsDestination destination,
    LifeOsFeatureCommandType type,
  ) {
    setState(() {
      _selectedDestination = destination;
      _featureCommand = LifeOsFeatureCommand(
        id: ++_nextFeatureCommandId,
        type: type,
      );
    });
  }

  void openTask(LifeOsEntityId taskId) {
    final nextId = _nextFeatureCommandId + 1;
    final command = LifeOsFeatureCommand.openTask(id: nextId, taskId: taskId);
    setState(() {
      _selectedDestination = LifeOsDestination.tasks;
      _nextFeatureCommandId = nextId;
      _featureCommand = command;
    });
  }

  void openNote(LifeOsEntityId noteId) {
    final nextId = _nextFeatureCommandId + 1;
    final command = LifeOsFeatureCommand.openNote(id: nextId, noteId: noteId);
    setState(() {
      _selectedDestination = LifeOsDestination.notes;
      _nextFeatureCommandId = nextId;
      _featureCommand = command;
    });
  }

  void openWorkspace(LifeOsEntityId workspaceId) {
    final nextId = _nextFeatureCommandId + 1;
    final command = LifeOsFeatureCommand.openWorkspace(
      id: nextId,
      workspaceId: workspaceId,
    );
    setState(() {
      _selectedDestination = LifeOsDestination.workspaces;
      _nextFeatureCommandId = nextId;
      _featureCommand = command;
    });
  }

  void _featureCommandHandled(int id) {
    if (_featureCommand?.id == id) setState(() => _featureCommand = null);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.appTitle)),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedDestination.index,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) =>
                _selectDestination(LifeOsDestination.values[index]),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: Text(
                  localizations.navigationHome,
                  key: const Key('navigation-home-label'),
                ),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.workspaces_outline),
                selectedIcon: const Icon(Icons.workspaces),
                label: Text(
                  localizations.navigationWorkspaces,
                  key: const Key('navigation-workspaces-label'),
                ),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.task_alt_outlined),
                selectedIcon: const Icon(Icons.task_alt),
                label: Text(
                  localizations.navigationTasks,
                  key: const Key('navigation-tasks-label'),
                ),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.notes_outlined),
                selectedIcon: const Icon(Icons.notes),
                label: Text(
                  localizations.navigationNotes,
                  key: const Key('navigation-notes-label'),
                ),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.search_outlined),
                selectedIcon: const Icon(Icons.search),
                label: Text(
                  localizations.navigationSearch,
                  key: const Key('navigation-search-label'),
                ),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(
                  localizations.navigationSettings,
                  key: const Key('navigation-settings-label'),
                ),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedDestination.index,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: HomePlaceholder(
                    onOpenWorkspace: openWorkspace,
                    onNewWorkspace: () => _issueFeatureCommand(
                      LifeOsDestination.workspaces,
                      LifeOsFeatureCommandType.newWorkspace,
                    ),
                    onUnassigned: () => _issueFeatureCommand(
                      LifeOsDestination.workspaces,
                      LifeOsFeatureCommandType.openUnassigned,
                    ),
                    onNewTask: () => _issueFeatureCommand(
                      LifeOsDestination.tasks,
                      LifeOsFeatureCommandType.newTask,
                    ),
                    onNewNote: () => _issueFeatureCommand(
                      LifeOsDestination.notes,
                      LifeOsFeatureCommandType.newNote,
                    ),
                    onSearch: () =>
                        _selectDestination(LifeOsDestination.search),
                    onSettings: () =>
                        _selectDestination(LifeOsDestination.settings),
                  ),
                ),
                WorkspacePage(
                  featureCommand: _featureCommand,
                  onFeatureCommandHandled: _featureCommandHandled,
                ),
                TaskPage(
                  featureCommand: _featureCommand,
                  onFeatureCommandHandled: _featureCommandHandled,
                  onOpenTask: openTask,
                  onOpenNote: openNote,
                ),
                NotePage(
                  featureCommand: _featureCommand,
                  onFeatureCommandHandled: _featureCommandHandled,
                  onOpenTask: openTask,
                  onOpenNote: openNote,
                ),
                UnifiedSearchPage(
                  onOpenTask: openTask,
                  onOpenNote: openNote,
                  onOpenWorkspace: openWorkspace,
                ),
                const BackupSettingsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
