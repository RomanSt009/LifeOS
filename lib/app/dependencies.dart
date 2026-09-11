import '../application/use_cases/create_lifeos_backup.dart';
import '../application/use_cases/create_lifeos_task.dart';
import '../application/use_cases/export_lifeos_data.dart';
import '../application/use_cases/search_lifeos_tasks.dart';
import '../domain/repositories/lifeos_task_repository.dart';
import '../infrastructure/backup/formats/v1_backup_export_encoder.dart';
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
    required this.searchTasks,
    required this.createBackup,
    required this.exportData,
  });

  final LifeOsDatabase database;
  final LifeOsTaskRepository taskRepository;
  final CreateLifeOsTask createTask;
  final SearchLifeOsTasks searchTasks;
  final CreateLifeOsBackup createBackup;
  final ExportLifeOsData exportData;

  Future<void>? _closeFuture;

  Future<void> close() => _closeFuture ??= database.close();
}

Future<LifeOsAppDependencies> createProductionDependencies({
  ApplicationSupportDirectoryProvider applicationSupportDirectoryProvider =
      resolveApplicationSupportDirectory,
  IdentifierGenerator identifierGenerator = generateUuidV4,
  EntityIdGenerator entityIdGenerator = generateUuidV4,
  UtcClock utcClock = currentUtcTime,
  String applicationVersion = lifeOsApplicationVersion,
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
  final searchTasks = SearchLifeOsTasks(taskRepository);
  const backupExportEncoder = V1BackupExportEncoder();
  final createBackup = CreateLifeOsBackup(
    taskRepository: taskRepository,
    encoder: backupExportEncoder,
    utcClock: utcClock,
    applicationVersion: applicationVersion,
  );
  final exportData = ExportLifeOsData(
    taskRepository: taskRepository,
    encoder: backupExportEncoder,
    utcClock: utcClock,
    applicationVersion: applicationVersion,
  );

  return LifeOsAppDependencies(
    database: database,
    taskRepository: taskRepository,
    createTask: createTask,
    searchTasks: searchTasks,
    createBackup: createBackup,
    exportData: exportData,
  );
}

const lifeOsApplicationVersion = '1.0.0+1';

DateTime currentUtcTime() => DateTime.now().toUtc();
