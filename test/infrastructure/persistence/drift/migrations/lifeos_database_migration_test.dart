import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/migrations/lifeos_migration_strategy.dart';
import 'package:lifeos/infrastructure/persistence/drift/production_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  group('LifeOsDatabase migrations', () {
    test(
      'migrates frozen v1 data sequentially to v3 and remains stable',
      () async {
        final verifier = SchemaVerifier(GeneratedHelper());
        final schema = await verifier.schemaAt(1);
        addTearDown(schema.close);

        final oldDatabase = v1.DatabaseAtV1(schema.newConnection());
        await _insertV1Fixture(oldDatabase);
        await oldDatabase.close();

        final migratedDatabase = LifeOsDatabase(schema.newConnection());
        await verifier.migrateAndValidate(
          migratedDatabase,
          3,
          options: const ValidationOptions(validateDropped: true),
        );

        await _expectV1FixturePreserved(migratedDatabase);
        expect(
          await migratedDatabase.select(migratedDatabase.noteRecords).get(),
          isEmpty,
        );
        expect(
          await migratedDatabase
              .select(migratedDatabase.relationshipRecords)
              .get(),
          isEmpty,
        );
        expect(await _userVersion(migratedDatabase), 3);
        expect(await _foreignKeyViolations(migratedDatabase), isEmpty);
        expect(await _quickCheck(migratedDatabase), 'ok');
        await migratedDatabase.close();

        final reopenedDatabase = LifeOsDatabase(schema.newConnection());
        await _expectV1FixturePreserved(reopenedDatabase);
        expect(
          await reopenedDatabase.select(reopenedDatabase.noteRecords).get(),
          isEmpty,
        );
        expect(
          await reopenedDatabase
              .select(reopenedDatabase.relationshipRecords)
              .get(),
          isEmpty,
        );
        expect(await _userVersion(reopenedDatabase), 3);
        expect(await _foreignKeyViolations(reopenedDatabase), isEmpty);
        await reopenedDatabase.close();
      },
    );

    test('migrates a file-backed v2 database to schema-equivalent v3 and '
        'preserves Task, Note, and Outbox', () async {
      final directory = await Directory.systemTemp.createTemp(
        'lifeos-v2-to-v3-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}${Platform.pathSeparator}lifeos.db');

      final oldDatabase = v2.DatabaseAtV2(NativeDatabase(file));
      await _insertV2Fixture(oldDatabase);
      await oldDatabase.close();

      final verifier = SchemaVerifier(GeneratedHelper());
      final migratedDatabase = LifeOsDatabase(NativeDatabase(file));
      await verifier.migrateAndValidate(
        migratedDatabase,
        3,
        options: const ValidationOptions(validateDropped: true),
      );

      await _expectV2FixturePreserved(migratedDatabase);
      expect(
        await migratedDatabase
            .select(migratedDatabase.relationshipRecords)
            .get(),
        isEmpty,
      );
      expect(await _userVersion(migratedDatabase), 3);
      expect(await _foreignKeyViolations(migratedDatabase), isEmpty);
      expect(await _quickCheck(migratedDatabase), 'ok');
      await migratedDatabase.close();

      final reopenedDatabase = LifeOsDatabase(NativeDatabase(file));
      await _expectV2FixturePreserved(reopenedDatabase);
      expect(await _userVersion(reopenedDatabase), 3);
      expect(await _foreignKeyViolations(reopenedDatabase), isEmpty);
      await reopenedDatabase.close();
    });

    test('creates a fresh v3 schema equivalent to the frozen schema', () async {
      final database = LifeOsDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.customSelect('SELECT 1').get();
      await database.validateDatabaseSchema(
        options: const ValidationOptions(validateDropped: true),
      );

      expect(await _userVersion(database), 3);
      expect(await _userTableNames(database), [
        'entities',
        'notes',
        'outbox',
        'relationships',
        'tasks',
      ]);
      expect(await _foreignKeyViolations(database), isEmpty);
      expect(await _quickCheck(database), 'ok');

      await expectLater(
        database
            .into(database.noteRecords)
            .insert(
              NoteRecordsCompanion.insert(
                entityId: 'missing-entity',
                title: 'Orphan',
                content: 'Must be rejected',
              ),
            ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'enforces Relationship keys, checks, uniqueness, and indexes',
      () async {
        final database = LifeOsDatabase(NativeDatabase.memory());
        addTearDown(database.close);
        await database.customSelect('SELECT 1').get();
        await _insertRelationshipConstraintEntities(database);

        final foreignKeys = await database
            .customSelect("PRAGMA foreign_key_list('relationships')")
            .get();
        expect(foreignKeys, hasLength(3));
        expect(foreignKeys.map((row) => row.read<String>('from')).toSet(), {
          'entity_id',
          'first_entity_id',
          'second_entity_id',
        });
        expect(
          foreignKeys.map((row) => row.read<String>('on_update')).toSet(),
          {'NO ACTION'},
        );
        expect(
          foreignKeys.map((row) => row.read<String>('on_delete')).toSet(),
          {'NO ACTION'},
        );

        final tableInfo = await database
            .customSelect("PRAGMA table_info('relationships')")
            .get();
        expect(
          tableInfo
              .singleWhere((row) => row.read<String>('name') == 'entity_id')
              .read<int>('pk'),
          1,
        );

        await database
            .into(database.relationshipRecords)
            .insert(
              RelationshipRecordsCompanion.insert(
                entityId: 'relationship-valid',
                firstEntityId: 'a-task',
                secondEntityId: 'b-note',
                kind: 'related',
              ),
            );

        await expectLater(
          database
              .into(database.relationshipRecords)
              .insert(
                RelationshipRecordsCompanion.insert(
                  entityId: 'relationship-self',
                  firstEntityId: 'a-task',
                  secondEntityId: 'a-task',
                  kind: 'related',
                ),
              ),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          database
              .into(database.relationshipRecords)
              .insert(
                RelationshipRecordsCompanion.insert(
                  entityId: 'relationship-reversed',
                  firstEntityId: 'b-note',
                  secondEntityId: 'a-task',
                  kind: 'related',
                ),
              ),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          database
              .into(database.relationshipRecords)
              .insert(
                RelationshipRecordsCompanion.insert(
                  entityId: 'relationship-duplicate',
                  firstEntityId: 'a-task',
                  secondEntityId: 'b-note',
                  kind: 'related',
                ),
              ),
          throwsA(isA<Exception>()),
        );

        await database
            .into(database.relationshipRecords)
            .insert(
              RelationshipRecordsCompanion.insert(
                entityId: 'relationship-other-kind',
                firstEntityId: 'a-task',
                secondEntityId: 'b-note',
                kind: 'future-kind',
              ),
            );
        expect(
          await database.select(database.relationshipRecords).get(),
          hasLength(2),
        );

        final indexes = await database
            .customSelect("PRAGMA index_list('relationships')")
            .get();
        expect(
          indexes.map((row) => row.read<String>('name')),
          contains('relationships_second_entity_id_idx'),
        );
        final secondIndexColumns = await database
            .customSelect(
              "PRAGMA index_info('relationships_second_entity_id_idx')",
            )
            .get();
        expect(
          secondIndexColumns.map((row) => row.read<String>('name')).toList(),
          ['second_entity_id'],
        );
        expect(await _foreignKeyViolations(database), isEmpty);
        expect(await _quickCheck(database), 'ok');
      },
    );

    test('rolls back the complete migration chain when a step fails', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(2);
      addTearDown(schema.close);

      final failingDatabase = _FailingLifeOsDatabase(schema.newConnection());
      await expectLater(
        failingDatabase.customSelect('SELECT 1').get(),
        throwsA(isA<StateError>()),
      );
      await failingDatabase.close();

      expect(_rawUserVersion(schema), 2);
      expect(_rawUserTableNames(schema), [
        'entities',
        'notes',
        'outbox',
        'tasks',
      ]);
    });

    test('rejects a future schema version without mutating it', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(3);
      addTearDown(schema.close);
      schema.rawDatabase.execute('PRAGMA user_version = 4');
      final tablesBefore = _rawUserTableNames(schema);

      final database = LifeOsDatabase(schema.newConnection());
      await expectLater(
        database.customSelect('SELECT 1').get(),
        throwsA(isA<LifeOsUnsupportedSchemaException>()),
      );
      await database.close();

      expect(_rawUserVersion(schema), 4);
      expect(_rawUserTableNames(schema), tablesBefore);
    });

    test(
      'production open does not publish a database before migration succeeds',
      () async {
        final supportDirectory = await Directory.systemTemp.createTemp(
          'lifeos-migration-startup-',
        );
        addTearDown(() => supportDirectory.delete(recursive: true));

        final currentDatabase = await openProductionDatabaseIn(
          supportDirectory,
        );
        await currentDatabase.customStatement('PRAGMA user_version = 4');
        await currentDatabase.close();

        await expectLater(
          openProductionDatabaseIn(supportDirectory),
          throwsA(
            isA<DriftRemoteException>().having(
              (error) => error.remoteCause.toString(),
              'remote cause',
              contains('LifeOsUnsupportedSchemaException'),
            ),
          ),
        );
      },
    );
  });
}

Future<void> _insertV1Fixture(v1.DatabaseAtV1 database) async {
  await database
      .into(database.entities)
      .insert(
        v1.EntitiesCompanion.insert(
          id: 'task-v1',
          entityType: 'task',
          createdAt: _sqliteTimestamp(DateTime.utc(2026, 9, 1, 10)),
          updatedAt: _sqliteTimestamp(DateTime.utc(2026, 9, 1, 11)),
          lifecycle: 'active',
          version: 2,
          source: 'user',
        ),
      );
  await database
      .into(database.tasks)
      .insert(
        v1.TasksCompanion.insert(
          entityId: 'task-v1',
          title: 'Preserve this task',
          isCompleted: 1,
        ),
      );
  await database
      .into(database.outbox)
      .insert(
        v1.OutboxCompanion.insert(
          changeId: 'change-v1',
          entityId: 'task-v1',
          deviceId: 'device-v1',
          operation: 'UPDATE',
          newVersion: 2,
          payload: '{"id":"task-v1"}',
          schemaVersion: 1,
          status: 'pending',
          attemptCount: 0,
          createdAt: _sqliteTimestamp(DateTime.utc(2026, 9, 1, 11)),
        ),
      );
}

Future<void> _insertV2Fixture(v2.DatabaseAtV2 database) async {
  await database.batch((batch) {
    batch.insertAll(database.entities, [
      v2.EntitiesCompanion.insert(
        id: 'task-v2',
        entityType: 'task',
        createdAt: _sqliteTimestamp(DateTime.utc(2026, 9, 2, 10)),
        updatedAt: _sqliteTimestamp(DateTime.utc(2026, 9, 2, 11)),
        lifecycle: 'archived',
        version: 7,
        source: 'user',
      ),
      v2.EntitiesCompanion.insert(
        id: 'note-v2',
        entityType: 'note',
        createdAt: _sqliteTimestamp(DateTime.utc(2026, 9, 2, 12)),
        updatedAt: _sqliteTimestamp(DateTime.utc(2026, 9, 2, 13)),
        lifecycle: 'active',
        version: 4,
        source: 'import',
      ),
    ]);
    batch.insert(
      database.tasks,
      v2.TasksCompanion.insert(
        entityId: 'task-v2',
        title: 'Preserved v2 Task',
        isCompleted: 1,
      ),
    );
    batch.insert(
      database.notes,
      v2.NotesCompanion.insert(
        entityId: 'note-v2',
        title: ' Preserved title ',
        content: '  Exact note content\r\nwith whitespace  ',
      ),
    );
    batch.insert(
      database.outbox,
      v2.OutboxCompanion.insert(
        changeId: 'change-v2',
        entityId: 'note-v2',
        deviceId: 'device-v2',
        operation: 'UPDATE',
        baseVersion: const Value(3),
        newVersion: 4,
        payload: '{"id":"note-v2","content":"  Exact  "}',
        schemaVersion: 1,
        status: 'PENDING',
        attemptCount: 2,
        createdAt: _sqliteTimestamp(DateTime.utc(2026, 9, 2, 13)),
        lastAttemptAt: Value(
          _sqliteTimestamp(DateTime.utc(2026, 9, 2, 13, 30)),
        ),
      ),
    );
  });
}

int _sqliteTimestamp(DateTime value) {
  return value.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
}

Future<void> _expectV1FixturePreserved(LifeOsDatabase database) async {
  final entity = await database.select(database.entities).getSingle();
  expect(entity.id, 'task-v1');
  expect(entity.entityType, 'task');
  expect(entity.createdAt.toUtc(), DateTime.utc(2026, 9, 1, 10));
  expect(entity.updatedAt.toUtc(), DateTime.utc(2026, 9, 1, 11));
  expect(entity.lifecycle, 'active');
  expect(entity.version, 2);
  expect(entity.source, 'user');

  final task = await database.select(database.taskRecords).getSingle();
  expect(task.entityId, 'task-v1');
  expect(task.title, 'Preserve this task');
  expect(task.isCompleted, isTrue);

  final outbox = await database.select(database.outboxEntries).getSingle();
  expect(outbox.changeId, 'change-v1');
  expect(outbox.entityId, 'task-v1');
  expect(outbox.deviceId, 'device-v1');
  expect(outbox.operation, 'UPDATE');
  expect(outbox.newVersion, 2);
  expect(outbox.payload, '{"id":"task-v1"}');
  expect(outbox.schemaVersion, 1);
  expect(outbox.status, 'pending');
  expect(outbox.attemptCount, 0);
}

Future<void> _expectV2FixturePreserved(LifeOsDatabase database) async {
  final entities = await (database.select(
    database.entities,
  )..orderBy([(row) => OrderingTerm.asc(row.id)])).get();
  expect(entities, hasLength(2));

  final noteEntity = entities.singleWhere((row) => row.id == 'note-v2');
  expect(noteEntity.entityType, 'note');
  expect(noteEntity.createdAt.toUtc(), DateTime.utc(2026, 9, 2, 12));
  expect(noteEntity.updatedAt.toUtc(), DateTime.utc(2026, 9, 2, 13));
  expect(noteEntity.lifecycle, 'active');
  expect(noteEntity.version, 4);
  expect(noteEntity.source, 'import');

  final taskEntity = entities.singleWhere((row) => row.id == 'task-v2');
  expect(taskEntity.entityType, 'task');
  expect(taskEntity.createdAt.toUtc(), DateTime.utc(2026, 9, 2, 10));
  expect(taskEntity.updatedAt.toUtc(), DateTime.utc(2026, 9, 2, 11));
  expect(taskEntity.lifecycle, 'archived');
  expect(taskEntity.version, 7);
  expect(taskEntity.source, 'user');

  final task = await database.select(database.taskRecords).getSingle();
  expect(task.entityId, 'task-v2');
  expect(task.title, 'Preserved v2 Task');
  expect(task.isCompleted, isTrue);

  final note = await database.select(database.noteRecords).getSingle();
  expect(note.entityId, 'note-v2');
  expect(note.title, ' Preserved title ');
  expect(note.content, '  Exact note content\r\nwith whitespace  ');

  final outbox = await database.select(database.outboxEntries).getSingle();
  expect(outbox.changeId, 'change-v2');
  expect(outbox.entityId, 'note-v2');
  expect(outbox.deviceId, 'device-v2');
  expect(outbox.operation, 'UPDATE');
  expect(outbox.baseVersion, 3);
  expect(outbox.newVersion, 4);
  expect(outbox.payload, '{"id":"note-v2","content":"  Exact  "}');
  expect(outbox.schemaVersion, 1);
  expect(outbox.status, 'PENDING');
  expect(outbox.attemptCount, 2);
  expect(outbox.createdAt.toUtc(), DateTime.utc(2026, 9, 2, 13));
  expect(outbox.lastAttemptAt?.toUtc(), DateTime.utc(2026, 9, 2, 13, 30));
}

Future<void> _insertRelationshipConstraintEntities(
  LifeOsDatabase database,
) async {
  final timestamp = DateTime.utc(2026, 9, 12);
  await database.batch((batch) {
    batch.insertAll(
      database.entities,
      [
        ('a-task', 'task'),
        ('b-note', 'note'),
        ('relationship-valid', 'relationship'),
        ('relationship-self', 'relationship'),
        ('relationship-reversed', 'relationship'),
        ('relationship-duplicate', 'relationship'),
        ('relationship-other-kind', 'relationship'),
      ].map(
        (entry) => EntitiesCompanion.insert(
          id: entry.$1,
          entityType: entry.$2,
          createdAt: timestamp,
          updatedAt: timestamp,
          lifecycle: 'active',
          version: 1,
          source: 'user',
        ),
      ),
    );
  });
}

Future<int> _userVersion(GeneratedDatabase database) async {
  final row = await database.customSelect('PRAGMA user_version').getSingle();
  return row.data.values.single as int;
}

Future<List<QueryRow>> _foreignKeyViolations(GeneratedDatabase database) {
  return database.customSelect('PRAGMA foreign_key_check').get();
}

Future<String> _quickCheck(GeneratedDatabase database) async {
  final row = await database.customSelect('PRAGMA quick_check').getSingle();
  return row.data.values.single as String;
}

Future<List<String>> _userTableNames(GeneratedDatabase database) async {
  final rows = await database
      .customSelect(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  return rows.map((row) => row.read<String>('name')).toList();
}

int _rawUserVersion(InitializedSchema schema) {
  return schema.rawDatabase.select('PRAGMA user_version').single.columnAt(0)
      as int;
}

List<String> _rawUserTableNames(InitializedSchema schema) {
  return schema.rawDatabase
      .select(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .map((row) => row['name'] as String)
      .toList();
}

final class _FailingLifeOsDatabase extends LifeOsDatabase {
  _FailingLifeOsDatabase(super.executor);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) => runLifeOsMigrationChain(
      database: this,
      migrator: migrator,
      from: from,
      to: to,
      steps: {
        2: (migrator) async {
          await migrator.create(relationshipRecords);
          await migrator.create(relationshipsSecondEntityIdIdx);
          await customStatement(
            'CREATE TABLE migration_partial (id INTEGER PRIMARY KEY)',
          );
          throw StateError('Controlled migration failure');
        },
      },
    ),
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
