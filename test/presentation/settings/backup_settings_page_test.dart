import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/backup/lifeos_backup_operations.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/settings/backup_settings_page.dart';
import 'package:lifeos/presentation/settings/backup_settings_providers.dart';
import 'package:lifeos/presentation/settings/lifeos_artifact_file_chooser.dart';

void main() {
  testWidgets('localizes the real Settings destination content in en and ru', (
    tester,
  ) async {
    for (final scenario in [
      (locale: const Locale('en'), title: 'Backup and data'),
      (locale: const Locale('ru'), title: 'Резервная копия и данные'),
    ]) {
      await tester.pumpWidget(
        testApp(
          locale: scenario.locale,
          chooser: FakeFileChooser(),
          operations: FakeBackupOperations(),
        ),
      );
      expect(find.text(scenario.title), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Backup cancel returns to idle without writing or error', (
    tester,
  ) async {
    final chooser = FakeFileChooser();
    final operations = FakeBackupOperations();
    await tester.pumpWidget(testApp(chooser: chooser, operations: operations));

    await tester.tap(find.byKey(const Key('create-backup-button')));
    await tester.pumpAndSettle();

    expect(chooser.backupChooseCount, 1);
    expect(operations.backupCalls, 0);
    expect(find.byKey(const Key('backup-operation-status')), findsNothing);
    expect(find.byKey(const Key('backup-operation-progress')), findsNothing);
  });

  testWidgets(
    'Backup reports success and blocks duplicate running invocation',
    (tester) async {
      final completer = Completer<void>();
      final chooser = FakeFileChooser(backupDestination: r'C:\backup.zip');
      final operations = FakeBackupOperations(backupCompleter: completer);
      await tester.pumpWidget(
        testApp(chooser: chooser, operations: operations),
      );

      await tester.tap(find.byKey(const Key('create-backup-button')));
      await tester.pump();
      expect(operations.backupCalls, 1);
      expect(
        find.byKey(const Key('backup-operation-progress')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('create-backup-button')))
            .onPressed,
        isNull,
      );
      await tester.tap(
        find.byKey(const Key('create-backup-button')),
        warnIfMissed: false,
      );
      expect(operations.backupCalls, 1);

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.text('Backup created successfully.'), findsOneWidget);
    },
  );

  testWidgets('Backup maps a typed destination error', (tester) async {
    final operations = FakeBackupOperations(
      backupError: const LifeOsBackupOperationException(
        LifeOsBackupOperationErrorCode.destinationAlreadyExists,
      ),
    );
    await tester.pumpWidget(
      testApp(
        chooser: FakeFileChooser(backupDestination: r'C:\existing.zip'),
        operations: operations,
      ),
    );

    await tester.tap(find.byKey(const Key('create-backup-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('A file already exists at the selected destination.'),
      findsOneWidget,
    );
  });

  testWidgets('Export handles cancel, success, and typed error', (
    tester,
  ) async {
    final chooser = FakeFileChooser();
    final operations = FakeBackupOperations();
    await tester.pumpWidget(testApp(chooser: chooser, operations: operations));

    await tester.tap(find.byKey(const Key('export-data-button')));
    await tester.pumpAndSettle();
    expect(operations.exportCalls, 0);

    chooser.exportDestination = r'C:\export.json';
    await tester.tap(find.byKey(const Key('export-data-button')));
    await tester.pumpAndSettle();
    expect(operations.exportCalls, 1);
    expect(find.text('Export created successfully.'), findsOneWidget);

    operations.exportError = const LifeOsBackupOperationException(
      LifeOsBackupOperationErrorCode.fileSystemFailure,
    );
    await tester.tap(find.byKey(const Key('export-data-button')));
    await tester.pumpAndSettle();
    expect(
      find.text('The selected file could not be read or written.'),
      findsOneWidget,
    );
  });

  testWidgets('Restore file cancel does not invoke Application operations', (
    tester,
  ) async {
    final operations = FakeBackupOperations();
    await tester.pumpWidget(
      testApp(chooser: FakeFileChooser(), operations: operations),
    );

    await tester.tap(find.byKey(const Key('restore-backup-button')));
    await tester.pumpAndSettle();

    expect(operations.restoreConfirmations, isEmpty);
  });

  testWidgets('Restore maps invalid Backup and persistence failures', (
    tester,
  ) async {
    final operations = FakeBackupOperations(
      restoreError: const LifeOsBackupOperationException(
        LifeOsBackupOperationErrorCode.invalidBackup,
      ),
    );
    await tester.pumpWidget(
      testApp(
        chooser: FakeFileChooser(restoreSource: r'C:\invalid.zip'),
        operations: operations,
      ),
    );

    await tester.tap(find.byKey(const Key('restore-backup-button')));
    await tester.pumpAndSettle();
    expect(find.text('This backup is invalid or corrupted.'), findsOneWidget);

    operations.restoreError = const LifeOsBackupOperationException(
      LifeOsBackupOperationErrorCode.restorePersistenceFailure,
    );
    await tester.tap(find.byKey(const Key('restore-backup-button')));
    await tester.pumpAndSettle();
    expect(
      find.text('The backup could not replace current LifeOS data.'),
      findsOneWidget,
    );
  });

  testWidgets('Restore confirmation cancel performs no confirmed mutation', (
    tester,
  ) async {
    final operations = FakeBackupOperations(requireConfirmation: true);
    await tester.pumpWidget(
      testApp(
        chooser: FakeFileChooser(restoreSource: r'C:\backup.zip'),
        operations: operations,
      ),
    );

    await tester.tap(find.byKey(const Key('restore-backup-button')));
    await tester.pumpAndSettle();
    expect(find.text('Replace current LifeOS data?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('restore-confirmation-cancel')));
    await tester.pumpAndSettle();

    expect(operations.restoreConfirmations, [false]);
    expect(find.text('Backup restored successfully.'), findsNothing);
  });

  testWidgets('Restore confirmation retries explicitly and reports success', (
    tester,
  ) async {
    final operations = FakeBackupOperations(requireConfirmation: true);
    await tester.pumpWidget(
      testApp(
        chooser: FakeFileChooser(restoreSource: r'C:\backup.zip'),
        operations: operations,
      ),
    );

    await tester.tap(find.byKey(const Key('restore-backup-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('restore-confirmation-confirm')));
    await tester.pumpAndSettle();

    expect(operations.restoreConfirmations, [false, true]);
    expect(find.text('Backup restored successfully.'), findsOneWidget);
  });

  test('suggested filenames are UTC and Windows-safe', () {
    final timestamp = DateTime.utc(2026, 9, 11, 12, 34, 56);
    expect(
      lifeOsBackupSuggestedFileName(timestamp),
      'lifeos-backup-20260911T123456Z.zip',
    );
    expect(
      lifeOsExportSuggestedFileName(timestamp),
      'lifeos-export-20260911T123456Z.json',
    );
  });
}

Widget testApp({
  Locale locale = const Locale('en'),
  required FakeFileChooser chooser,
  required FakeBackupOperations operations,
}) {
  return ProviderScope(
    overrides: [
      lifeOsArtifactFileChooserProvider.overrideWithValue(chooser),
      lifeOsBackupOperationsProvider.overrideWithValue(operations),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: BackupSettingsPage()),
    ),
  );
}

class FakeFileChooser implements LifeOsArtifactFileChooser {
  FakeFileChooser({
    this.backupDestination,
    this.exportDestination,
    this.restoreSource,
  });

  String? backupDestination;
  String? exportDestination;
  String? restoreSource;
  int backupChooseCount = 0;

  @override
  Future<String?> chooseBackupDestination({
    required String suggestedName,
    required String fileTypeLabel,
  }) async {
    backupChooseCount += 1;
    return backupDestination;
  }

  @override
  Future<String?> chooseExportDestination({
    required String suggestedName,
    required String fileTypeLabel,
  }) async {
    return exportDestination;
  }

  @override
  Future<String?> chooseBackupToRestore({required String fileTypeLabel}) async =>
      restoreSource;
}

class FakeBackupOperations implements LifeOsBackupOperations {
  FakeBackupOperations({
    this.backupCompleter,
    this.backupError,
    this.exportError,
    this.restoreError,
    this.requireConfirmation = false,
  });

  final Completer<void>? backupCompleter;
  Object? backupError;
  Object? exportError;
  Object? restoreError;
  final bool requireConfirmation;
  int backupCalls = 0;
  int exportCalls = 0;
  final List<bool> restoreConfirmations = [];

  @override
  Future<void> createBackupAt(String destinationPath) async {
    backupCalls += 1;
    if (backupError case final error?) throw error;
    await backupCompleter?.future;
  }

  @override
  Future<void> exportDataAt(String destinationPath) async {
    exportCalls += 1;
    if (exportError case final error?) throw error;
  }

  @override
  Future<void> restoreBackupFrom(
    String sourcePath, {
    required bool destructiveReplaceConfirmed,
  }) async {
    restoreConfirmations.add(destructiveReplaceConfirmed);
    if (restoreError case final error?) throw error;
    if (requireConfirmation && !destructiveReplaceConfirmed) {
      throw const LifeOsBackupOperationException(
        LifeOsBackupOperationErrorCode.confirmationRequired,
      );
    }
  }
}
