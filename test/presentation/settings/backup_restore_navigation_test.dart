import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/backup/lifeos_backup_operations.dart';
import 'package:lifeos/application/use_cases/create_lifeos_task.dart';
import 'package:lifeos/application/use_cases/search_lifeos_tasks.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/search/task_search_providers.dart';
import 'package:lifeos/presentation/settings/backup_settings_providers.dart';
import 'package:lifeos/presentation/settings/lifeos_artifact_file_chooser.dart';
import 'package:lifeos/presentation/shell/lifeos_shell_page.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';
import 'package:lifeos/presentation/tasks/task_list_providers.dart';

void main() {
  testWidgets(
    'Restore refreshes Tasks and subsequent Search uses restored state',
    (tester) async {
      final oldTask = LifeOsTask.createUserTask(
        id: const LifeOsEntityId(
          value: 'old-task',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Old local Task',
        timestamp: DateTime.utc(2026, 9, 10),
      );
      final restoredTask = LifeOsTask.createUserTask(
        id: const LifeOsEntityId(
          value: 'restored-task',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Restored searchable Task',
        timestamp: DateTime.utc(2026, 9, 11),
      );
      final repository = MutableTaskRepository([oldTask]);
      final operations = RestoreReplacingOperations(
        repository: repository,
        restoredTasks: [restoredTask],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lifeOsTaskRepositoryProvider.overrideWithValue(repository),
            createLifeOsTaskProvider.overrideWithValue(
              CreateLifeOsTask(
                repository: repository,
                entityIdGenerator: () => 'unused-id',
                utcClock: () => DateTime.utc(2026, 9, 11),
              ),
            ),
            searchLifeOsTasksProvider.overrideWithValue(
              SearchLifeOsTasks(repository),
            ),
            lifeOsBackupOperationsProvider.overrideWithValue(operations),
            lifeOsArtifactFileChooserProvider.overrideWithValue(
              const RestoreFileChooser(),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LifeosShellPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Old local Task'), findsOneWidget);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore-backup-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('restore-confirmation-confirm')));
      await tester.pumpAndSettle();
      expect(operations.confirmations, [false, true]);

      await tester.tap(find.text('Tasks'));
      await tester.pumpAndSettle();
      expect(find.text('Old local Task'), findsNothing);
      expect(find.text('Restored searchable Task'), findsOneWidget);

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('search-query-field')),
        'searchable',
      );
      await tester.tap(find.byKey(const Key('search-submit-button')));
      await tester.pumpAndSettle();
      expect(find.text('Restored searchable Task'), findsOneWidget);
      expect(find.text('Old local Task'), findsNothing);
    },
  );
}

class RestoreReplacingOperations implements LifeOsBackupOperations {
  RestoreReplacingOperations({
    required this.repository,
    required this.restoredTasks,
  });

  final MutableTaskRepository repository;
  final List<LifeOsTask> restoredTasks;
  final List<bool> confirmations = [];

  @override
  Future<void> createBackupAt(String destinationPath) async {}

  @override
  Future<void> exportDataAt(String destinationPath) async {}

  @override
  Future<void> restoreBackupFrom(
    String sourcePath, {
    required bool destructiveReplaceConfirmed,
  }) async {
    confirmations.add(destructiveReplaceConfirmed);
    if (!destructiveReplaceConfirmed) {
      throw const LifeOsBackupOperationException(
        LifeOsBackupOperationErrorCode.confirmationRequired,
      );
    }
    repository.tasks
      ..clear()
      ..addAll(restoredTasks);
  }
}

class RestoreFileChooser implements LifeOsArtifactFileChooser {
  const RestoreFileChooser();

  @override
  Future<String?> chooseBackupDestination({
    required String suggestedName,
    required String fileTypeLabel,
  }) async {
    return null;
  }

  @override
  Future<String?> chooseExportDestination({
    required String suggestedName,
    required String fileTypeLabel,
  }) async {
    return null;
  }

  @override
  Future<String?> chooseBackupToRestore({required String fileTypeLabel}) async =>
      r'C:\backup.zip';
}

class MutableTaskRepository implements LifeOsTaskRepository {
  MutableTaskRepository(this.tasks);

  final List<LifeOsTask> tasks;

  @override
  Future<List<LifeOsTask>> getAll() async => List.unmodifiable(tasks);

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async {
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async {
    final normalized = query.toLowerCase();
    return tasks
        .where((task) => task.title.toLowerCase().contains(normalized))
        .toList(growable: false);
  }

  @override
  Future<void> save(LifeOsTask task) async {
    final index = tasks.indexWhere((candidate) => candidate.id == task.id);
    if (index == -1) {
      tasks.add(task);
    } else {
      tasks[index] = task;
    }
  }
}
