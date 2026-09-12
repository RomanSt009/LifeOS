import 'package:drift/drift.dart';

Future<void> migrateV1ToV2(Migrator migrator, DatabaseSchemaEntity notesTable) {
  return migrator.create(notesTable);
}
