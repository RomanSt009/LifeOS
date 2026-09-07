import 'package:drift/drift.dart';

part 'lifeos_database.g.dart';

@DataClassName('EntityRecord')
class Entities extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get lifecycle => text()();
  IntColumn get version => integer()();
  TextColumn get source => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('TaskRecord')
class TaskRecords extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get entityId => text().references(Entities, #id)();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {entityId};
}

@DataClassName('OutboxEntryRecord')
class OutboxEntries extends Table {
  @override
  String get tableName => 'outbox';

  TextColumn get changeId => text()();
  TextColumn get entityId => text().references(Entities, #id)();
  TextColumn get deviceId => text()();
  TextColumn get operation => text()();
  IntColumn get baseVersion => integer().nullable()();
  IntColumn get newVersion => integer()();
  TextColumn get payload => text()();
  IntColumn get schemaVersion => integer()();
  TextColumn get status => text()();
  IntColumn get attemptCount => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {changeId};
}

@DriftDatabase(tables: [Entities, TaskRecords, OutboxEntries])
class LifeOsDatabase extends _$LifeOsDatabase {
  LifeOsDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
