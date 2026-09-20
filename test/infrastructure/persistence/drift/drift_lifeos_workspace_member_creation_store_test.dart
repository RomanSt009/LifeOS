import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_workspace_membership.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_workspace_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/workspaces/drift_lifeos_workspace_member_creation_store.dart';
import 'package:lifeos/domain/entities/lifeos_workspace.dart';

void main() {
  late LifeOsDatabase database;
  var change = 0;
  const workspaceId = LifeOsEntityId(
    value: 'workspace-1',
    entityType: LifeOsEntityType.workspace,
  );
  final timestamp = DateTime.utc(2026, 9, 20, 10);

  setUp(() async {
    database = LifeOsDatabase(NativeDatabase.memory());
    await DriftLifeOsWorkspaceRepository(
      database,
      () => 'workspace-change-${++change}',
      'device-1',
    ).save(
      LifeOsWorkspace.createUserWorkspace(
        id: workspaceId,
        title: 'Workspace',
        description: null,
        timestamp: timestamp,
      ),
    );
    await database.delete(database.outboxEntries).go();
  });
  tearDown(() => database.close());

  test(
    'atomically creates Task, Membership, and exactly two CREATE changes',
    () async {
      final task = _task(timestamp);
      final membership = _membership(
        'membership-task',
        task.id,
        workspaceId,
        timestamp,
      );
      await _store(database).createTaskInWorkspace(task, membership);

      expect(await database.select(database.taskRecords).get(), hasLength(1));
      expect(
        await database.select(database.workspaceMembershipRecords).get(),
        hasLength(1),
      );
      final outbox = await database.select(database.outboxEntries).get();
      expect(outbox, hasLength(2));
      expect(outbox.every((entry) => entry.operation == 'CREATE'), isTrue);
      expect(outbox.map((entry) => entry.entityId).toSet(), {
        task.id.value,
        membership.id.value,
      });
      final workspaceEntity = await (database.select(
        database.entities,
      )..where((row) => row.id.equals(workspaceId.value))).getSingle();
      expect(workspaceEntity.version, 1);
      expect(workspaceEntity.updatedAt.toUtc(), timestamp);
    },
  );

  test('atomically creates Note and preserves content exactly', () async {
    final note = _note(timestamp);
    final membership = _membership(
      'membership-note',
      note.id,
      workspaceId,
      timestamp,
    );
    await _store(database).createNoteInWorkspace(note, membership);
    final row = await database.select(database.noteRecords).getSingle();
    expect(row.content, '  Body\n');
    expect(await database.select(database.outboxEntries).get(), hasLength(2));
  });

  test('Task and Membership survive close and reopen', () async {
    final directory = await Directory.systemTemp.createTemp('lifeos-quick-');
    final file = File('${directory.path}${Platform.pathSeparator}lifeos.db');
    await database.close();
    database = LifeOsDatabase(NativeDatabase(file));
    await DriftLifeOsWorkspaceRepository(
      database,
      () => 'workspace-file',
      'device-1',
    ).save(
      LifeOsWorkspace.createUserWorkspace(
        id: workspaceId,
        title: 'Workspace',
        description: null,
        timestamp: timestamp,
      ),
    );
    await database.delete(database.outboxEntries).go();
    await _store(database).createTaskInWorkspace(
      _task(timestamp),
      _membership(
        'membership-task',
        _task(timestamp).id,
        workspaceId,
        timestamp,
      ),
    );
    await database.close();
    database = LifeOsDatabase(NativeDatabase(file));
    expect(await database.select(database.taskRecords).get(), hasLength(1));
    expect(
      await database.select(database.workspaceMembershipRecords).get(),
      hasLength(1),
    );
    await database.close();
    database = LifeOsDatabase(NativeDatabase.memory());
    await directory.delete(recursive: true);
  });

  for (final failure in <String, String>{
    'member typed persistence': "CREATE TRIGGER fail_step BEFORE INSERT ON tasks BEGIN SELECT RAISE(ABORT, 'fail'); END",
    'Membership persistence': "CREATE TRIGGER fail_step BEFORE INSERT ON workspace_memberships BEGIN SELECT RAISE(ABORT, 'fail'); END",
    'first Outbox persistence': "CREATE TRIGGER fail_step BEFORE INSERT ON outbox BEGIN SELECT RAISE(ABORT, 'fail'); END",
    'second Outbox persistence': "CREATE TRIGGER fail_step BEFORE INSERT ON outbox WHEN (SELECT COUNT(*) FROM outbox) = 1 BEGIN SELECT RAISE(ABORT, 'fail'); END",
  }.entries) {
    test(
      'rolls back every quick-create row after ${failure.key} failure',
      () async {
        await database.customStatement(failure.value);
        await expectLater(
          _store(database).createTaskInWorkspace(
            _task(timestamp),
            _membership(
              'membership-task',
              _task(timestamp).id,
              workspaceId,
              timestamp,
            ),
          ),
          throwsA(isA<LifeOsWorkspaceMemberCreationPersistenceException>()),
        );
        await _expectNoPartialState(database);
      },
    );
  }

  test('rolls back Note Entity when Note typed persistence fails', () async {
    await database.customStatement(
      "CREATE TRIGGER fail_note BEFORE INSERT ON notes BEGIN SELECT RAISE(ABORT, 'fail'); END",
    );
    final note = _note(timestamp);
    await expectLater(
      _store(database).createNoteInWorkspace(
        note,
        _membership('membership-note', note.id, workspaceId, timestamp),
      ),
      throwsA(isA<LifeOsWorkspaceMemberCreationPersistenceException>()),
    );
    await _expectNoPartialState(database);
  });
}

DriftLifeOsWorkspaceMemberCreationStore _store(LifeOsDatabase database) {
  var change = 0;
  return DriftLifeOsWorkspaceMemberCreationStore(
    database,
    () => 'quick-change-${++change}',
    'device-1',
  );
}

LifeOsTask _task(DateTime timestamp) => LifeOsTask.createUserTask(
  id: const LifeOsEntityId(value: 'task-1', entityType: LifeOsEntityType.task),
  title: 'Task',
  timestamp: timestamp,
);

LifeOsNote _note(DateTime timestamp) => LifeOsNote.createUserNote(
  id: const LifeOsEntityId(value: 'note-1', entityType: LifeOsEntityType.note),
  title: 'Note',
  content: '  Body\n',
  timestamp: timestamp,
);

LifeOsWorkspaceMembership _membership(
  String id,
  LifeOsEntityId memberId,
  LifeOsEntityId workspaceId,
  DateTime timestamp,
) => LifeOsWorkspaceMembership.createUserMembership(
  id: LifeOsEntityId(
    value: id,
    entityType: LifeOsEntityType.workspaceMembership,
  ),
  workspaceId: workspaceId,
  memberEntityId: memberId,
  timestamp: timestamp,
);

Future<void> _expectNoPartialState(LifeOsDatabase database) async {
  expect(await database.select(database.taskRecords).get(), isEmpty);
  expect(await database.select(database.noteRecords).get(), isEmpty);
  expect(
    await database.select(database.workspaceMembershipRecords).get(),
    isEmpty,
  );
  expect(await database.select(database.outboxEntries).get(), isEmpty);
  expect(
    await (database.select(
      database.entities,
    )..where((row) => row.id.isNotValue('workspace-1'))).get(),
    isEmpty,
  );
}
