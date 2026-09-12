import 'package:drift/drift.dart';

import 'migrations/lifeos_migration_strategy.dart';

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

@DataClassName('NoteRecord')
class NoteRecords extends Table {
  @override
  String get tableName => 'notes';

  TextColumn get entityId => text().references(Entities, #id)();
  TextColumn get title => text()();
  TextColumn get content => text()();

  @override
  Set<Column<Object>> get primaryKey => {entityId};
}

@DataClassName('RelationshipRecord')
@TableIndex(
  name: 'relationships_second_entity_id_idx',
  columns: {#secondEntityId},
)
class RelationshipRecords extends Table {
  @override
  String get tableName => 'relationships';

  @ReferenceName('relationshipIdentity')
  TextColumn get entityId => text().references(Entities, #id)();

  @ReferenceName('firstEndpointRelationships')
  TextColumn get firstEntityId => text().references(Entities, #id)();

  @ReferenceName('secondEndpointRelationships')
  TextColumn get secondEntityId => text().references(Entities, #id)();
  TextColumn get kind => text()();

  @override
  Set<Column<Object>> get primaryKey => {entityId};

  @override
  List<String> get customConstraints => [
    'CHECK (first_entity_id <> second_entity_id)',
    'CHECK (first_entity_id < second_entity_id)',
    'UNIQUE (first_entity_id, second_entity_id, kind)',
  ];
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

@DriftDatabase(
  tables: [
    Entities,
    TaskRecords,
    NoteRecords,
    RelationshipRecords,
    OutboxEntries,
  ],
)
class LifeOsDatabase extends _$LifeOsDatabase {
  LifeOsDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => createLifeOsMigrationStrategy(
    database: this,
    notesTable: noteRecords,
    relationshipsTable: relationshipRecords,
    relationshipsSecondEntityIdIndex: relationshipsSecondEntityIdIdx,
  );
}
