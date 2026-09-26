import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/dependencies.dart';
import 'package:lifeos/application/search/lifeos_search_result.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:path/path.dart' as path;

void main() {
  test(
    'composes Workspace quick create over the single production database',
    () async {
      final supportDirectory = await Directory.systemTemp.createTemp(
        'lifeos-workspace-composition-',
      );
      addTearDown(() => supportDirectory.delete(recursive: true));
      var infrastructureId = 0;
      final entityIds = ['workspace-1', 'task-1', 'membership-1'];
      final dependencies = await createProductionDependencies(
        applicationSupportDirectoryProvider: () async => supportDirectory,
        identifierGenerator: () => 'infrastructure-${++infrastructureId}',
        entityIdGenerator: () => entityIds.removeAt(0),
        utcClock: () => DateTime.utc(2026, 9, 20, 12),
      );
      addTearDown(dependencies.close);

      final workspace = await dependencies.createWorkspace(
        title: 'Home',
        description: null,
      );
      final result = await dependencies.createTaskInWorkspace(
        workspaceId: workspace.id,
        title: 'Inside Workspace',
      );
      final members = await dependencies.getWorkspaceMembers(workspace.id);

      expect(members, hasLength(1));
      expect(members.single.entityId, result.task.id);
      expect(
        await dependencies.taskRepository.getById(result.task.id),
        result.task,
      );
      expect(
        await dependencies.workspaceMembershipRepository.getById(
          result.membership.id,
        ),
        result.membership,
      );
      expect(
        await dependencies.database
            .select(dependencies.database.outboxEntries)
            .get(),
        hasLength(3),
      );
    },
  );

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
      final unifiedResults = await dependencies.searchEntities(
        'production',
        limit: 50,
      );
      expect(unifiedResults, hasLength(1));
      expect(unifiedResults.single, isA<LifeOsTaskSearchResult>());
      expect(unifiedResults.single.entityId, task.id);
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

  test(
    'composes direct related-neighbor reads over the single database',
    () async {
      final supportDirectory = await Directory.systemTemp.createTemp(
        'lifeos-related-reader-composition-',
      );
      addTearDown(() => supportDirectory.delete(recursive: true));
      var infrastructureId = 0;
      final entityIds = ['task-source', 'note-neighbor', 'relationship-1'];
      final dependencies = await createProductionDependencies(
        applicationSupportDirectoryProvider: () async => supportDirectory,
        identifierGenerator: () => 'infrastructure-${++infrastructureId}',
        entityIdGenerator: () => entityIds.removeAt(0),
        utcClock: () => DateTime.utc(2026, 9, 25, 12),
      );
      addTearDown(dependencies.close);

      final task = await dependencies.createTask('Source');
      final note = await dependencies.createNote(
        title: 'Neighbor',
        content: '',
      );
      final relationship = await dependencies.createRelationship(
        task.id,
        note.id,
      );

      final neighbors = await dependencies.getDirectRelatedNeighbors(
        sourceId: task.id,
        limit: 5,
      );

      expect(neighbors, hasLength(1));
      expect(neighbors.single.entityId, note.id);
      expect(neighbors.single.relationship, relationship);
      expect(
        await dependencies.database
            .select(dependencies.database.entities)
            .get(),
        hasLength(3),
      );
    },
  );
}
