import 'dart:ui' show AppExitResponse;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:lifeos/app/app.dart';
import 'package:lifeos/app/bootstrap.dart';
import 'package:lifeos/app/dependencies.dart';
import 'package:lifeos/application/ai/lifeos_ai_provider.dart';
import 'package:lifeos/application/ai/lifeos_local_ai_availability.dart';
import 'package:lifeos/application/use_cases/ask_about_lifeos_workspace.dart';
import 'package:lifeos/application/use_cases/build_lifeos_ai_context.dart';
import 'package:lifeos/application/use_cases/check_lifeos_local_ai_availability.dart';
import 'package:lifeos/application/use_cases/create_lifeos_backup.dart';
import 'package:lifeos/application/use_cases/create_lifeos_note.dart';
import 'package:lifeos/application/use_cases/create_lifeos_relationship.dart';
import 'package:lifeos/application/backup/lifeos_backup_operations.dart';
import 'package:lifeos/application/use_cases/create_lifeos_task.dart';
import 'package:lifeos/application/use_cases/create_lifeos_entity_in_workspace.dart';
import 'package:lifeos/application/use_cases/create_lifeos_workspace.dart';
import 'package:lifeos/application/use_cases/export_lifeos_data.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_note.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_task_title.dart';
import 'package:lifeos/application/use_cases/delete_lifeos_task.dart';
import 'package:lifeos/application/use_cases/restore_lifeos_task.dart';
import 'package:lifeos/application/use_cases/delete_lifeos_note.dart';
import 'package:lifeos/application/use_cases/restore_lifeos_note.dart';
import 'package:lifeos/application/use_cases/request_lifeos_ai_completion.dart';
import 'package:lifeos/application/use_cases/restore_lifeos_backup.dart';
import 'package:lifeos/application/use_cases/search_lifeos_entities.dart';
import 'package:lifeos/application/use_cases/unlink_lifeos_relationship.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_workspace.dart';
import 'package:lifeos/application/use_cases/get_lifeos_workspace_context.dart';
import 'package:lifeos/application/use_cases/get_lifeos_workspaces.dart';
import 'package:lifeos/application/use_cases/get_direct_lifeos_related_neighbors.dart';
import 'package:lifeos/application/use_cases/lifeos_workspace_lifecycle.dart';
import 'package:lifeos/application/use_cases/lifeos_workspace_membership.dart';
import 'package:lifeos/infrastructure/backup/files/lifeos_backup_file_reader.dart';
import 'package:lifeos/infrastructure/backup/formats/v1_backup_export_encoder.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_task_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_note_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_relationship_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_workspace_membership_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_workspace_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/relationships/drift_lifeos_related_entity_reader.dart';
import 'package:lifeos/infrastructure/persistence/drift/restore/drift_lifeos_backup_restore_store.dart';
import 'package:lifeos/infrastructure/persistence/drift/search/drift_lifeos_unified_search_reader.dart';
import 'package:lifeos/infrastructure/persistence/drift/workspaces/drift_lifeos_workspace_context_reader.dart';
import 'package:lifeos/infrastructure/persistence/drift/workspaces/drift_lifeos_workspace_member_creation_store.dart';
import 'package:lifeos/presentation/search/unified_search_providers.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';
import 'package:lifeos/presentation/tasks/task_list_providers.dart';

void main() {
  testWidgets('closes the owned database when the app lifecycle ends', (
    tester,
  ) async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    final dependencies = _createTestDependencies(database);

    await tester.pumpWidget(LifeOSApp(dependencies: dependencies));
    await database.customSelect('SELECT 1').get();

    await tester.pumpWidget(const SizedBox.shrink());
    await dependencies.close();

    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('clean app exit closes without a confirmation dialog', (
    tester,
  ) async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    final dependencies = _createTestDependencies(database);
    await tester.pumpWidget(LifeOSApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    final response = await tester.binding.handleRequestAppExit();

    expect(response, AppExitResponse.exit);
    expect(find.byType(AlertDialog), findsNothing);
    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(isA<StateError>()),
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'dirty Note cancels duplicate app exits and can later discard once',
    (tester) async {
      final database = LifeOsDatabase(NativeDatabase.memory());
      final dependencies = _createTestDependencies(database);
      await tester.pumpWidget(LifeOSApp(dependencies: dependencies));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('navigation-notes-label')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('note-content-field')),
        'Draft protected from app close',
      );
      await tester.pump();

      final firstExit = tester.binding.handleRequestAppExit();
      await tester.pumpAndSettle();
      final repeatedExit = tester.binding.handleRequestAppExit();
      await tester.pump();
      expect(find.text('Save changes to this Note?'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.byKey(const Key('unsaved-note-cancel')));
      await tester.pumpAndSettle();
      expect(await firstExit, AppExitResponse.cancel);
      expect(await repeatedExit, AppExitResponse.cancel);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('note-content-field')))
            .controller!
            .text,
        'Draft protected from app close',
      );
      expect(find.byKey(const Key('note-unsaved-indicator')), findsOneWidget);
      await database.customSelect('SELECT 1').get();

      final discardedExit = tester.binding.handleRequestAppExit();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.byKey(const Key('unsaved-note-discard')));
      await tester.pumpAndSettle();
      expect(await discardedExit, AppExitResponse.exit);
      await expectLater(
        database.customSelect('SELECT 1').get(),
        throwsA(isA<StateError>()),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('startup failure is recoverable through Retry', (tester) async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    final dependencies = _createTestDependencies(database);
    var attempts = 0;
    await tester.pumpWidget(
      LifeOSBootstrap(
        createDependencies: () async {
          attempts += 1;
          if (attempts == 1) {
            throw StateError('Expected startup failure.');
          }
          return dependencies;
        },
        exitApplication: () async {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LifeOS could not start'), findsOneWidget);
    expect(find.textContaining('Expected startup failure'), findsNothing);
    expect(find.byKey(const Key('startup-retry-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('startup-retry-button')));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.byType(LifeOSApp), findsOneWidget);
    await database.customSelect('SELECT 1').get();
    await tester.pumpWidget(const SizedBox.shrink());
    await dependencies.close();
  });

  testWidgets('startup failure localizes Exit and does not retry implicitly', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localesTestValue = const [Locale('ru')];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    var attempts = 0;
    var exits = 0;
    await tester.pumpWidget(
      LifeOSBootstrap(
        createDependencies: () async {
          attempts += 1;
          throw StateError('Expected startup failure.');
        },
        exitApplication: () async {
          exits += 1;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Не удалось запустить LifeOS'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Выйти из LifeOS'), findsOneWidget);
    expect(attempts, 1);

    await tester.tap(find.byKey(const Key('startup-exit-button')));
    await tester.pump();
    expect(exits, 1);
    expect(attempts, 1);
  });

  testWidgets('provides the composed Domain repository to Presentation', (
    tester,
  ) async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    final dependencies = _createTestDependencies(database);
    final repository = dependencies.taskRepository;

    await tester.pumpWidget(LifeOSApp(dependencies: dependencies));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    expect(container.read(lifeOsTaskRepositoryProvider), same(repository));
    expect(
      container.read(searchLifeOsEntitiesProvider),
      same(dependencies.searchEntities),
    );
    expect(
      container.read(editLifeOsTaskTitleProvider),
      same(dependencies.editTaskTitle),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await dependencies.close();
  });
}

LifeOsAppDependencies _createTestDependencies(LifeOsDatabase database) {
  final taskRepository = DriftLifeOsTaskRepository(
    database,
    () => 'task-change',
    'device-test',
  );
  final noteRepository = DriftLifeOsNoteRepository(
    database,
    () => 'note-change',
    'device-test',
  );
  final relationshipRepository = DriftLifeOsRelationshipRepository(
    database,
    () => 'relationship-change',
    'device-test',
  );
  final relatedEntityReader = DriftLifeOsRelatedEntityReader(database);
  final workspaceRepository = DriftLifeOsWorkspaceRepository(
    database,
    () => 'workspace-change',
    'device-test',
  );
  final membershipRepository = DriftLifeOsWorkspaceMembershipRepository(
    database,
    () => 'membership-change',
    'device-test',
  );
  final contextReader = DriftLifeOsWorkspaceContextReader(database);
  final creationStore = DriftLifeOsWorkspaceMemberCreationStore(
    database,
    () => 'quick-change',
    'device-test',
  );
  DateTime clock() => DateTime.utc(2026, 9, 9);
  const backupExportEncoder = V1BackupExportEncoder();
  final requestAiCompletion = RequestLifeOsAiCompletion(
    const _UnavailableAiProvider(),
  );
  final askAboutWorkspace = AskAboutLifeOsWorkspace(
    buildContext: BuildLifeOsAiContext(
      workspaceRepository: workspaceRepository,
      workspaceContextReader: contextReader,
    ),
    requestCompletion: requestAiCompletion,
  );
  return LifeOsAppDependencies(
    database: database,
    taskRepository: taskRepository,
    noteRepository: noteRepository,
    relationshipRepository: relationshipRepository,
    relatedEntityReader: relatedEntityReader,
    workspaceRepository: workspaceRepository,
    workspaceMembershipRepository: membershipRepository,
    createTask: CreateLifeOsTask(
      repository: taskRepository,
      entityIdGenerator: () => 'task-test',
      utcClock: clock,
    ),
    editTaskTitle: EditLifeOsTaskTitle(
      repository: taskRepository,
      utcClock: clock,
    ),
    deleteTask: DeleteLifeOsTask(repository: taskRepository, utcClock: clock),
    restoreTask: RestoreLifeOsTask(repository: taskRepository, utcClock: clock),
    createNote: CreateLifeOsNote(
      repository: noteRepository,
      entityIdGenerator: () => 'note-test',
      utcClock: clock,
    ),
    editNote: EditLifeOsNote(repository: noteRepository, utcClock: clock),
    deleteNote: DeleteLifeOsNote(repository: noteRepository, utcClock: clock),
    restoreNote: RestoreLifeOsNote(repository: noteRepository, utcClock: clock),
    createRelationship: CreateLifeOsRelationship(
      relationshipRepository: relationshipRepository,
      taskRepository: taskRepository,
      noteRepository: noteRepository,
      entityIdGenerator: () => 'relationship-test',
      utcClock: clock,
    ),
    unlinkRelationship: UnlinkLifeOsRelationship(
      repository: relationshipRepository,
      utcClock: clock,
    ),
    getDirectRelatedNeighbors: GetDirectLifeOsRelatedNeighbors(
      relatedEntityReader,
    ),
    searchEntities: SearchLifeOsEntities(
      DriftLifeOsUnifiedSearchReader(database),
    ),
    createWorkspace: CreateLifeOsWorkspace(
      repository: workspaceRepository,
      entityIdGenerator: () => 'workspace-test',
      utcClock: clock,
    ),
    editWorkspace: EditLifeOsWorkspace(
      repository: workspaceRepository,
      utcClock: clock,
    ),
    getWorkspace: GetLifeOsWorkspace(workspaceRepository),
    getWorkspaces: GetLifeOsWorkspaces(workspaceRepository),
    getDeletedWorkspaces: GetDeletedLifeOsWorkspaces(workspaceRepository),
    deleteWorkspace: DeleteLifeOsWorkspace(
      repository: workspaceRepository,
      utcClock: clock,
    ),
    restoreWorkspace: RestoreLifeOsWorkspace(
      repository: workspaceRepository,
      utcClock: clock,
    ),
    attachWorkspaceMember: AttachLifeOsWorkspaceMember(
      repository: membershipRepository,
      entityIdGenerator: () => 'membership-test',
      utcClock: clock,
    ),
    detachWorkspaceMember: DetachLifeOsWorkspaceMember(
      repository: membershipRepository,
      utcClock: clock,
    ),
    getWorkspaceMembers: GetLifeOsWorkspaceMembers(contextReader),
    getUnassignedWorkspaceMembers: GetUnassignedLifeOsWorkspaceMembers(
      contextReader,
    ),
    createTaskInWorkspace: CreateLifeOsTaskInWorkspace(
      workspaceRepository: workspaceRepository,
      store: creationStore,
      entityIdGenerator: () => 'quick-task-test',
      utcClock: clock,
    ),
    createNoteInWorkspace: CreateLifeOsNoteInWorkspace(
      workspaceRepository: workspaceRepository,
      store: creationStore,
      entityIdGenerator: () => 'quick-note-test',
      utcClock: clock,
    ),
    createBackup: CreateLifeOsBackup(
      taskRepository: taskRepository,
      encoder: backupExportEncoder,
      utcClock: () => DateTime.utc(2026, 9, 11),
      applicationVersion: lifeOsApplicationVersion,
    ),
    exportData: ExportLifeOsData(
      taskRepository: taskRepository,
      encoder: backupExportEncoder,
      utcClock: () => DateTime.utc(2026, 9, 11),
      applicationVersion: lifeOsApplicationVersion,
    ),
    restoreBackup: RestoreLifeOsBackup(
      reader: const LifeOsBackupFileReader(),
      restoreStore: DriftLifeOsBackupRestoreStore(database),
    ),
    backupOperations: const _NoopBackupOperations(),
    localAiHttpClient: MockClient((_) async {
      throw StateError('Local AI network must not run during startup.');
    }),
    checkLocalAiAvailability: CheckLifeOsLocalAiAvailability(
      const _UnavailableLocalAiReader(),
    ),
    requestAiCompletion: requestAiCompletion,
    askAboutWorkspace: askAboutWorkspace,
    localAiModelName: 'test-model',
  );
}

class _NoopBackupOperations implements LifeOsBackupOperations {
  const _NoopBackupOperations();

  @override
  Future<void> createBackupAt(String destinationPath) async {}

  @override
  Future<void> exportDataAt(String destinationPath) async {}

  @override
  Future<void> restoreBackupFrom(
    String sourcePath, {
    required bool destructiveReplaceConfirmed,
  }) async {}
}

class _UnavailableLocalAiReader implements LifeOsLocalAiAvailabilityReader {
  const _UnavailableLocalAiReader();

  @override
  Future<LifeOsLocalAiAvailability> read() async =>
      LifeOsLocalAiAvailability.runtimeUnavailable;
}

class _UnavailableAiProvider implements LifeOsAiProvider {
  const _UnavailableAiProvider();

  @override
  Future<LifeOsAiResponse> generate(LifeOsAiRequest request) {
    throw const LifeOsAiProviderException(LifeOsAiProviderError.unavailable);
  }
}
