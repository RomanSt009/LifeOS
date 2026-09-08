import '../infrastructure/persistence/drift/lifeos_database.dart';
import '../infrastructure/persistence/drift/production_database.dart';

class LifeOsAppDependencies {
  LifeOsAppDependencies({required this.database});

  final LifeOsDatabase database;

  Future<void>? _closeFuture;

  Future<void> close() => _closeFuture ??= database.close();
}

Future<LifeOsAppDependencies> createProductionDependencies() async {
  return LifeOsAppDependencies(database: await openProductionDatabase());
}
