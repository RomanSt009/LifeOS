import 'package:drift/drift.dart';

import 'lifeos_migration_validation.dart';
import 'v1_to_v2.dart';
import 'v2_to_v3.dart';

typedef LifeOsMigrationStep = Future<void> Function(Migrator migrator);

final class LifeOsUnsupportedSchemaException implements Exception {
  const LifeOsUnsupportedSchemaException({
    required this.from,
    required this.to,
  });

  final int from;
  final int to;

  @override
  String toString() =>
      'LifeOsUnsupportedSchemaException: unsupported schema transition '
      '$from -> $to.';
}

MigrationStrategy createLifeOsMigrationStrategy({
  required GeneratedDatabase database,
  required DatabaseSchemaEntity notesTable,
  required DatabaseSchemaEntity relationshipsTable,
  required DatabaseSchemaEntity relationshipsSecondEntityIdIndex,
}) {
  return MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) => runLifeOsMigrationChain(
      database: database,
      migrator: migrator,
      from: from,
      to: to,
      steps: {
        1: (migrator) => migrateV1ToV2(migrator, notesTable),
        2: (migrator) => migrateV2ToV3(
          migrator,
          relationshipsTable,
          relationshipsSecondEntityIdIndex,
        ),
      },
    ),
    beforeOpen: (_) async {
      await database.customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

Future<void> runLifeOsMigrationChain({
  required GeneratedDatabase database,
  required Migrator migrator,
  required int from,
  required int to,
  required Map<int, LifeOsMigrationStep> steps,
}) async {
  if (from < 1 || from >= to || to > database.schemaVersion) {
    throw LifeOsUnsupportedSchemaException(from: from, to: to);
  }

  await database.customStatement('PRAGMA foreign_keys = ON');

  await database.transaction(() async {
    var currentVersion = from;
    while (currentVersion < to) {
      final step = steps[currentVersion];
      if (step == null) {
        throw LifeOsUnsupportedSchemaException(
          from: currentVersion,
          to: currentVersion + 1,
        );
      }

      await step(migrator);
      currentVersion += 1;
    }

    await validateLifeOsMigration(database);
  });
}
