import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'task_list.dart';

class TaskPage extends StatelessWidget {
  const TaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.appTitle,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
    );
  }
}
