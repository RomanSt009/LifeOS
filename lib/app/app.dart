import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../presentation/ai/local_ai_providers.dart';
import '../presentation/shell/lifeos_shell_page.dart';
import '../presentation/notes/note_exit_coordinator.dart';
import '../presentation/notes/note_providers.dart';
import '../presentation/relationships/relationship_providers.dart';
import '../presentation/search/unified_search_providers.dart';
import '../presentation/settings/backup_settings_providers.dart';
import '../presentation/tasks/task_completion_providers.dart';
import '../presentation/tasks/task_list_providers.dart';
import '../presentation/workspaces/workspace_providers.dart';
import 'dependencies.dart';

class LifeOSApp extends StatefulWidget {
  const LifeOSApp({required this.dependencies, super.key});

  final LifeOsAppDependencies dependencies;

  @override
  State<LifeOSApp> createState() => _LifeOSAppState();
}

class _LifeOSAppState extends State<LifeOSApp> {
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        lifeOsTaskRepositoryProvider.overrideWithValue(
          widget.dependencies.taskRepository,
        ),
        lifeOsNoteRepositoryProvider.overrideWithValue(
          widget.dependencies.noteRepository,
        ),
        lifeOsRelationshipRepositoryProvider.overrideWithValue(
          widget.dependencies.relationshipRepository,
        ),
        createLifeOsNoteProvider.overrideWithValue(
          widget.dependencies.createNote,
        ),
        editLifeOsNoteProvider.overrideWithValue(widget.dependencies.editNote),
        deleteLifeOsNoteProvider.overrideWithValue(
          widget.dependencies.deleteNote,
        ),
        restoreLifeOsNoteProvider.overrideWithValue(
          widget.dependencies.restoreNote,
        ),
        createLifeOsRelationshipProvider.overrideWithValue(
          widget.dependencies.createRelationship,
        ),
        unlinkLifeOsRelationshipProvider.overrideWithValue(
          widget.dependencies.unlinkRelationship,
        ),
        getDirectLifeOsRelatedNeighborsProvider.overrideWithValue(
          widget.dependencies.getDirectRelatedNeighbors,
        ),
        createLifeOsTaskProvider.overrideWithValue(
          widget.dependencies.createTask,
        ),
        editLifeOsTaskTitleProvider.overrideWithValue(
          widget.dependencies.editTaskTitle,
        ),
        deleteLifeOsTaskProvider.overrideWithValue(
          widget.dependencies.deleteTask,
        ),
        restoreLifeOsTaskProvider.overrideWithValue(
          widget.dependencies.restoreTask,
        ),
        searchLifeOsEntitiesProvider.overrideWithValue(
          widget.dependencies.searchEntities,
        ),
        lifeOsBackupOperationsProvider.overrideWithValue(
          widget.dependencies.backupOperations,
        ),
        createLifeOsWorkspaceProvider.overrideWithValue(
          widget.dependencies.createWorkspace,
        ),
        editLifeOsWorkspaceProvider.overrideWithValue(
          widget.dependencies.editWorkspace,
        ),
        getLifeOsWorkspacesProvider.overrideWithValue(
          widget.dependencies.getWorkspaces,
        ),
        getDeletedLifeOsWorkspacesProvider.overrideWithValue(
          widget.dependencies.getDeletedWorkspaces,
        ),
        deleteLifeOsWorkspaceProvider.overrideWithValue(
          widget.dependencies.deleteWorkspace,
        ),
        restoreLifeOsWorkspaceProvider.overrideWithValue(
          widget.dependencies.restoreWorkspace,
        ),
        getLifeOsWorkspaceMembersProvider.overrideWithValue(
          widget.dependencies.getWorkspaceMembers,
        ),
        getUnassignedLifeOsWorkspaceMembersProvider.overrideWithValue(
          widget.dependencies.getUnassignedWorkspaceMembers,
        ),
        attachLifeOsWorkspaceMemberProvider.overrideWithValue(
          widget.dependencies.attachWorkspaceMember,
        ),
        detachLifeOsWorkspaceMemberProvider.overrideWithValue(
          widget.dependencies.detachWorkspaceMember,
        ),
        createLifeOsTaskInWorkspaceProvider.overrideWithValue(
          widget.dependencies.createTaskInWorkspace,
        ),
        createLifeOsNoteInWorkspaceProvider.overrideWithValue(
          widget.dependencies.createNoteInWorkspace,
        ),
        checkLifeOsLocalAiAvailabilityProvider.overrideWithValue(
          widget.dependencies.checkLocalAiAvailability,
        ),
        askAboutLifeOsWorkspaceProvider.overrideWithValue(
          widget.dependencies.askAboutWorkspace,
        ),
        lifeOsLocalAiModelNameProvider.overrideWithValue(
          widget.dependencies.localAiModelName,
        ),
      ],
      child: _LifeOSAppLifecycle(dependencies: widget.dependencies),
    );
  }
}

class _LifeOSAppLifecycle extends ConsumerStatefulWidget {
  const _LifeOSAppLifecycle({required this.dependencies});

  final LifeOsAppDependencies dependencies;

  @override
  ConsumerState<_LifeOSAppLifecycle> createState() =>
      _LifeOSAppLifecycleState();
}

class _LifeOSAppLifecycleState extends ConsumerState<_LifeOSAppLifecycle> {
  late final AppLifecycleListener _lifecycleListener;
  Future<AppExitResponse>? _exitRequest;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: _handleExitRequested,
    );
  }

  Future<AppExitResponse> _handleExitRequested() {
    return _exitRequest ??= _resolveExitRequest();
  }

  Future<AppExitResponse> _resolveExitRequest() async {
    try {
      final canClose = await ref
          .read(lifeOsNoteExitCoordinatorProvider)
          .requestClose();
      if (!canClose) {
        _exitRequest = null;
        return AppExitResponse.cancel;
      }
      await widget.dependencies.close();
      return AppExitResponse.exit;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'LifeOS app lifecycle',
          context: ErrorDescription('while resolving an app exit request'),
        ),
      );
      _exitRequest = null;
      return AppExitResponse.cancel;
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    unawaited(widget.dependencies.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveLifeOsLocale,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const LifeosShellPage(),
    );
  }
}

Locale resolveLifeOsLocale(Locale? locale, Iterable<Locale> supportedLocales) {
  final fallbackLocale = supportedLocales.firstWhere(
    (supportedLocale) => supportedLocale.languageCode == 'en',
  );
  if (locale == null) {
    return fallbackLocale;
  }

  for (final supportedLocale in supportedLocales) {
    if (supportedLocale.languageCode == locale.languageCode) {
      return supportedLocale;
    }
  }

  return fallbackLocale;
}
