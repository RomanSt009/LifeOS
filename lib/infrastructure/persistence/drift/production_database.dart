import 'dart:io';

import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'lifeos_database.dart';

const productionDatabaseFileName = 'lifeos.db';

typedef ApplicationSupportDirectoryProvider = Future<Directory> Function();

Future<LifeOsDatabase> openProductionDatabase({
  ApplicationSupportDirectoryProvider applicationSupportDirectoryProvider =
      getApplicationSupportDirectory,
}) async {
  final supportDirectory = await applicationSupportDirectoryProvider();
  await supportDirectory.create(recursive: true);

  final databaseFile = File(
    path.join(supportDirectory.path, productionDatabaseFileName),
  );

  return LifeOsDatabase(NativeDatabase.createInBackground(databaseFile));
}
