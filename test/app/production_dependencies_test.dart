import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/dependencies.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';

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
      );
      addTearDown(dependencies.close);
      const taskId = LifeOsEntityId(
        value: 'composed-task',
        entityType: LifeOsEntityType.task,
      );
      final task = LifeOsTask(
        id: taskId,
        title: 'Use the production composition',
        isCompleted: false,
        createdAt: DateTime.utc(2026, 9, 8, 12),
        updatedAt: DateTime.utc(2026, 9, 8, 12),
        lifecycle: LifeOsEntityLifecycle.active,
        version: 1,
        source: LifeOsEntitySource.user,
      );

      await dependencies.taskRepository.save(task);
      final outbox = await dependencies.database
          .select(dependencies.database.outboxEntries)
          .getSingle();

      expect(await dependencies.taskRepository.getById(taskId), task);
      expect(outbox.changeId, 'change-test');
      expect(outbox.deviceId, 'device-test');
    },
  );
}
