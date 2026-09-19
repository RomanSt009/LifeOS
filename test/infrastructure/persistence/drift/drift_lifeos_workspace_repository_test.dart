import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_workspace.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/mappers/lifeos_workspace_mapper.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_workspace_repository.dart';

void main() {
  late LifeOsDatabase database;
  late DriftLifeOsWorkspaceRepository repository;
  var change = 0;

  setUp(() {
    database = LifeOsDatabase(NativeDatabase.memory());
    repository = DriftLifeOsWorkspaceRepository(
      database,
      () => 'workspace-change-${++change}',
      'device-1',
    );
  });
  tearDown(() => database.close());

  LifeOsWorkspace workspace(
    String id, {
    String title = 'Work',
    String? description,
    DateTime? timestamp,
  }) => LifeOsWorkspace.createUserWorkspace(
    id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.workspace),
    title: title,
    description: description,
    timestamp: timestamp ?? DateTime.utc(2026, 9, 19, 10),
  );

  test(
    'persists Workspace and full CREATE Outbox snapshot atomically',
    () async {
      final value = workspace('workspace-1', description: '  exact\ntext  ');
      await repository.save(value);

      expect(await repository.getById(value.id), value);
      expect(await database.select(database.entities).get(), hasLength(1));
      expect(
        await database.select(database.workspaceRecords).get(),
        hasLength(1),
      );
      final outbox = await database.select(database.outboxEntries).getSingle();
      expect(outbox.operation, 'CREATE');
      expect(outbox.baseVersion, isNull);
      expect(outbox.newVersion, 1);
      expect(outbox.schemaVersion, 1);
      expect(jsonDecode(outbox.payload), {
        'id': 'workspace-1',
        'entityType': 'workspace',
        'title': 'Work',
        'description': '  exact\ntext  ',
        'createdAt': '2026-09-19T10:00:00.000Z',
        'updatedAt': '2026-09-19T10:00:00.000Z',
        'lifecycle': 'active',
        'version': 1,
        'source': 'user',
      });
    },
  );

  test(
    'persists edit and lifecycle as UPDATE and skips direct no-op',
    () async {
      final initial = workspace('workspace-1');
      await repository.save(initial);
      await repository.save(initial);
      final edited = initial.edit(
        title: ' Home ',
        description: '',
        updatedAt: DateTime.utc(2026, 9, 19, 11),
      );
      await repository.save(edited);
      final deleted = edited.delete(updatedAt: DateTime.utc(2026, 9, 19, 12));
      await repository.save(deleted);

      expect(await repository.getById(initial.id), deleted);
      final outbox = await database.select(database.outboxEntries).get();
      expect(outbox, hasLength(3));
      expect(outbox[1].operation, 'UPDATE');
      expect(outbox[1].baseVersion, 1);
      expect(outbox[1].newVersion, 2);
      expect(outbox[2].baseVersion, 2);
      expect(outbox[2].newVersion, 3);
      expect(
        (jsonDecode(outbox[2].payload) as Map<String, Object?>)['lifecycle'],
        'deleted',
      );
    },
  );

  test('getAll is all-state and lifecycle reads are deterministic', () async {
    final older = workspace(
      'workspace-b',
      timestamp: DateTime.utc(2026, 9, 19, 9),
    );
    final sameTimeA = workspace('workspace-a');
    final deleted = workspace('workspace-c')
        .delete(updatedAt: DateTime.utc(2026, 9, 19, 11));
    await repository.save(older);
    await repository.save(sameTimeA);
    await repository.save(workspace('workspace-c'));
    await repository.save(deleted);

    expect((await repository.getAll()).map((e) => e.id.value), [
      'workspace-c',
      'workspace-a',
      'workspace-b',
    ]);
    expect(
      (await repository.getByLifecycle(LifeOsEntityLifecycle.active))
          .map((e) => e.id.value),
      ['workspace-a', 'workspace-b'],
    );
    expect(
      (await repository.getByLifecycle(LifeOsEntityLifecycle.deleted)).single,
      deleted,
    );
  });

  test('rolls back Entity and typed row when Outbox creation fails', () async {
    repository = DriftLifeOsWorkspaceRepository(
      database,
      () => throw StateError('injected'),
      'device-1',
    );
    await expectLater(
      repository.save(workspace('workspace-rollback')),
      throwsA(isA<LifeOsWorkspacePersistenceException>()),
    );
    expect(await database.select(database.entities).get(), isEmpty);
    expect(await database.select(database.workspaceRecords).get(), isEmpty);
    expect(await database.select(database.outboxEntries).get(), isEmpty);
  });

  test(
    'reports corrupted Workspace data through typed mapping exception',
    () async {
      await database
          .into(database.entities)
          .insert(
            EntitiesCompanion.insert(
              id: 'workspace-corrupt',
              entityType: 'workspace',
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
              lifecycle: 'active',
              version: 1,
              source: 'user',
            ),
          );
      await database
          .into(database.workspaceRecords)
          .insert(
            WorkspaceRecordsCompanion.insert(
              entityId: 'workspace-corrupt',
              title: ' not-normalized ',
              description: const Value(null),
            ),
          );
      await expectLater(
        repository.getById(
          const LifeOsEntityId(
            value: 'workspace-corrupt',
            entityType: LifeOsEntityType.workspace,
          ),
        ),
        throwsA(isA<LifeOsWorkspaceMappingException>()),
      );
    },
  );

  test('persists Workspace across close and reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'lifeos-workspace-',
    );
    final file = File('${directory.path}${Platform.pathSeparator}lifeos.db');
    await database.close();
    database = LifeOsDatabase(NativeDatabase(file));
    repository = DriftLifeOsWorkspaceRepository(
      database,
      () => 'reopen-change',
      'device-1',
    );
    final value = workspace('workspace-reopen', description: 'kept');
    await repository.save(value);
    await database.close();

    database = LifeOsDatabase(NativeDatabase(file));
    repository = DriftLifeOsWorkspaceRepository(
      database,
      () => 'unused',
      'device-1',
    );
    expect(await repository.getById(value.id), value);
    await database.close();
    database = LifeOsDatabase(NativeDatabase.memory());
    await directory.delete(recursive: true);
  });
}
