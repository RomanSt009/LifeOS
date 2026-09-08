import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
}
