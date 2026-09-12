import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../presentation/shell/lifeos_shell_page.dart';
import '../presentation/notes/note_providers.dart';
import '../presentation/search/task_search_providers.dart';
import '../presentation/settings/backup_settings_providers.dart';
import '../presentation/tasks/task_completion_providers.dart';
import '../presentation/tasks/task_list_providers.dart';
import 'dependencies.dart';

class LifeOSApp extends StatefulWidget {
  const LifeOSApp({required this.dependencies, super.key});

  final LifeOsAppDependencies dependencies;

  @override
  State<LifeOSApp> createState() => _LifeOSAppState();
}

class _LifeOSAppState extends State<LifeOSApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        await widget.dependencies.close();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    unawaited(widget.dependencies.close());
    super.dispose();
  }

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
        createLifeOsNoteProvider.overrideWithValue(
          widget.dependencies.createNote,
        ),
        editLifeOsNoteProvider.overrideWithValue(widget.dependencies.editNote),
        createLifeOsTaskProvider.overrideWithValue(
          widget.dependencies.createTask,
        ),
        searchLifeOsTasksProvider.overrideWithValue(
          widget.dependencies.searchTasks,
        ),
        lifeOsBackupOperationsProvider.overrideWithValue(
          widget.dependencies.backupOperations,
        ),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: resolveLifeOsLocale,
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        home: const LifeosShellPage(),
      ),
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
