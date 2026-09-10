import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../home/home_placeholder.dart';
import '../navigation/lifeos_destination.dart';
import '../tasks/task_list.dart';

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
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.appTitle,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(localizations.appDescription),
                      const SizedBox(height: 24),
                      Text(
                        localizations.taskListTitle,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 8),
                      const Expanded(child: TaskList()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
