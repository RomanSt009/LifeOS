import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/mappers/lifeos_workspace_membership_mapper.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_workspace_membership_repository.dart';

void main() {
  late LifeOsDatabase database;
  late DriftLifeOsWorkspaceMembershipRepository repository;
  var change = 0;

  const workspaceId = LifeOsEntityId(
    value: 'workspace-1',
    entityType: LifeOsEntityType.workspace,
  );
  const workspace2Id = LifeOsEntityId(
    value: 'workspace-2',
    entityType: LifeOsEntityType.workspace,
  );
  const taskId = LifeOsEntityId(
    value: 'task-1',
    entityType: LifeOsEntityType.task,
  );
  const noteId = LifeOsEntityId(
    value: 'note-1',
    entityType: LifeOsEntityType.note,
  );
  LifeOsEntityId membershipId(String value) => LifeOsEntityId(
    value: value,
    entityType: LifeOsEntityType.workspaceMembership,
  );

  setUp(() async {
    database = LifeOsDatabase(NativeDatabase.memory());
    repository = DriftLifeOsWorkspaceMembershipRepository(
      database,
      () => 'membership-change-${++change}',
      'device-1',
    );
    await _workspace(database, workspaceId.value);
    await _workspace(database, workspace2Id.value);
    await _task(database, taskId.value);
    await _note(database, noteId.value);
  });
  tearDown(() => database.close());

  test('first attach persists Task membership and CREATE snapshot', () async {
    final result = await repository.attach(
      workspaceId: workspaceId,
      memberEntityId: taskId,
      newMembershipId: membershipId('membership-1'),
      timestamp: DateTime.utc(2026, 9, 19, 10),
    );
    expect(await repository.getByPair(workspaceId, taskId), result);
    final outbox = await database.select(database.outboxEntries).getSingle();
    expect(outbox.operation, 'CREATE');
    expect(outbox.baseVersion, isNull);
    expect(outbox.newVersion, 1);
    expect(outbox.schemaVersion, 1);
    expect(jsonDecode(outbox.payload), {
      'id': 'membership-1',
      'entityType': 'workspaceMembership',
      'workspaceId': 'workspace-1',
      'memberEntityId': 'task-1',
      'createdAt': '2026-09-19T10:00:00.000Z',
      'updatedAt': '2026-09-19T10:00:00.000Z',
      'lifecycle': 'active',
      'version': 1,
      'source': 'user',
    });
  });

  test(
    'active duplicate attach is a true no-op and ignores candidate ID',
    () async {
      final first = await repository.attach(
        workspaceId: workspaceId,
        memberEntityId: taskId,
        newMembershipId: membershipId('membership-1'),
        timestamp: DateTime.utc(2026, 9, 19, 10),
      );
      final duplicate = await repository.attach(
        workspaceId: workspaceId,
        memberEntityId: taskId,
        newMembershipId: membershipId('unused-candidate'),
        timestamp: DateTime.utc(2026, 9, 19, 11),
      );
      expect(duplicate, first);
      expect(await database.select(database.outboxEntries).get(), hasLength(1));
      expect(
        await database.select(database.workspaceMembershipRecords).get(),
        hasLength(1),
      );
    },
  );

  test(
    'detach and reattach preserve identity and emit UPDATE snapshots',
    () async {
      final first = await repository.attach(
        workspaceId: workspaceId,
        memberEntityId: noteId,
        newMembershipId: membershipId('membership-note'),
        timestamp: DateTime.utc(2026, 9, 19, 10),
      );
      final removed = await repository.remove(
        membershipId: first.id,
        timestamp: DateTime.utc(2026, 9, 19, 11),
      );
      expect(removed?.lifecycle, LifeOsEntityLifecycle.deleted);
      expect(removed?.version, 2);
      final repeated = await repository.remove(
        membershipId: first.id,
        timestamp: DateTime.utc(2026, 9, 19, 12),
      );
      expect(repeated, removed);
      final reattached = await repository.attach(
        workspaceId: workspaceId,
        memberEntityId: noteId,
        newMembershipId: membershipId('unused-candidate'),
        timestamp: DateTime.utc(2026, 9, 19, 13),
      );
      expect(reattached.id, first.id);
      expect(reattached.lifecycle, LifeOsEntityLifecycle.active);
      expect(reattached.version, 3);
      final outbox = await database.select(database.outboxEntries).get();
      expect(outbox, hasLength(3));
      expect(outbox[1].operation, 'UPDATE');
      expect(outbox[1].baseVersion, 1);
      expect(outbox[1].newVersion, 2);
      expect(outbox[2].operation, 'UPDATE');
      expect(outbox[2].baseVersion, 2);
      expect(outbox[2].newVersion, 3);
      expect(
        (jsonDecode(outbox[2].payload) as Map<String, Object?>)['id'],
        first.id.value,
      );
    },
  );

  test(
    'supports zero-to-many membership and deterministic active reads',
    () async {
      final first = await repository.attach(
        workspaceId: workspaceId,
        memberEntityId: taskId,
        newMembershipId: membershipId('membership-b'),
        timestamp: DateTime.utc(2026, 9, 19, 10),
      );
      final second = await repository.attach(
        workspaceId: workspace2Id,
        memberEntityId: taskId,
        newMembershipId: membershipId('membership-a'),
        timestamp: DateTime.utc(2026, 9, 19, 11),
      );
      final note = await repository.attach(
        workspaceId: workspaceId,
        memberEntityId: noteId,
        newMembershipId: membershipId('membership-c'),
        timestamp: DateTime.utc(2026, 9, 19, 11),
      );
      await repository.remove(
        membershipId: note.id,
        timestamp: DateTime.utc(2026, 9, 19, 12),
      );
      expect(
        (await repository.getActiveForMember(taskId)).map((e) => e.id.value),
        [second.id.value, first.id.value],
      );
      expect(
        (await repository.getActiveForWorkspace(workspaceId))
            .map((e) => e.id.value),
        [first.id.value],
      );
      expect(await repository.getAll(), hasLength(3));
    },
  );

  test(
    'concurrent duplicate attaches create one pair and one Outbox row',
    () async {
      final results = await Future.wait([
        repository.attach(
          workspaceId: workspaceId,
          memberEntityId: taskId,
          newMembershipId: membershipId('membership-a'),
          timestamp: DateTime.utc(2026, 9, 19, 10),
        ),
        repository.attach(
          workspaceId: workspaceId,
          memberEntityId: taskId,
          newMembershipId: membershipId('membership-b'),
          timestamp: DateTime.utc(2026, 9, 19, 10),
        ),
      ]);
      expect(results[0].id, results[1].id);
      expect(
        await database.select(database.workspaceMembershipRecords).get(),
        hasLength(1),
      );
      expect(await database.select(database.outboxEntries).get(), hasLength(1));
    },
  );

  test(
    'rejects missing, inactive, mismatched, or incomplete endpoints',
    () async {
      await (database.update(database.entities)
            ..where((row) => row.id.equals(workspaceId.value)))
          .write(const EntitiesCompanion(lifecycle: Value('archived')));
      await expectLater(
        repository.attach(
          workspaceId: workspaceId,
          memberEntityId: taskId,
          newMembershipId: membershipId('inactive-workspace'),
          timestamp: DateTime.utc(2026, 9, 19, 10),
        ),
        throwsA(isA<LifeOsWorkspaceMembershipPersistenceException>()),
      );
      await (database.update(database.entities)
            ..where((row) => row.id.equals(workspaceId.value)))
          .write(const EntitiesCompanion(lifecycle: Value('active')));
      await (database.update(database.entities)
            ..where((row) => row.id.equals(taskId.value)))
          .write(const EntitiesCompanion(lifecycle: Value('deleted')));
      await expectLater(
        repository.attach(
          workspaceId: workspaceId,
          memberEntityId: taskId,
          newMembershipId: membershipId('inactive-member'),
          timestamp: DateTime.utc(2026, 9, 19, 10),
        ),
        throwsA(isA<LifeOsWorkspaceMembershipPersistenceException>()),
      );
      await expectLater(
        repository.attach(
          workspaceId: workspaceId,
          memberEntityId: const LifeOsEntityId(
            value: 'missing',
            entityType: LifeOsEntityType.note,
          ),
          newMembershipId: membershipId('missing-member'),
          timestamp: DateTime.utc(2026, 9, 19, 10),
        ),
        throwsA(isA<LifeOsWorkspaceMembershipPersistenceException>()),
      );
      expect(
        await database.select(database.workspaceMembershipRecords).get(),
        isEmpty,
      );
      expect(await database.select(database.outboxEntries).get(), isEmpty);
    },
  );

  test('rolls back membership state when Outbox creation fails', () async {
    repository = DriftLifeOsWorkspaceMembershipRepository(
      database,
      () => throw StateError('injected'),
      'device-1',
    );
    await expectLater(
      repository.attach(
        workspaceId: workspaceId,
        memberEntityId: noteId,
        newMembershipId: membershipId('membership-rollback'),
        timestamp: DateTime.utc(2026, 9, 19, 10),
      ),
      throwsA(isA<LifeOsWorkspaceMembershipPersistenceException>()),
    );
    expect(
      await database.select(database.workspaceMembershipRecords).get(),
      isEmpty,
    );
    expect(
      await (database.select(
        database.entities,
      )..where((row) => row.entityType.equals('workspaceMembership'))).get(),
      isEmpty,
    );
  });

  test(
    'reports corrupted persisted membership through typed exception',
    () async {
      await database
          .into(database.entities)
          .insert(
            EntitiesCompanion.insert(
              id: 'membership-corrupt',
              entityType: 'workspaceMembership',
              createdAt: DateTime.utc(2026),
              updatedAt: DateTime.utc(2026),
              lifecycle: 'archived',
              version: 1,
              source: 'user',
            ),
          );
      await database
          .into(database.workspaceMembershipRecords)
          .insert(
            WorkspaceMembershipRecordsCompanion.insert(
              entityId: 'membership-corrupt',
              workspaceId: workspaceId.value,
              memberEntityId: taskId.value,
            ),
          );
      await expectLater(
        repository.getById(membershipId('membership-corrupt')),
        throwsA(isA<LifeOsWorkspaceMembershipMappingException>()),
      );
    },
  );

  test('survives close and reopen with deleted membership retained', () async {
    final directory = await Directory.systemTemp.createTemp(
      'lifeos-membership-',
    );
    final file = File('${directory.path}${Platform.pathSeparator}lifeos.db');
    await database.close();
    database = LifeOsDatabase(NativeDatabase(file));
    await _workspace(database, workspaceId.value);
    await _task(database, taskId.value);
    repository = DriftLifeOsWorkspaceMembershipRepository(
      database,
      () => 'reopen-${++change}',
      'device-1',
    );
    final attached = await repository.attach(
      workspaceId: workspaceId,
      memberEntityId: taskId,
      newMembershipId: membershipId('membership-reopen'),
      timestamp: DateTime.utc(2026, 9, 19, 10),
    );
    final deleted = await repository.remove(
      membershipId: attached.id,
      timestamp: DateTime.utc(2026, 9, 19, 11),
    );
    await database.close();

    database = LifeOsDatabase(NativeDatabase(file));
    repository = DriftLifeOsWorkspaceMembershipRepository(
      database,
      () => 'unused',
      'device-1',
    );
    expect(await repository.getById(attached.id), deleted);
    expect(await repository.getAll(), [deleted]);
    await database.close();
    database = LifeOsDatabase(NativeDatabase.memory());
    await directory.delete(recursive: true);
  });
}

Future<void> _entity(
  LifeOsDatabase database,
  String id,
  String type, {
  String lifecycle = 'active',
}) => database
    .into(database.entities)
    .insert(
      EntitiesCompanion.insert(
        id: id,
        entityType: type,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        lifecycle: lifecycle,
        version: 1,
        source: 'user',
      ),
    );

Future<void> _workspace(LifeOsDatabase database, String id) async {
  await _entity(database, id, 'workspace');
  await database
      .into(database.workspaceRecords)
      .insert(
        WorkspaceRecordsCompanion.insert(
          entityId: id,
          title: 'Workspace $id',
          description: const Value(null),
        ),
      );
}

Future<void> _task(LifeOsDatabase database, String id) async {
  await _entity(database, id, 'task');
  await database
      .into(database.taskRecords)
      .insert(
        TaskRecordsCompanion.insert(
          entityId: id,
          title: 'Task $id',
          isCompleted: false,
        ),
      );
}

Future<void> _note(LifeOsDatabase database, String id) async {
  await _entity(database, id, 'note');
  await database
      .into(database.noteRecords)
      .insert(
        NoteRecordsCompanion.insert(
          entityId: id,
          title: 'Note $id',
          content: 'Body',
        ),
      );
}
