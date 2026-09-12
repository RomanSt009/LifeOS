import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/app.dart';
import 'package:lifeos/app/dependencies.dart';
import 'package:lifeos/application/use_cases/create_lifeos_backup.dart';
import 'package:lifeos/application/use_cases/create_lifeos_note.dart';
import 'package:lifeos/application/backup/lifeos_backup_operations.dart';
import 'package:lifeos/application/use_cases/create_lifeos_task.dart';
import 'package:lifeos/application/use_cases/export_lifeos_data.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_note.dart';
import 'package:lifeos/application/use_cases/restore_lifeos_backup.dart';
import 'package:lifeos/application/use_cases/search_lifeos_tasks.dart';
import 'package:lifeos/infrastructure/backup/files/lifeos_backup_file_reader.dart';
import 'package:lifeos/infrastructure/backup/formats/v1_backup_export_encoder.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_task_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_note_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/restore/drift_lifeos_backup_restore_store.dart';
import 'package:lifeos/presentation/search/task_search_providers.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';

void main() {
  testWidgets('closes the owned database when the app lifecycle ends', (
    tester,
  ) async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    final repository = DriftLifeOsTaskRepository(
      database,
      () => 'change-test',
      'device-test',
    );
    final noteRepository = DriftLifeOsNoteRepository(
      database,
      () => 'note-change-test',
      'device-test',
    );
    const backupExportEncoder = V1BackupExportEncoder();
    final dependencies = LifeOsAppDependencies(
      database: database,
      taskRepository: repository,
      noteRepository: noteRepository,
      createTask: CreateLifeOsTask(
        repository: repository,
        entityIdGenerator: () => 'task-test',
        utcClock: () => DateTime.utc(2026, 9, 9),
      ),
      createNote: CreateLifeOsNote(
        repository: noteRepository,
        entityIdGenerator: () => 'note-test',
        utcClock: () => DateTime.utc(2026, 9, 9),
      ),
      editNote: EditLifeOsNote(
        repository: noteRepository,
        utcClock: () => DateTime.utc(2026, 9, 9),
      ),
      searchTasks: SearchLifeOsTasks(repository),
      createBackup: CreateLifeOsBackup(
        taskRepository: repository,
        encoder: backupExportEncoder,
        utcClock: () => DateTime.utc(2026, 9, 11),
        applicationVersion: lifeOsApplicationVersion,
      ),
      exportData: ExportLifeOsData(
        taskRepository: repository,
        encoder: backupExportEncoder,
        utcClock: () => DateTime.utc(2026, 9, 11),
        applicationVersion: lifeOsApplicationVersion,
      ),
      restoreBackup: RestoreLifeOsBackup(
        reader: const LifeOsBackupFileReader(),
        restoreStore: DriftLifeOsBackupRestoreStore(database),
      ),
      backupOperations: const _NoopBackupOperations(),
    );

    await tester.pumpWidget(LifeOSApp(dependencies: dependencies));
    await database.customSelect('SELECT 1').get();

    await tester.pumpWidget(const SizedBox.shrink());
    await dependencies.close();

    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('provides the composed Domain repository to Presentation', (
    tester,
  ) async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    final repository = DriftLifeOsTaskRepository(
      database,
      () => 'change-test',
      'device-test',
    );
    final noteRepository = DriftLifeOsNoteRepository(
      database,
      () => 'note-change-test',
      'device-test',
    );
    const backupExportEncoder = V1BackupExportEncoder();
    final dependencies = LifeOsAppDependencies(
      database: database,
      taskRepository: repository,
      noteRepository: noteRepository,
      createTask: CreateLifeOsTask(
        repository: repository,
        entityIdGenerator: () => 'task-test',
        utcClock: () => DateTime.utc(2026, 9, 9),
      ),
      createNote: CreateLifeOsNote(
        repository: noteRepository,
        entityIdGenerator: () => 'note-test',
        utcClock: () => DateTime.utc(2026, 9, 9),
      ),
      editNote: EditLifeOsNote(
        repository: noteRepository,
        utcClock: () => DateTime.utc(2026, 9, 9),
      ),
      searchTasks: SearchLifeOsTasks(repository),
      createBackup: CreateLifeOsBackup(
        taskRepository: repository,
        encoder: backupExportEncoder,
        utcClock: () => DateTime.utc(2026, 9, 11),
        applicationVersion: lifeOsApplicationVersion,
      ),
      exportData: ExportLifeOsData(
        taskRepository: repository,
        encoder: backupExportEncoder,
        utcClock: () => DateTime.utc(2026, 9, 11),
        applicationVersion: lifeOsApplicationVersion,
      ),
      restoreBackup: RestoreLifeOsBackup(
        reader: const LifeOsBackupFileReader(),
        restoreStore: DriftLifeOsBackupRestoreStore(database),
      ),
      backupOperations: const _NoopBackupOperations(),
    );

    await tester.pumpWidget(LifeOSApp(dependencies: dependencies));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    expect(container.read(lifeOsTaskRepositoryProvider), same(repository));
    expect(
      container.read(searchLifeOsTasksProvider),
      same(dependencies.searchTasks),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await dependencies.close();
  });
}

class _NoopBackupOperations implements LifeOsBackupOperations {
  const _NoopBackupOperations();

  @override
  Future<void> createBackupAt(String destinationPath) async {}

  @override
  Future<void> exportDataAt(String destinationPath) async {}

  @override
  Future<void> restoreBackupFrom(
    String sourcePath, {
    required bool destructiveReplaceConfirmed,
  }) async {}
}
