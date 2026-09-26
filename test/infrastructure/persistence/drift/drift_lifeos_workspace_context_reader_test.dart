import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/workspaces/lifeos_workspace_context_reader.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/workspaces/drift_lifeos_workspace_context_reader.dart';

void main() {
  late LifeOsDatabase database;
  late DriftLifeOsWorkspaceContextReader reader;
  const workspaceId = LifeOsEntityId(
    value: 'workspace-1',
    entityType: LifeOsEntityType.workspace,
  );

  setUp(() async {
    database = LifeOsDatabase(NativeDatabase.memory());
    reader = DriftLifeOsWorkspaceContextReader(database);
    await _workspace(database, workspaceId.value);
  });
  tearDown(() => database.close());

  test(
    'reads only active direct Task/Note members in deterministic order',
    () async {
      await _task(database, 'task-b', updatedAt: DateTime.utc(2026, 9, 20, 12));
      await _note(database, 'note-a', updatedAt: DateTime.utc(2026, 9, 20, 12));
      await _task(
        database,
        'task-hidden',
        lifecycle: 'archived',
        updatedAt: DateTime.utc(2026, 9, 20, 13),
      );
      await _task(database, 'task-deleted-membership');
      await _membership(
        database,
        'membership-task',
        workspaceId.value,
        'task-b',
      );
      await _membership(
        database,
        'membership-note',
        workspaceId.value,
        'note-a',
      );
      await _membership(
        database,
        'membership-hidden-member',
        workspaceId.value,
        'task-hidden',
      );
      await _membership(
        database,
        'membership-deleted',
        workspaceId.value,
        'task-deleted-membership',
        lifecycle: 'deleted',
      );

      final values = await reader.getDirectMembers(workspaceId);
      expect(values.map((value) => value.entityId.value), ['note-a', 'task-b']);
      expect(values[0], isA<LifeOsWorkspaceNoteMember>());
      expect(values[1], isA<LifeOsWorkspaceTaskMember>());
      expect(values.every((value) => value.membershipId != null), isTrue);
    },
  );

  test('Unassigned uses only effective active Workspace memberships', () async {
    await _task(database, 'task-unassigned');
    await _note(database, 'note-assigned');
    await _task(database, 'task-deleted-membership');
    await _note(database, 'note-inactive-workspace');
    await _task(database, 'task-inactive', lifecycle: 'deleted');
    await _membership(
      database,
      'membership-assigned',
      workspaceId.value,
      'note-assigned',
    );
    await _membership(
      database,
      'membership-deleted',
      workspaceId.value,
      'task-deleted-membership',
      lifecycle: 'deleted',
    );
    await _workspace(database, 'workspace-archived', lifecycle: 'archived');
    await _membership(
      database,
      'membership-inactive-workspace',
      'workspace-archived',
      'note-inactive-workspace',
    );

    final values = await reader.getUnassigned();
    expect(values.map((value) => value.entityId.value).toSet(), {
      'task-unassigned',
      'task-deleted-membership',
      'note-inactive-workspace',
    });
    expect(values.every((value) => value.membershipId == null), isTrue);
  });

  test(
    'does not traverse Relationships and rejects unsupported direct types',
    () async {
      await _task(database, 'task-direct');
      await _note(database, 'note-related-only');
      await _membership(
        database,
        'membership-task',
        workspaceId.value,
        'task-direct',
      );
      expect(
        (await reader.getDirectMembers(workspaceId))
            .map((value) => value.entityId.value),
        ['task-direct'],
      );

      await _entity(database, 'relationship-unsupported', 'relationship');
      await _membership(
        database,
        'membership-unsupported',
        workspaceId.value,
        'relationship-unsupported',
      );
      await expectLater(
        reader.getDirectMembers(workspaceId),
        throwsA(isA<LifeOsWorkspaceContextPersistenceException>()),
      );
    },
  );

  test(
    'Relationships never expand Workspace context or mutate memberships',
    () async {
      const secondWorkspaceId = LifeOsEntityId(
        value: 'workspace-2',
        entityType: LifeOsEntityType.workspace,
      );
      await _workspace(database, secondWorkspaceId.value);
      await _task(database, 'task-member');
      await _note(database, 'note-related-only');
      await _membership(
        database,
        'membership-task',
        workspaceId.value,
        'task-member',
      );
      await _relationship(
        database,
        'relationship-task-note',
        'task-member',
        'note-related-only',
      );

      expect(
        (await reader.getDirectMembers(workspaceId))
            .map((value) => value.entityId.value),
        ['task-member'],
      );
      expect(
        (await reader.getUnassigned()).map((value) => value.entityId.value),
        ['note-related-only'],
      );

      await _membership(
        database,
        'membership-note-second',
        secondWorkspaceId.value,
        'note-related-only',
      );
      expect(await reader.getUnassigned(), isEmpty);

      await _setLifecycle(database, 'membership-note-second', 'deleted');
      expect(
        (await reader.getUnassigned()).map((value) => value.entityId.value),
        ['note-related-only'],
      );
      expect(
        (await database.select(database.relationshipRecords).get()).single.kind,
        'related',
      );
      expect(
        (await database.select(database.entities).get())
            .singleWhere((row) => row.id == 'relationship-task-note')
            .lifecycle,
        'active',
      );

      await _membership(
        database,
        'membership-note-first',
        workspaceId.value,
        'note-related-only',
      );
      await _setLifecycle(database, 'relationship-task-note', 'deleted');
      expect(
        (await reader.getDirectMembers(workspaceId))
            .map((value) => value.entityId.value)
            .toSet(),
        {'task-member', 'note-related-only'},
      );
      expect(
        (await database.select(database.entities).get())
            .singleWhere((row) => row.id == 'membership-note-first')
            .lifecycle,
        'active',
      );
    },
  );
}

Future<void> _entity(
  LifeOsDatabase database,
  String id,
  String type, {
  String lifecycle = 'active',
  DateTime? updatedAt,
}) => database
    .into(database.entities)
    .insert(
      EntitiesCompanion.insert(
        id: id,
        entityType: type,
        createdAt: DateTime.utc(2026),
        updatedAt: updatedAt ?? DateTime.utc(2026),
        lifecycle: lifecycle,
        version: 1,
        source: 'user',
      ),
    );

Future<void> _workspace(
  LifeOsDatabase database,
  String id, {
  String lifecycle = 'active',
}) async {
  await _entity(database, id, 'workspace', lifecycle: lifecycle);
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

Future<void> _task(
  LifeOsDatabase database,
  String id, {
  String lifecycle = 'active',
  DateTime? updatedAt,
}) async {
  await _entity(
    database,
    id,
    'task',
    lifecycle: lifecycle,
    updatedAt: updatedAt,
  );
  await database
      .into(database.taskRecords)
      .insert(
        TaskRecordsCompanion.insert(
          entityId: id,
          title: id,
          isCompleted: false,
        ),
      );
}

Future<void> _note(
  LifeOsDatabase database,
  String id, {
  String lifecycle = 'active',
  DateTime? updatedAt,
}) async {
  await _entity(
    database,
    id,
    'note',
    lifecycle: lifecycle,
    updatedAt: updatedAt,
  );
  await database
      .into(database.noteRecords)
      .insert(
        NoteRecordsCompanion.insert(entityId: id, title: id, content: 'Body'),
      );
}

Future<void> _membership(
  LifeOsDatabase database,
  String id,
  String workspaceId,
  String memberId, {
  String lifecycle = 'active',
}) async {
  await _entity(database, id, 'workspaceMembership', lifecycle: lifecycle);
  await database
      .into(database.workspaceMembershipRecords)
      .insert(
        WorkspaceMembershipRecordsCompanion.insert(
          entityId: id,
          workspaceId: workspaceId,
          memberEntityId: memberId,
        ),
      );
}

Future<void> _relationship(
  LifeOsDatabase database,
  String id,
  String endpointA,
  String endpointB,
) async {
  final first = endpointA.compareTo(endpointB) < 0 ? endpointA : endpointB;
  final second = first == endpointA ? endpointB : endpointA;
  await _entity(database, id, 'relationship');
  await database
      .into(database.relationshipRecords)
      .insert(
        RelationshipRecordsCompanion.insert(
          entityId: id,
          firstEntityId: first,
          secondEntityId: second,
          kind: 'related',
        ),
      );
}

Future<void> _setLifecycle(
  LifeOsDatabase database,
  String id,
  String lifecycle,
) => (database.update(database.entities)..where((row) => row.id.equals(id)))
    .write(EntitiesCompanion(lifecycle: Value(lifecycle)));
