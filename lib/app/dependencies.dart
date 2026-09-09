import '../application/use_cases/create_lifeos_task.dart';
import '../domain/repositories/lifeos_task_repository.dart';
import '../infrastructure/identity/file_device_identity_store.dart';
import '../infrastructure/identity/uuid_v4_generator.dart';
import '../infrastructure/persistence/drift/lifeos_database.dart';
import '../infrastructure/persistence/drift/production_database.dart';
import '../infrastructure/persistence/drift/repositories/drift_lifeos_task_repository.dart';

class LifeOsAppDependencies {
  LifeOsAppDependencies({
    required this.database,
    required this.taskRepository,
    required this.createTask,
  });

  final LifeOsDatabase database;
  final LifeOsTaskRepository taskRepository;
  final CreateLifeOsTask createTask;

  Future<void>? _closeFuture;

  Future<void> close() => _closeFuture ??= database.close();
}

Future<LifeOsAppDependencies> createProductionDependencies({
  ApplicationSupportDirectoryProvider applicationSupportDirectoryProvider =
      resolveApplicationSupportDirectory,
  IdentifierGenerator identifierGenerator = generateUuidV4,
  EntityIdGenerator entityIdGenerator = generateUuidV4,
  UtcClock utcClock = currentUtcTime,
}) async {
  final supportDirectory = await applicationSupportDirectoryProvider();
  final deviceId = await FileDeviceIdentityStore(
    supportDirectory,
    identifierGenerator,
  ).resolve();
  final database = await openProductionDatabaseIn(supportDirectory);
  final taskRepository = DriftLifeOsTaskRepository(
    database,
    identifierGenerator,
    deviceId,
  );
  final createTask = CreateLifeOsTask(
    repository: taskRepository,
    entityIdGenerator: entityIdGenerator,
    utcClock: utcClock,
  );

  return LifeOsAppDependencies(
    database: database,
    taskRepository: taskRepository,
    createTask: createTask,
  );
}

DateTime currentUtcTime() => DateTime.now().toUtc();
