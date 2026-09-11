import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../home/home_placeholder.dart';
import '../navigation/lifeos_destination.dart';
import '../search/task_search_page.dart';
import '../settings/backup_settings_page.dart';
import '../tasks/task_page.dart';

class LifeosShellPage extends StatefulWidget {
  const LifeosShellPage({super.key});

  @override
  State<LifeosShellPage> createState() => _LifeosShellPageState();
}

class _LifeosShellPageState extends State<LifeosShellPage> {
  LifeOsDestination _selectedDestination = LifeOsDestination.tasks;

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
            onDestinationSelected: (index) {
              setState(() {
                _selectedDestination = LifeOsDestination.values[index];
              });
            },
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: Text(localizations.navigationHome),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.task_alt_outlined),
                selectedIcon: const Icon(Icons.task_alt),
                label: Text(localizations.navigationTasks),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.search_outlined),
                selectedIcon: const Icon(Icons.search),
                label: Text(localizations.navigationSearch),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: Text(localizations.navigationSettings),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedDestination.index,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: HomePlaceholder(),
                ),
                const TaskPage(),
                const TaskSearchPage(),
                const BackupSettingsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
