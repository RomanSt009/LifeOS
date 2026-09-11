import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/dependencies.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:path/path.dart' as path;

void main() {
  test(
    'composes a repository with stable production identity inputs',
    () async {
      final supportDirectory = await Directory.systemTemp.createTemp(
        'lifeos-production-dependencies-',
      );
      addTearDown(() => supportDirectory.delete(recursive: true));
      final generatedIdentifiers = ['device-test', 'change-test'];
      final dependencies = await createProductionDependencies(
        applicationSupportDirectoryProvider: () async => supportDirectory,
        identifierGenerator: () => generatedIdentifiers.removeAt(0),
        entityIdGenerator: () => '00000000-0000-4000-8000-000000000001',
        utcClock: () => DateTime.utc(2026, 9, 8, 12),
      );
      addTearDown(dependencies.close);
      const taskId = LifeOsEntityId(
        value: '00000000-0000-4000-8000-000000000001',
        entityType: LifeOsEntityType.task,
      );
      final task = await dependencies.createTask(
        'Use the production composition',
      );
      final outbox = await dependencies.database
          .select(dependencies.database.outboxEntries)
          .getSingle();
      final backupDraft = await dependencies.createBackup();
      final backupData =
          jsonDecode(backupDraft.dataJson) as Map<String, dynamic>;
      final exportData =
          jsonDecode(await dependencies.exportData()) as Map<String, dynamic>;
      expect(await dependencies.taskRepository.getById(taskId), task);
      expect(await dependencies.searchTasks('production'), [task]);
      expect(task.createdAt, DateTime.utc(2026, 9, 8, 12));
      expect(task.updatedAt, task.createdAt);
      expect(task.lifecycle, LifeOsEntityLifecycle.active);
      expect(task.version, 1);
      expect(task.source, LifeOsEntitySource.user);
      expect(outbox.changeId, 'change-test');
      expect(outbox.deviceId, 'device-test');
      expect(backupDraft.createdAt, DateTime.utc(2026, 9, 8, 12));
      expect(backupDraft.applicationVersion, lifeOsApplicationVersion);
      expect((backupData['tasks'] as List<dynamic>), hasLength(1));
      expect((exportData['tasks'] as List<dynamic>), hasLength(1));
      expect(backupDraft.dataJson, isNot(contains('outbox')));
      expect(backupDraft.dataJson, isNot(contains('deviceId')));
      final outboxAfterBackupAndExport = await dependencies.database
          .select(dependencies.database.outboxEntries)
          .get();
      expect(outboxAfterBackupAndExport, hasLength(1));

      final backupPath = path.join(supportDirectory.path, 'restore-test.zip');
      final exportPath = path.join(supportDirectory.path, 'export-test.json');
      await dependencies.backupOperations.createBackupAt(backupPath);
      await dependencies.backupOperations.exportDataAt(exportPath);
      await dependencies.backupOperations.restoreBackupFrom(
        backupPath,
        destructiveReplaceConfirmed: true,
      );
      expect(await File(backupPath).exists(), isTrue);
      expect(await File(exportPath).exists(), isTrue);
      expect(await dependencies.taskRepository.getById(taskId), task);
      expect(
        await dependencies.database
            .select(dependencies.database.outboxEntries)
            .get(),
        isEmpty,
      );
    },
  );
}
