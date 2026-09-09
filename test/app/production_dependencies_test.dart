import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/dependencies.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';

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
        entityIdGenerator: () => 'composed-task',
        utcClock: () => DateTime.utc(2026, 9, 8, 12),
      );
      addTearDown(dependencies.close);
      const taskId = LifeOsEntityId(
        value: 'composed-task',
        entityType: LifeOsEntityType.task,
      );
      final task = await dependencies.createTask(
        'Use the production composition',
      );
      final outbox = await dependencies.database
          .select(dependencies.database.outboxEntries)
          .getSingle();

      expect(await dependencies.taskRepository.getById(taskId), task);
      expect(task.createdAt, DateTime.utc(2026, 9, 8, 12));
      expect(task.updatedAt, task.createdAt);
      expect(task.lifecycle, LifeOsEntityLifecycle.active);
      expect(task.version, 1);
      expect(task.source, LifeOsEntitySource.user);
      expect(outbox.changeId, 'change-test');
      expect(outbox.deviceId, 'device-test');
    },
  );
}
