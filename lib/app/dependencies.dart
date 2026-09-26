import 'package:http/http.dart' as http;

import '../application/use_cases/check_lifeos_local_ai_availability.dart';
import '../application/use_cases/create_lifeos_backup.dart';
import '../application/use_cases/create_lifeos_note.dart';
import '../application/use_cases/create_lifeos_relationship.dart';
import '../application/use_cases/create_lifeos_task.dart';
import '../application/use_cases/create_lifeos_entity_in_workspace.dart';
import '../application/use_cases/create_lifeos_workspace.dart';
import '../application/use_cases/edit_lifeos_workspace.dart';
import '../application/use_cases/get_lifeos_workspace_context.dart';
import '../application/use_cases/get_lifeos_workspaces.dart';
import '../application/use_cases/get_direct_lifeos_related_neighbors.dart';
import '../application/use_cases/lifeos_workspace_lifecycle.dart';
import '../application/use_cases/lifeos_workspace_membership.dart';
import '../application/use_cases/edit_lifeos_note.dart';
import '../application/use_cases/edit_lifeos_task_title.dart';
import '../application/use_cases/delete_lifeos_task.dart';
import '../application/use_cases/restore_lifeos_task.dart';
import '../application/use_cases/delete_lifeos_note.dart';
import '../application/use_cases/restore_lifeos_note.dart';
import '../application/use_cases/unlink_lifeos_relationship.dart';
import '../application/use_cases/export_lifeos_data.dart';
import '../application/use_cases/restore_lifeos_backup.dart';
import '../application/use_cases/search_lifeos_entities.dart';
import '../application/backup/lifeos_backup_operations.dart';
import '../application/relationships/lifeos_related_entity_reader.dart';
import '../domain/repositories/lifeos_task_repository.dart';
import '../domain/repositories/lifeos_note_repository.dart';
import '../domain/repositories/lifeos_relationship_repository.dart';
import '../domain/repositories/lifeos_workspace_membership_repository.dart';
import '../domain/repositories/lifeos_workspace_repository.dart';
import '../infrastructure/ai/ollama/lifeos_ollama_http_transport.dart';
import '../infrastructure/ai/ollama/ollama_lifeos_local_ai_availability_reader.dart';
import '../infrastructure/backup/files/lifeos_backup_file_reader.dart';
import '../infrastructure/backup/formats/v4_backup_export_encoder.dart';
import '../infrastructure/identity/file_device_identity_store.dart';
import '../infrastructure/identity/uuid_v4_generator.dart';
import '../infrastructure/persistence/drift/lifeos_database.dart';
import '../infrastructure/persistence/drift/production_database.dart';
import '../infrastructure/persistence/drift/repositories/drift_lifeos_task_repository.dart';
import '../infrastructure/persistence/drift/repositories/drift_lifeos_note_repository.dart';
import '../infrastructure/persistence/drift/repositories/drift_lifeos_relationship_repository.dart';
import '../infrastructure/persistence/drift/repositories/drift_lifeos_workspace_membership_repository.dart';
import '../infrastructure/persistence/drift/repositories/drift_lifeos_workspace_repository.dart';
import '../infrastructure/persistence/drift/relationships/drift_lifeos_related_entity_reader.dart';
import '../infrastructure/persistence/drift/restore/drift_lifeos_backup_restore_store.dart';
import '../infrastructure/persistence/drift/search/drift_lifeos_unified_search_reader.dart';
import '../infrastructure/persistence/drift/workspaces/drift_lifeos_workspace_context_reader.dart';
import '../infrastructure/persistence/drift/workspaces/drift_lifeos_workspace_member_creation_store.dart';
import 'backup_operations.dart';

class LifeOsAppDependencies {
  LifeOsAppDependencies({
    required this.database,
    required this.taskRepository,
    required this.noteRepository,
    required this.relationshipRepository,
    required this.relatedEntityReader,
    required this.workspaceRepository,
    required this.workspaceMembershipRepository,
    required this.createTask,
    required this.editTaskTitle,
    required this.deleteTask,
    required this.restoreTask,
    required this.createNote,
    required this.editNote,
    required this.deleteNote,
    required this.restoreNote,
    required this.createRelationship,
    required this.unlinkRelationship,
    required this.getDirectRelatedNeighbors,
    required this.searchEntities,
    required this.createWorkspace,
    required this.editWorkspace,
    required this.getWorkspace,
    required this.getWorkspaces,
    required this.getDeletedWorkspaces,
    required this.deleteWorkspace,
    required this.restoreWorkspace,
    required this.attachWorkspaceMember,
    required this.detachWorkspaceMember,
    required this.getWorkspaceMembers,
    required this.getUnassignedWorkspaceMembers,
    required this.createTaskInWorkspace,
    required this.createNoteInWorkspace,
    required this.createBackup,
    required this.exportData,
    required this.restoreBackup,
    required this.backupOperations,
    required http.Client localAiHttpClient,
    required this.checkLocalAiAvailability,
  }) : _localAiHttpClient = localAiHttpClient;

  final LifeOsDatabase database;
  final LifeOsTaskRepository taskRepository;
  final LifeOsNoteRepository noteRepository;
  final LifeOsRelationshipRepository relationshipRepository;
  final LifeOsRelatedEntityReader relatedEntityReader;
  final LifeOsWorkspaceRepository workspaceRepository;
  final LifeOsWorkspaceMembershipRepository workspaceMembershipRepository;
  final CreateLifeOsTask createTask;
  final EditLifeOsTaskTitle editTaskTitle;
  final DeleteLifeOsTask deleteTask;
  final RestoreLifeOsTask restoreTask;
  final CreateLifeOsNote createNote;
  final EditLifeOsNote editNote;
  final DeleteLifeOsNote deleteNote;
  final RestoreLifeOsNote restoreNote;
  final CreateLifeOsRelationship createRelationship;
  final UnlinkLifeOsRelationship unlinkRelationship;
  final GetDirectLifeOsRelatedNeighbors getDirectRelatedNeighbors;
  final SearchLifeOsEntities searchEntities;
  final CreateLifeOsWorkspace createWorkspace;
  final EditLifeOsWorkspace editWorkspace;
  final GetLifeOsWorkspace getWorkspace;
  final GetLifeOsWorkspaces getWorkspaces;
  final GetDeletedLifeOsWorkspaces getDeletedWorkspaces;
  final DeleteLifeOsWorkspace deleteWorkspace;
  final RestoreLifeOsWorkspace restoreWorkspace;
  final AttachLifeOsWorkspaceMember attachWorkspaceMember;
  final DetachLifeOsWorkspaceMember detachWorkspaceMember;
  final GetLifeOsWorkspaceMembers getWorkspaceMembers;
  final GetUnassignedLifeOsWorkspaceMembers getUnassignedWorkspaceMembers;
  final CreateLifeOsTaskInWorkspace createTaskInWorkspace;
  final CreateLifeOsNoteInWorkspace createNoteInWorkspace;
  final CreateLifeOsBackup createBackup;
  final ExportLifeOsData exportData;
  final RestoreLifeOsBackup restoreBackup;
  final LifeOsBackupOperations backupOperations;
  final CheckLifeOsLocalAiAvailability checkLocalAiAvailability;
  final http.Client _localAiHttpClient;

  Future<void>? _closeFuture;

  Future<void> close() => _closeFuture ??= _closeOwnedResources();

  Future<void> _closeOwnedResources() async {
    _localAiHttpClient.close();
    await database.close();
  }
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
  final relationshipRepository = DriftLifeOsRelationshipRepository(
    database,
    identifierGenerator,
    deviceId,
  );
  final relatedEntityReader = DriftLifeOsRelatedEntityReader(database);
  final workspaceRepository = DriftLifeOsWorkspaceRepository(
    database,
    identifierGenerator,
    deviceId,
  );
  final workspaceMembershipRepository =
      DriftLifeOsWorkspaceMembershipRepository(
        database,
        identifierGenerator,
        deviceId,
      );
  final workspaceContextReader = DriftLifeOsWorkspaceContextReader(database);
  final workspaceMemberCreationStore = DriftLifeOsWorkspaceMemberCreationStore(
    database,
    identifierGenerator,
    deviceId,
  );
  final createTask = CreateLifeOsTask(
    repository: taskRepository,
    entityIdGenerator: entityIdGenerator,
    utcClock: utcClock,
  );
  final searchEntities = SearchLifeOsEntities(
    DriftLifeOsUnifiedSearchReader(database),
  );
  final editTaskTitle = EditLifeOsTaskTitle(
    repository: taskRepository,
    utcClock: utcClock,
  );
  final deleteTask = DeleteLifeOsTask(
    repository: taskRepository,
    utcClock: utcClock,
  );
  final restoreTask = RestoreLifeOsTask(
    repository: taskRepository,
    utcClock: utcClock,
  );
  final createNote = CreateLifeOsNote(
    repository: noteRepository,
    entityIdGenerator: entityIdGenerator,
    utcClock: utcClock,
  );
  final editNote = EditLifeOsNote(
    repository: noteRepository,
    utcClock: utcClock,
  );
  final deleteNote = DeleteLifeOsNote(
    repository: noteRepository,
    utcClock: utcClock,
  );
  final restoreNote = RestoreLifeOsNote(
    repository: noteRepository,
    utcClock: utcClock,
  );
  final createRelationship = CreateLifeOsRelationship(
    relationshipRepository: relationshipRepository,
    taskRepository: taskRepository,
    noteRepository: noteRepository,
    entityIdGenerator: entityIdGenerator,
    utcClock: utcClock,
  );
  final unlinkRelationship = UnlinkLifeOsRelationship(
    repository: relationshipRepository,
    utcClock: utcClock,
  );
  final getDirectRelatedNeighbors = GetDirectLifeOsRelatedNeighbors(
    relatedEntityReader,
  );
  final createWorkspace = CreateLifeOsWorkspace(
    repository: workspaceRepository,
    entityIdGenerator: entityIdGenerator,
    utcClock: utcClock,
  );
  final editWorkspace = EditLifeOsWorkspace(
    repository: workspaceRepository,
    utcClock: utcClock,
  );
  final getWorkspace = GetLifeOsWorkspace(workspaceRepository);
  final getWorkspaces = GetLifeOsWorkspaces(workspaceRepository);
  final getDeletedWorkspaces = GetDeletedLifeOsWorkspaces(workspaceRepository);
  final deleteWorkspace = DeleteLifeOsWorkspace(
    repository: workspaceRepository,
    utcClock: utcClock,
  );
  final restoreWorkspace = RestoreLifeOsWorkspace(
    repository: workspaceRepository,
    utcClock: utcClock,
  );
  final attachWorkspaceMember = AttachLifeOsWorkspaceMember(
    repository: workspaceMembershipRepository,
    entityIdGenerator: entityIdGenerator,
    utcClock: utcClock,
  );
  final detachWorkspaceMember = DetachLifeOsWorkspaceMember(
    repository: workspaceMembershipRepository,
    utcClock: utcClock,
  );
  final getWorkspaceMembers = GetLifeOsWorkspaceMembers(workspaceContextReader);
  final getUnassignedWorkspaceMembers = GetUnassignedLifeOsWorkspaceMembers(
    workspaceContextReader,
  );
  final createTaskInWorkspace = CreateLifeOsTaskInWorkspace(
    workspaceRepository: workspaceRepository,
    store: workspaceMemberCreationStore,
    entityIdGenerator: entityIdGenerator,
    utcClock: utcClock,
  );
  final createNoteInWorkspace = CreateLifeOsNoteInWorkspace(
    workspaceRepository: workspaceRepository,
    store: workspaceMemberCreationStore,
    entityIdGenerator: entityIdGenerator,
    utcClock: utcClock,
  );
  const backupExportEncoder = V4BackupExportEncoder();
  final createBackup = CreateLifeOsBackup(
    taskRepository: taskRepository,
    noteRepository: noteRepository,
    relationshipRepository: relationshipRepository,
    workspaceRepository: workspaceRepository,
    workspaceMembershipRepository: workspaceMembershipRepository,
    encoder: backupExportEncoder,
    utcClock: utcClock,
    applicationVersion: applicationVersion,
    backupFormatVersion: 4,
  );
  final exportData = ExportLifeOsData(
    taskRepository: taskRepository,
    noteRepository: noteRepository,
    relationshipRepository: relationshipRepository,
    workspaceRepository: workspaceRepository,
    workspaceMembershipRepository: workspaceMembershipRepository,
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
  final localAiHttpClient = createDirectLifeOsOllamaHttpClient();
  final localAiTransport = FixedLoopbackLifeOsOllamaHttpTransport(
    localAiHttpClient,
  );
  final checkLocalAiAvailability = CheckLifeOsLocalAiAvailability(
    OllamaLifeOsLocalAiAvailabilityReader(localAiTransport),
  );

  return LifeOsAppDependencies(
    database: database,
    taskRepository: taskRepository,
    noteRepository: noteRepository,
    relationshipRepository: relationshipRepository,
    relatedEntityReader: relatedEntityReader,
    workspaceRepository: workspaceRepository,
    workspaceMembershipRepository: workspaceMembershipRepository,
    createTask: createTask,
    editTaskTitle: editTaskTitle,
    deleteTask: deleteTask,
    restoreTask: restoreTask,
    createNote: createNote,
    editNote: editNote,
    deleteNote: deleteNote,
    restoreNote: restoreNote,
    createRelationship: createRelationship,
    unlinkRelationship: unlinkRelationship,
    getDirectRelatedNeighbors: getDirectRelatedNeighbors,
    searchEntities: searchEntities,
    createWorkspace: createWorkspace,
    editWorkspace: editWorkspace,
    getWorkspace: getWorkspace,
    getWorkspaces: getWorkspaces,
    getDeletedWorkspaces: getDeletedWorkspaces,
    deleteWorkspace: deleteWorkspace,
    restoreWorkspace: restoreWorkspace,
    attachWorkspaceMember: attachWorkspaceMember,
    detachWorkspaceMember: detachWorkspaceMember,
    getWorkspaceMembers: getWorkspaceMembers,
    getUnassignedWorkspaceMembers: getUnassignedWorkspaceMembers,
    createTaskInWorkspace: createTaskInWorkspace,
    createNoteInWorkspace: createNoteInWorkspace,
    createBackup: createBackup,
    exportData: exportData,
    restoreBackup: restoreBackup,
    backupOperations: backupOperations,
    localAiHttpClient: localAiHttpClient,
    checkLocalAiAvailability: checkLocalAiAvailability,
  );
}

const lifeOsApplicationVersion = '1.0.0+1';

DateTime currentUtcTime() => DateTime.now().toUtc();
