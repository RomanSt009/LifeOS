import 'package:drift/drift.dart' show Value, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/relationships/lifeos_related_entity_reader.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/mappers/lifeos_relationship_mapper.dart';
import 'package:lifeos/infrastructure/persistence/drift/relationships/drift_lifeos_related_entity_reader.dart';

void main() {
  late LifeOsDatabase database;
  late DriftLifeOsRelatedEntityReader reader;

  setUp(() {
    database = LifeOsDatabase(NativeDatabase.memory());
    reader = DriftLifeOsRelatedEntityReader(database);
  });
  tearDown(() => database.close());

  test(
    'validates Task/Note source identity and lifecycle with typed errors',
    () async {
      await _task(database, 'task-active');
      await _note(database, 'note-active');
      await _task(database, 'task-archived', lifecycle: 'archived');
      await _note(database, 'note-deleted', lifecycle: 'deleted');

      expect(
        await reader.getDirectNeighbors(
          sourceId: _id('task-active', LifeOsEntityType.task),
          limit: 1,
        ),
        isEmpty,
      );
      expect(
        await reader.getDirectNeighbors(
          sourceId: _id('note-active', LifeOsEntityType.note),
          limit: 1,
        ),
        isEmpty,
      );

      await _expectQueryError(
        reader.getDirectNeighbors(
          sourceId: _id('missing', LifeOsEntityType.task),
          limit: 1,
        ),
        LifeOsRelatedEntityQueryError.sourceNotFound,
      );
      for (final source in [
        _id('task-archived', LifeOsEntityType.task),
        _id('note-deleted', LifeOsEntityType.note),
      ]) {
        await _expectQueryError(
          reader.getDirectNeighbors(sourceId: source, limit: 1),
          LifeOsRelatedEntityQueryError.sourceInactive,
        );
      }
      await _expectQueryError(
        reader.getDirectNeighbors(
          sourceId: _id('workspace', LifeOsEntityType.workspace),
          limit: 1,
        ),
        LifeOsRelatedEntityQueryError.unsupportedSourceType,
      );
      await _expectQueryError(
        reader.getDirectNeighbors(
          sourceId: _id('task-active', LifeOsEntityType.task),
          limit: 0,
        ),
        LifeOsRelatedEntityQueryError.invalidLimit,
      );
    },
  );

  test(
    'resolves Task↔Task, Task↔Note, Note↔Task, and Note↔Note from either side',
    () async {
      await _task(database, 'task-m');
      await _task(database, 'task-z');
      await _note(database, 'note-a');
      await _note(database, 'note-m');
      await _task(database, 'task-a');
      await _relationship(database, 'rel-task-first', 'task-m', 'task-z');
      await _relationship(database, 'rel-task-second', 'note-a', 'task-m');
      await _relationship(database, 'rel-note-first', 'note-m', 'task-a');
      await _relationship(database, 'rel-note-second', 'note-a', 'note-m');

      final taskNeighbors = await reader.getDirectNeighbors(
        sourceId: _id('task-m', LifeOsEntityType.task),
        limit: 10,
      );
      expect(taskNeighbors, hasLength(2));
      expect(taskNeighbors.map((value) => value.entityId.value).toSet(), {
        'task-z',
        'note-a',
      });
      expect(
        taskNeighbors.whereType<LifeOsRelatedTaskNeighbor>(),
        hasLength(1),
      );
      expect(
        taskNeighbors.whereType<LifeOsRelatedNoteNeighbor>(),
        hasLength(1),
      );

      final noteNeighbors = await reader.getDirectNeighbors(
        sourceId: _id('note-m', LifeOsEntityType.note),
        limit: 10,
      );
      expect(noteNeighbors, hasLength(2));
      expect(noteNeighbors.map((value) => value.entityId.value).toSet(), {
        'task-a',
        'note-a',
      });
      expect(
        noteNeighbors.whereType<LifeOsRelatedTaskNeighbor>(),
        hasLength(1),
      );
      expect(
        noteNeighbors.whereType<LifeOsRelatedNoteNeighbor>(),
        hasLength(1),
      );
    },
  );

  test(
    'filters lifecycle state and makes a restored neighbor visible again',
    () async {
      await _task(database, 'task-source');
      await _note(database, 'note-visible');
      await _note(database, 'note-hidden');
      await _note(database, 'note-unlinked');
      await _relationship(
        database,
        'rel-visible',
        'note-visible',
        'task-source',
      );
      await _relationship(database, 'rel-hidden', 'note-hidden', 'task-source');
      await _relationship(
        database,
        'rel-unlinked',
        'note-unlinked',
        'task-source',
        lifecycle: 'deleted',
      );
      await _setLifecycle(database, 'note-hidden', 'archived');

      var values = await reader.getDirectNeighbors(
        sourceId: _id('task-source', LifeOsEntityType.task),
        limit: 10,
      );
      expect(values.map((value) => value.entityId.value), ['note-visible']);

      await _setLifecycle(database, 'note-hidden', 'deleted');
      expect(
        await reader.getDirectNeighbors(
          sourceId: _id('task-source', LifeOsEntityType.task),
          limit: 10,
        ),
        hasLength(1),
      );
      await _setLifecycle(database, 'note-hidden', 'active');
      values = await reader.getDirectNeighbors(
        sourceId: _id('task-source', LifeOsEntityType.task),
        limit: 10,
      );
      expect(values.map((value) => value.entityId.value).toSet(), {
        'note-visible',
        'note-hidden',
      });
    },
  );

  test(
    'orders in SQL by Relationship update then ID and applies limit',
    () async {
      await _task(database, 'task-source');
      for (final id in ['note-a', 'note-b', 'note-c', 'note-d']) {
        await _note(database, id);
      }
      await _relationship(
        database,
        'rel-z-old',
        'note-d',
        'task-source',
        updatedAt: DateTime.utc(2026, 9, 25, 9),
      );
      await _relationship(
        database,
        'rel-b-new',
        'note-b',
        'task-source',
        updatedAt: DateTime.utc(2026, 9, 25, 11),
      );
      await _relationship(
        database,
        'rel-a-new',
        'note-a',
        'task-source',
        updatedAt: DateTime.utc(2026, 9, 25, 11),
      );
      await _relationship(
        database,
        'rel-middle',
        'note-c',
        'task-source',
        updatedAt: DateTime.utc(2026, 9, 25, 10),
      );

      final values = await reader.getDirectNeighbors(
        sourceId: _id('task-source', LifeOsEntityType.task),
        limit: 3,
      );
      expect(values, hasLength(3));
      expect(values.map((value) => value.relationship.id.value), [
        'rel-a-new',
        'rel-b-new',
        'rel-middle',
      ]);
      expect(values.map((value) => value.entityId.value).toSet(), hasLength(3));
    },
  );

  test('keeps a large adjacency read bounded and deterministic', () async {
    await _task(database, 'task-source');
    for (var index = 0; index < 80; index++) {
      final id = 'note-${index.toString().padLeft(3, '0')}';
      await _note(database, id);
      await _relationship(
        database,
        'rel-${index.toString().padLeft(3, '0')}',
        id,
        'task-source',
        updatedAt: DateTime.utc(2026, 9, 25, 10).add(Duration(minutes: index)),
      );
    }

    final first = await reader.getDirectNeighbors(
      sourceId: _id('task-source', LifeOsEntityType.task),
      limit: 7,
    );
    final second = await reader.getDirectNeighbors(
      sourceId: _id('task-source', LifeOsEntityType.task),
      limit: 7,
    );
    expect(first, hasLength(7));
    expect(
      first.map((value) => value.relationship.id.value),
      second.map((value) => value.relationship.id.value),
    );
    expect(first.first.relationship.id.value, 'rel-079');
    expect(first.last.relationship.id.value, 'rel-073');
  });

  test(
    'fails rather than silently skipping corrupted typed neighbor state',
    () async {
      await _task(database, 'task-source');
      await _entity(database, 'note-corrupt', 'note');
      await _relationship(
        database,
        'rel-corrupt',
        'note-corrupt',
        'task-source',
      );

      await expectLater(
        reader.getDirectNeighbors(
          sourceId: _id('task-source', LifeOsEntityType.task),
          limit: 10,
        ),
        throwsA(isA<LifeOsRelatedEntityPersistenceException>()),
      );
    },
  );

  test('fails on an incompatible persisted endpoint type', () async {
    await _task(database, 'task-source');
    await _workspace(database, 'workspace-corrupt');
    await _relationship(
      database,
      'rel-corrupt',
      'task-source',
      'workspace-corrupt',
    );

    await expectLater(
      reader.getDirectNeighbors(
        sourceId: _id('task-source', LifeOsEntityType.task),
        limit: 10,
      ),
      throwsA(isA<LifeOsRelationshipMappingException>()),
    );
  });

  test(
    'is read-only and repeated reads preserve all persistence counts',
    () async {
      await _task(database, 'task-source');
      await _note(database, 'note-target');
      await _relationship(
        database,
        'rel-read-only',
        'note-target',
        'task-source',
      );
      await database
          .into(database.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              changeId: 'existing-change',
              entityId: 'task-source',
              deviceId: 'device',
              operation: 'CREATE',
              baseVersion: const Value(null),
              newVersion: 1,
              payload: '{}',
              schemaVersion: 1,
              status: 'PENDING',
              attemptCount: 0,
              createdAt: DateTime.utc(2026),
              lastAttemptAt: const Value(null),
            ),
          );
      final before = await _counts(database);

      final first = await reader.getDirectNeighbors(
        sourceId: _id('task-source', LifeOsEntityType.task),
        limit: 5,
      );
      final second = await reader.getDirectNeighbors(
        sourceId: _id('task-source', LifeOsEntityType.task),
        limit: 5,
      );

      expect(
        first.map((value) => value.entityId),
        second.map((value) => value.entityId),
      );
      expect(await _counts(database), before);
    },
  );

  test('schema v4 endpoint lookup uses both existing indexes', () async {
    final rows = await database
        .customSelect(
          '''
EXPLAIN QUERY PLAN
SELECT entity_id
FROM relationships
WHERE first_entity_id = ?1 OR second_entity_id = ?1
LIMIT ?2
''',
          variables: const [Variable<String>('task-source'), Variable<int>(10)],
        )
        .get();
    final details = rows.map((row) => row.read<String>('detail')).join('\n');

    expect(details, contains('MULTI-INDEX OR'));
    expect(details, contains('first_entity_id'));
    expect(details, contains('relationships_second_entity_id_idx'));
    expect(details, isNot(contains('SCAN relationships')));
  });
}

LifeOsEntityId _id(String value, LifeOsEntityType type) =>
    LifeOsEntityId(value: value, entityType: type);

Future<void> _expectQueryError(
  Future<Object?> future,
  LifeOsRelatedEntityQueryError error,
) => expectLater(
  future,
  throwsA(
    isA<LifeOsRelatedEntityQueryException>().having(
      (value) => value.error,
      'error',
      error,
    ),
  ),
);

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

Future<void> _task(
  LifeOsDatabase database,
  String id, {
  String lifecycle = 'active',
}) async {
  await _entity(database, id, 'task', lifecycle: lifecycle);
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

Future<void> _note(
  LifeOsDatabase database,
  String id, {
  String lifecycle = 'active',
}) async {
  await _entity(database, id, 'note', lifecycle: lifecycle);
  await database
      .into(database.noteRecords)
      .insert(
        NoteRecordsCompanion.insert(
          entityId: id,
          title: 'Note $id',
          content: 'Body $id',
        ),
      );
}

Future<void> _workspace(LifeOsDatabase database, String id) async {
  await _entity(database, id, 'workspace');
  await database
      .into(database.workspaceRecords)
      .insert(
        WorkspaceRecordsCompanion.insert(
          entityId: id,
          title: 'Workspace',
          description: const Value(null),
        ),
      );
}

Future<void> _relationship(
  LifeOsDatabase database,
  String id,
  String endpointA,
  String endpointB, {
  String lifecycle = 'active',
  DateTime? updatedAt,
}) async {
  final first = endpointA.compareTo(endpointB) < 0 ? endpointA : endpointB;
  final second = first == endpointA ? endpointB : endpointA;
  await _entity(
    database,
    id,
    'relationship',
    lifecycle: lifecycle,
    updatedAt: updatedAt,
  );
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

Future<List<int>> _counts(LifeOsDatabase database) async => [
  (await database.select(database.entities).get()).length,
  (await database.select(database.taskRecords).get()).length,
  (await database.select(database.noteRecords).get()).length,
  (await database.select(database.relationshipRecords).get()).length,
  (await database.select(database.outboxEntries).get()).length,
];
