import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'lifeos_database.dart';

const productionDatabaseFileName = 'lifeos.db';

typedef ApplicationSupportDirectoryProvider = Future<Directory> Function();

Future<Directory> resolveApplicationSupportDirectory() {
  return getApplicationSupportDirectory();
}

Future<LifeOsDatabase> openProductionDatabase({
  ApplicationSupportDirectoryProvider applicationSupportDirectoryProvider =
      resolveApplicationSupportDirectory,
}) async {
  final supportDirectory = await applicationSupportDirectoryProvider();

  return openProductionDatabaseIn(supportDirectory);
}

Future<LifeOsDatabase> openProductionDatabaseIn(
  Directory supportDirectory,
) async {
  await supportDirectory.create(recursive: true);

  final databaseFile = File(
    path.join(supportDirectory.path, productionDatabaseFileName),
  );

  final database = LifeOsDatabase(
    NativeDatabase.createInBackground(databaseFile),
  );

  try {
    await database.customSelect('SELECT 1').get();
    return database;
  } on Object {
    await database.close();
    rethrow;
  }
}
