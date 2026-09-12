import 'package:drift/drift.dart';

Future<void> migrateV2ToV3(
  Migrator migrator,
  DatabaseSchemaEntity relationshipsTable,
  DatabaseSchemaEntity relationshipsSecondEntityIdIndex,
) async {
  await migrator.create(relationshipsTable);
  await migrator.create(relationshipsSecondEntityIdIndex);
}
