import '../application/use_cases/create_lifeos_backup.dart';
import '../application/use_cases/create_lifeos_note.dart';
import '../application/use_cases/create_lifeos_task.dart';
import '../application/use_cases/edit_lifeos_note.dart';
import '../application/use_cases/export_lifeos_data.dart';
import '../application/use_cases/restore_lifeos_backup.dart';
import '../application/use_cases/search_lifeos_tasks.dart';
import '../application/backup/lifeos_backup_operations.dart';
import '../domain/repositories/lifeos_task_repository.dart';
import '../domain/repositories/lifeos_note_repository.dart';
import '../infrastructure/backup/files/lifeos_backup_file_reader.dart';
import '../infrastructure/backup/formats/v2_backup_export_encoder.dart';
import '../infrastructure/identity/file_device_identity_store.dart';
import '../infrastructure/identity/uuid_v4_generator.dart';
import '../infrastructure/persistence/drift/lifeos_database.dart';
import '../infrastructure/persistence/drift/production_database.dart';
import '../infrastructure/persistence/drift/repositories/drift_lifeos_task_repository.dart';
import '../infrastructure/persistence/drift/repositories/drift_lifeos_note_repository.dart';
import '../infrastructure/persistence/drift/restore/drift_lifeos_backup_restore_store.dart';
import 'backup_operations.dart';

class LifeOsAppDependencies {
  LifeOsAppDependencies({
    required this.database,
    required this.taskRepository,
    required this.noteRepository,
    required this.createTask,
    required this.createNote,
    required this.editNote,
    required this.searchTasks,
    required this.createBackup,
    required this.exportData,
    required this.restoreBackup,
    required this.backupOperations,
  });

  final LifeOsDatabase database;
  final LifeOsTaskRepository taskRepository;
  final LifeOsNoteRepository noteRepository;
  final CreateLifeOsTask createTask;
  final CreateLifeOsNote createNote;
  final EditLifeOsNote editNote;
  final SearchLifeOsTasks searchTasks;
  final CreateLifeOsBackup createBackup;
  final ExportLifeOsData exportData;
  final RestoreLifeOsBackup restoreBackup;
  final LifeOsBackupOperations backupOperations;

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
  final noteRepository = DriftLifeOsNoteRepository(
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
  final createNote = CreateLifeOsNote(
    repository: noteRepository,
    entityIdGenerator: entityIdGenerator,
    utcClock: utcClock,
  );
  final editNote = EditLifeOsNote(
    repository: noteRepository,
    utcClock: utcClock,
  );
  const backupExportEncoder = V2BackupExportEncoder();
  final createBackup = CreateLifeOsBackup(
    taskRepository: taskRepository,
    noteRepository: noteRepository,
    encoder: backupExportEncoder,
    utcClock: utcClock,
    applicationVersion: applicationVersion,
    backupFormatVersion: 2,
  );
  final exportData = ExportLifeOsData(
    taskRepository: taskRepository,
    noteRepository: noteRepository,
    encoder: backupExportEncoder,
    utcClock: utcClock,
    applicationVersion: applicationVersion,
  );
  final restoreBackup = RestoreLifeOsBackup(
    reader: const LifeOsBackupFileReader(),
    restoreStore: DriftLifeOsBackupRestoreStore(database),
  );
  final backupOperations = ComposedLifeOsBackupOperations(
    createBackup: createBackup,
    exportData: exportData,
    restoreBackup: restoreBackup,
    sourceDatabaseSchemaVersion: database.schemaVersion,
  );

  return LifeOsAppDependencies(
    database: database,
    taskRepository: taskRepository,
    noteRepository: noteRepository,
    createTask: createTask,
    createNote: createNote,
    editNote: editNote,
    searchTasks: searchTasks,
    createBackup: createBackup,
    exportData: exportData,
    restoreBackup: restoreBackup,
    backupOperations: backupOperations,
  );
}

const lifeOsApplicationVersion = '1.0.0+1';

DateTime currentUtcTime() => DateTime.now().toUtc();
