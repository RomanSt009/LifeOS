import 'package:drift/drift.dart';

Future<void> migrateV3ToV4(
  Migrator migrator,
  DatabaseSchemaEntity workspacesTable,
  DatabaseSchemaEntity workspaceMembershipsTable,
  DatabaseSchemaEntity workspaceMembershipsMemberEntityIdIndex,
) async {
  await migrator.create(workspacesTable);
  await migrator.create(workspaceMembershipsTable);
  await migrator.create(workspaceMembershipsMemberEntityIdIndex);
}
