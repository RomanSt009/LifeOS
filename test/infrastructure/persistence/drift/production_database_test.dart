import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/toggle_stored_task_completion.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/infrastructure/persistence/drift/production_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_task_repository.dart';
import 'package:path/path.dart' as path;

void main() {
  test(
    'stores lifeos.db in application support and retains data after reopen',
    () async {
      final supportDirectory = await Directory.systemTemp.createTemp(
        'lifeos-production-database-',
      );
      addTearDown(() => supportDirectory.delete(recursive: true));

      const taskId = LifeOsEntityId(
        value: 'task-file-backed',
        entityType: LifeOsEntityType.task,
      );
      final task = LifeOsTask(
        id: taskId,
        title: 'Survive database restart',
        isCompleted: true,
        createdAt: DateTime.utc(2026, 9, 8, 10),
        updatedAt: DateTime.utc(2026, 9, 8, 11),
        lifecycle: LifeOsEntityLifecycle.active,
        version: 1,
        source: LifeOsEntitySource.user,
      );

      final firstDatabase = await openProductionDatabase(
        applicationSupportDirectoryProvider: () async => supportDirectory,
      );
      final firstRepository = DriftLifeOsTaskRepository(
        firstDatabase,
        () => 'change-file-backed',
        'device-test',
      );

      await firstRepository.save(task);
      await firstDatabase.close();

      final databaseFile = File(
        path.join(supportDirectory.path, productionDatabaseFileName),
      );
      expect(databaseFile.existsSync(), isTrue);

      final reopenedDatabase = await openProductionDatabase(
        applicationSupportDirectoryProvider: () async => supportDirectory,
      );
      addTearDown(reopenedDatabase.close);
      final reopenedRepository = DriftLifeOsTaskRepository(
        reopenedDatabase,
        () => 'unused-change-id',
        'device-test',
      );

      expect(await reopenedRepository.getById(taskId), task);
      expect(
        await reopenedDatabase.select(reopenedDatabase.outboxEntries).get(),
        hasLength(1),
      );
    },
  );

  test('retains both completion transitions after reopen with one Outbox change each', () async {
    final supportDirectory = await Directory.systemTemp.createTemp(
      'lifeos-toggle-restart-',
    );
    addTearDown(() => supportDirectory.delete(recursive: true));
    const taskId = LifeOsEntityId(
      value: 'task-toggle-restart',
      entityType: LifeOsEntityType.task,
    );
    final createdAt = DateTime.utc(2026, 9, 9, 10);
    final completedAt = DateTime.utc(2026, 9, 9, 11);
    final reopenedAt = DateTime.utc(2026, 9, 9, 12);
    final original = LifeOsTask.createUserTask(
      id: taskId,
      title: 'Persist both completion states',
      timestamp: createdAt,
    );

    final firstDatabase = await openProductionDatabase(
      applicationSupportDirectoryProvider: () async => supportDirectory,
    );
    final firstChangeIds = ['change-create', 'change-complete'];
    final firstRepository = DriftLifeOsTaskRepository(
      firstDatabase,
      () => firstChangeIds.removeAt(0),
      'device-test',
    );
    await firstRepository.save(original);
    final completed = await ToggleStoredTaskCompletion(
      repository: firstRepository,
    )(taskId, updatedAt: completedAt);
    expect(completed?.isCompleted, isTrue);
    await firstDatabase.close();

    final secondDatabase = await openProductionDatabase(
      applicationSupportDirectoryProvider: () async => supportDirectory,
    );
    final secondRepository = DriftLifeOsTaskRepository(
      secondDatabase,
      () => 'change-incomplete',
      'device-test',
    );
    expect((await secondRepository.getById(taskId))?.isCompleted, isTrue);
    final incomplete = await ToggleStoredTaskCompletion(
      repository: secondRepository,
    )(taskId, updatedAt: reopenedAt);
    expect(incomplete?.isCompleted, isFalse);
    await secondDatabase.close();

    final finalDatabase = await openProductionDatabase(
      applicationSupportDirectoryProvider: () async => supportDirectory,
    );
    addTearDown(finalDatabase.close);
    final finalRepository = DriftLifeOsTaskRepository(
      finalDatabase,
      () => 'unused-change-id',
      'device-test',
    );
    final persisted = await finalRepository.getById(taskId);
    final outbox = await finalDatabase
        .select(finalDatabase.outboxEntries)
        .get();

    expect(persisted?.isCompleted, isFalse);
    expect(persisted?.version, 3);
    expect(persisted?.updatedAt, reopenedAt);
    expect(outbox, hasLength(3));
    expect(
      outbox.map((entry) => entry.operation),
      unorderedEquals(['CREATE', 'UPDATE', 'UPDATE']),
    );
    expect(
      outbox.map((entry) => entry.changeId),
      unorderedEquals([
        'change-create',
        'change-complete',
        'change-incomplete',
      ]),
    );
  });

  test('searches persisted Task titles after database reopen', () async {
    final supportDirectory = await Directory.systemTemp.createTemp(
      'lifeos-search-restart-',
    );
    addTearDown(() => supportDirectory.delete(recursive: true));
    final task = LifeOsTask(
      id: const LifeOsEntityId(
        value: 'task-search-restart',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Найти после перезапуска',
      isCompleted: true,
      createdAt: DateTime.utc(2026, 9, 10, 10),
      updatedAt: DateTime.utc(2026, 9, 10, 11),
      lifecycle: LifeOsEntityLifecycle.active,
      version: 2,
      source: LifeOsEntitySource.user,
    );
    final firstDatabase = await openProductionDatabase(
      applicationSupportDirectoryProvider: () async => supportDirectory,
    );
    final firstRepository = DriftLifeOsTaskRepository(
      firstDatabase,
      () => 'change-search-restart',
      'device-test',
    );
    await firstRepository.save(task);
    await firstDatabase.close();

    final reopenedDatabase = await openProductionDatabase(
      applicationSupportDirectoryProvider: () async => supportDirectory,
    );
    addTearDown(reopenedDatabase.close);
    final reopenedRepository = DriftLifeOsTaskRepository(
      reopenedDatabase,
      () => 'unused-change-id',
      'device-test',
    );

    expect(await reopenedRepository.searchByTitle('ПЕРЕЗАПУСКА'), [task]);
    expect(
      await reopenedDatabase.select(reopenedDatabase.outboxEntries).get(),
      hasLength(1),
    );
  });
}
