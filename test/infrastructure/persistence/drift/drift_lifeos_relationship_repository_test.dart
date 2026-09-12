import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_relationship.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_relationship_repository.dart';

void main() {
  late LifeOsDatabase database;
  late DriftLifeOsRelationshipRepository repository;
  var change = 0;

  setUp(() async {
    database = LifeOsDatabase(NativeDatabase.memory());
    repository = DriftLifeOsRelationshipRepository(
      database,
      () => 'change-${++change}',
      'device-1',
    );
    await _entity(database, 'task-a', 'task');
    await _entity(database, 'task-b', 'task');
    await _entity(database, 'note-a', 'note');
  });
  tearDown(() => database.close());

  LifeOsRelationship relationship(
    String id,
    LifeOsEntityId first,
    LifeOsEntityId second, {
    DateTime? timestamp,
  }) => LifeOsRelationship.createUserRelationship(
    id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.relationship),
    firstEndpoint: first,
    secondEndpoint: second,
    timestamp: timestamp ?? DateTime.utc(2026, 9, 12, 10),
  );

  const taskA = LifeOsEntityId(
    value: 'task-a',
    entityType: LifeOsEntityType.task,
  );
  const taskB = LifeOsEntityId(
    value: 'task-b',
    entityType: LifeOsEntityType.task,
  );
  const noteA = LifeOsEntityId(
    value: 'note-a',
    entityType: LifeOsEntityType.note,
  );

  test('creates and reads Task↔Task, Task↔Note, and Note↔Note', () async {
    final values = [
      relationship(
        'rel-1',
        taskA,
        taskB,
        timestamp: DateTime.utc(2026, 9, 12, 10),
      ),
      relationship(
        'rel-2',
        taskA,
        noteA,
        timestamp: DateTime.utc(2026, 9, 12, 12),
      ),
      relationship(
        'rel-3',
        noteA,
        taskB,
        timestamp: DateTime.utc(2026, 9, 12, 12),
      ),
    ];
    for (final value in values) {
      await repository.save(value);
    }

    expect(await repository.getById(values.first.id), values.first);
    expect((await repository.getForEntity(taskA)).map((e) => e.id.value), [
      'rel-2',
      'rel-1',
    ]);
    expect((await repository.getForEntity(noteA)).map((e) => e.id.value), [
      'rel-2',
      'rel-3',
    ]);

    final outbox = await database.select(database.outboxEntries).get();
    expect(outbox, hasLength(3));
    final payload = jsonDecode(outbox.first.payload) as Map<String, Object?>;
    expect(outbox.first.operation, 'CREATE');
    expect(outbox.first.baseVersion, null);
    expect(outbox.first.newVersion, 1);
    expect(outbox.first.schemaVersion, 1);
    expect(payload, {
      'id': 'rel-1',
      'entityType': 'relationship',
      'firstEntityId': 'task-a',
      'secondEntityId': 'task-b',
      'kind': 'related',
      'createdAt': '2026-09-12T10:00:00.000Z',
      'updatedAt': '2026-09-12T10:00:00.000Z',
      'lifecycle': 'active',
      'version': 1,
      'source': 'user',
    });
  });

  test(
    'persists unlink as UPDATE and excludes deleted relationships',
    () async {
      final active = relationship('rel-1', taskA, noteA);
      await repository.save(active);
      final deleted = active.unlink(updatedAt: DateTime.utc(2026, 9, 12, 11));
      await repository.save(deleted);

      expect(
        (await repository.getById(deleted.id))?.lifecycle,
        LifeOsEntityLifecycle.deleted,
      );
      expect(await repository.getForEntity(taskA), isEmpty);
      final outbox = await database.select(database.outboxEntries).get();
      expect(outbox.last.operation, 'UPDATE');
      expect(outbox.last.baseVersion, 1);
      expect(outbox.last.newVersion, 2);
      expect(jsonDecode(outbox.last.payload), {
        'id': 'rel-1',
        'entityType': 'relationship',
        'firstEntityId': 'note-a',
        'secondEntityId': 'task-a',
        'kind': 'related',
        'createdAt': '2026-09-12T10:00:00.000Z',
        'updatedAt': '2026-09-12T11:00:00.000Z',
        'lifecycle': 'deleted',
        'version': 2,
        'source': 'user',
      });
    },
  );

  test(
    'direct repeated save is a true no-op without another Outbox row',
    () async {
      final value = relationship('rel-1', taskA, noteA);
      await repository.save(value);
      await repository.save(value);

      expect(await repository.getById(value.id), value);
      expect(await database.select(database.outboxEntries).get(), hasLength(1));
    },
  );

  test('rejects invalid creation and edits outside lifecycle unlink', () async {
    final invalidCreation = LifeOsRelationship(
      id: const LifeOsEntityId(
        value: 'rel-new',
        entityType: LifeOsEntityType.relationship,
      ),
      firstEntityId: noteA,
      secondEntityId: taskA,
      kind: LifeOsRelationshipKind.related,
      createdAt: DateTime.utc(2026, 9, 12, 10),
      updatedAt: DateTime.utc(2026, 9, 12, 11),
      lifecycle: LifeOsEntityLifecycle.deleted,
      version: 2,
      source: LifeOsEntitySource.user,
    );
    await expectLater(
      repository.save(invalidCreation),
      throwsA(isA<LifeOsRelationshipPersistenceException>()),
    );

    final active = relationship('rel-1', taskA, noteA);
    await repository.save(active);
    final endpointEdit = LifeOsRelationship(
      id: active.id,
      firstEntityId: taskA,
      secondEntityId: taskB,
      kind: active.kind,
      createdAt: active.createdAt,
      updatedAt: active.updatedAt.add(const Duration(hours: 1)),
      lifecycle: LifeOsEntityLifecycle.deleted,
      version: 2,
      source: active.source,
    );
    await expectLater(
      repository.save(endpointEdit),
      throwsA(isA<LifeOsRelationshipPersistenceException>()),
    );

    expect(await repository.getById(active.id), active);
    expect(await database.select(database.outboxEntries).get(), hasLength(1));
  });

  test(
    'rejects missing/mismatched endpoints and Entity ID collision',
    () async {
      await _entity(database, 'collision', 'task');
      final cases = [
        relationship(
          'missing-rel',
          taskA,
          const LifeOsEntityId(
            value: 'missing',
            entityType: LifeOsEntityType.note,
          ),
        ),
        relationship(
          'wrong-type-rel',
          taskA,
          const LifeOsEntityId(
            value: 'note-a',
            entityType: LifeOsEntityType.task,
          ),
        ),
        relationship('collision', taskA, noteA),
      ];
      for (final value in cases) {
        await expectLater(
          repository.save(value),
          throwsA(isA<LifeOsRelationshipPersistenceException>()),
        );
      }
      expect(
        await database.select(database.relationshipRecords).get(),
        isEmpty,
      );
      expect(await database.select(database.outboxEntries).get(), isEmpty);
    },
  );

  test('rejects reversed duplicate and preserves atomic state', () async {
    await repository.save(relationship('rel-1', taskA, noteA));
    await expectLater(
      repository.save(relationship('rel-2', noteA, taskA)),
      throwsA(isA<LifeOsRelationshipPersistenceException>()),
    );
    expect(
      await database.select(database.relationshipRecords).get(),
      hasLength(1),
    );
    expect(await database.select(database.outboxEntries).get(), hasLength(1));
  });

  test('survives close and reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'lifeos-rel-reopen-',
    );
    final file = File('${directory.path}${Platform.pathSeparator}lifeos.db');
    await database.close();
    database = LifeOsDatabase(NativeDatabase(file));
    repository = DriftLifeOsRelationshipRepository(
      database,
      () => 'reopen-change',
      'device-1',
    );
    await _entity(database, 'task-a', 'task');
    await _entity(database, 'note-a', 'note');
    final value = relationship('rel-reopen', taskA, noteA);
    await repository.save(value);
    await database.close();

    database = LifeOsDatabase(NativeDatabase(file));
    repository = DriftLifeOsRelationshipRepository(
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

Future<void> _entity(LifeOsDatabase database, String id, String type) =>
    database
        .into(database.entities)
        .insert(
          EntitiesCompanion.insert(
            id: id,
            entityType: type,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            lifecycle: 'active',
            version: 1,
            source: 'user',
          ),
        );
