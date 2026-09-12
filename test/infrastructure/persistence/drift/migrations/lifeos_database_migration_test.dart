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

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  group('LifeOsDatabase migrations', () {
    test(
      'migrates frozen v1 data to v2 and remains stable after reopen',
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
          2,
          options: const ValidationOptions(validateDropped: true),
        );

        await _expectV1FixturePreserved(migratedDatabase);
        expect(
          await migratedDatabase.select(migratedDatabase.noteRecords).get(),
          isEmpty,
        );
        expect(await _userVersion(migratedDatabase), 2);
        expect(await _foreignKeyViolations(migratedDatabase), isEmpty);
        await migratedDatabase.close();

        final reopenedDatabase = LifeOsDatabase(schema.newConnection());
        await _expectV1FixturePreserved(reopenedDatabase);
        expect(
          await reopenedDatabase.select(reopenedDatabase.noteRecords).get(),
          isEmpty,
        );
        expect(await _userVersion(reopenedDatabase), 2);
        expect(await _foreignKeyViolations(reopenedDatabase), isEmpty);
        await reopenedDatabase.close();
      },
    );

    test('creates a fresh v2 schema equivalent to the frozen schema', () async {
      final database = LifeOsDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await database.customSelect('SELECT 1').get();
      await database.validateDatabaseSchema(
        options: const ValidationOptions(validateDropped: true),
      );

      expect(await _userVersion(database), 2);
      expect(await _userTableNames(database), [
        'entities',
        'notes',
        'outbox',
        'tasks',
      ]);
      expect(await _foreignKeyViolations(database), isEmpty);

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

    test('rolls back the complete migration chain when a step fails', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(1);
      addTearDown(schema.close);

      final oldDatabase = v1.DatabaseAtV1(schema.newConnection());
      await _insertV1Fixture(oldDatabase);
      await oldDatabase.close();

      final failingDatabase = _FailingLifeOsDatabase(schema.newConnection());
      await expectLater(
        failingDatabase.customSelect('SELECT 1').get(),
        throwsA(isA<StateError>()),
      );
      await failingDatabase.close();

      expect(_rawUserVersion(schema), 1);
      expect(_rawUserTableNames(schema), ['entities', 'outbox', 'tasks']);

      final unchangedDatabase = v1.DatabaseAtV1(schema.newConnection());
      expect(
        await unchangedDatabase.select(unchangedDatabase.entities).get(),
        hasLength(1),
      );
      expect(
        await unchangedDatabase.select(unchangedDatabase.tasks).get(),
        hasLength(1),
      );
      expect(
        await unchangedDatabase.select(unchangedDatabase.outbox).get(),
        hasLength(1),
      );
      await unchangedDatabase.close();
    });

    test('rejects a future schema version without mutating it', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(2);
      addTearDown(schema.close);
      schema.rawDatabase.execute('PRAGMA user_version = 3');
      final tablesBefore = _rawUserTableNames(schema);

      final database = LifeOsDatabase(schema.newConnection());
      await expectLater(
        database.customSelect('SELECT 1').get(),
        throwsA(isA<LifeOsUnsupportedSchemaException>()),
      );
      await database.close();

      expect(_rawUserVersion(schema), 3);
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
        await currentDatabase.customStatement('PRAGMA user_version = 3');
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

Future<int> _userVersion(GeneratedDatabase database) async {
  final row = await database.customSelect('PRAGMA user_version').getSingle();
  return row.data.values.single as int;
}

Future<List<QueryRow>> _foreignKeyViolations(GeneratedDatabase database) {
  return database.customSelect('PRAGMA foreign_key_check').get();
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
        1: (migrator) async {
          await migrator.create(noteRecords);
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
