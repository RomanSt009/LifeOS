import 'package:flutter/material.dart';

import '../../domain/entities/lifeos_entity.dart';
import '../../l10n/app_localizations.dart';
import '../navigation/lifeos_feature_command.dart';
import 'task_list.dart';

class TaskPage extends StatelessWidget {
  const TaskPage({
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
          Expanded(
            child: TaskList(
              featureCommand: featureCommand,
              onFeatureCommandHandled: onFeatureCommandHandled,
              onOpenTask: onOpenTask,
              onOpenNote: onOpenNote,
            ),
          ),
        ],
      ),
    );
  }
}
