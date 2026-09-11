import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/backup/lifeos_backup_operations.dart';
import '../../l10n/app_localizations.dart';
import '../tasks/task_list_providers.dart';
import 'backup_settings_providers.dart';
import 'lifeos_artifact_file_chooser.dart';

enum _DataTransferPhase { idle, selecting, running, success, error }

class BackupSettingsPage extends ConsumerStatefulWidget {
  const BackupSettingsPage({super.key});

  @override
  ConsumerState<BackupSettingsPage> createState() => _BackupSettingsPageState();
}

class _BackupSettingsPageState extends ConsumerState<BackupSettingsPage> {
  _DataTransferPhase _phase = _DataTransferPhase.idle;
  String? _statusMessage;

  bool get _isBusy =>
      _phase == _DataTransferPhase.selecting ||
      _phase == _DataTransferPhase.running;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return ListView(
      key: const Key('backup-settings-page'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          localizations.settingsTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.backupDataSectionTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(localizations.backupDataSectionDescription),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      key: const Key('create-backup-button'),
                      onPressed: _isBusy ? null : _createBackup,
                      icon: const Icon(Icons.backup_outlined),
                      label: Text(localizations.backupCreateAction),
                    ),
                    OutlinedButton.icon(
                      key: const Key('export-data-button'),
                      onPressed: _isBusy ? null : _exportData,
                      icon: const Icon(Icons.file_download_outlined),
                      label: Text(localizations.exportDataAction),
                    ),
                    OutlinedButton.icon(
                      key: const Key('restore-backup-button'),
                      onPressed: _isBusy ? null : _restoreBackup,
                      icon: const Icon(Icons.restore_outlined),
                      label: Text(localizations.restoreBackupAction),
                    ),
                  ],
                ),
                if (_isBusy) ...[
                  const SizedBox(height: 20),
                  const LinearProgressIndicator(
                    key: Key('backup-operation-progress'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _phase == _DataTransferPhase.selecting
                        ? localizations.backupOperationSelecting
                        : localizations.backupOperationRunning,
                  ),
                ],
                if (_statusMessage case final message?) ...[
                  const SizedBox(height: 20),
                  Text(
                    message,
                    key: const Key('backup-operation-status'),
                    style: TextStyle(
                      color: _phase == _DataTransferPhase.error
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _createBackup() async {
    if (_isBusy) return;
    final localizations = AppLocalizations.of(context);
    _setPhase(_DataTransferPhase.selecting);
    try {
      final destination = await ref
          .read(lifeOsArtifactFileChooserProvider)
          .chooseBackupDestination(
            suggestedName: lifeOsBackupSuggestedFileName(DateTime.now()),
            fileTypeLabel: localizations.backupZipFileTypeLabel,
          );
      if (!mounted) return;
      if (destination == null) {
        _setPhase(_DataTransferPhase.idle);
        return;
      }
      _setPhase(_DataTransferPhase.running);
      await ref
          .read(lifeOsBackupOperationsProvider)
          .createBackupAt(destination);
      if (mounted) {
        _setPhase(
          _DataTransferPhase.success,
          localizations.backupCreateSuccess,
        );
      }
    } on Object catch (error) {
      if (mounted) _showError(error, localizations);
    }
  }

  Future<void> _exportData() async {
    if (_isBusy) return;
    final localizations = AppLocalizations.of(context);
    _setPhase(_DataTransferPhase.selecting);
    try {
      final destination = await ref
          .read(lifeOsArtifactFileChooserProvider)
          .chooseExportDestination(
            suggestedName: lifeOsExportSuggestedFileName(DateTime.now()),
            fileTypeLabel: localizations.jsonFileTypeLabel,
          );
      if (!mounted) return;
      if (destination == null) {
        _setPhase(_DataTransferPhase.idle);
        return;
      }
      _setPhase(_DataTransferPhase.running);
      await ref.read(lifeOsBackupOperationsProvider).exportDataAt(destination);
      if (mounted) {
        _setPhase(_DataTransferPhase.success, localizations.exportDataSuccess);
      }
    } on Object catch (error) {
      if (mounted) _showError(error, localizations);
    }
  }

  Future<void> _restoreBackup() async {
    if (_isBusy) return;
    final localizations = AppLocalizations.of(context);
    _setPhase(_DataTransferPhase.selecting);
    try {
      final source = await ref
          .read(lifeOsArtifactFileChooserProvider)
          .chooseBackupToRestore(
            fileTypeLabel: localizations.backupZipFileTypeLabel,
          );
      if (!mounted) return;
      if (source == null) {
        _setPhase(_DataTransferPhase.idle);
        return;
      }
      _setPhase(_DataTransferPhase.running);
      try {
        await ref
            .read(lifeOsBackupOperationsProvider)
            .restoreBackupFrom(source, destructiveReplaceConfirmed: false);
      } on LifeOsBackupOperationException catch (error) {
        if (error.code != LifeOsBackupOperationErrorCode.confirmationRequired) {
          rethrow;
        }
        if (!mounted) return;
        _setPhase(_DataTransferPhase.idle);
        final confirmed = await _confirmDestructiveRestore(localizations);
        if (!mounted) return;
        if (!confirmed) {
          _setPhase(_DataTransferPhase.idle);
          return;
        }
        _setPhase(_DataTransferPhase.running);
        await ref
            .read(lifeOsBackupOperationsProvider)
            .restoreBackupFrom(source, destructiveReplaceConfirmed: true);
      }
      ref.invalidate(taskListControllerProvider);
      if (mounted) {
        _setPhase(
          _DataTransferPhase.success,
          localizations.restoreBackupSuccess,
        );
      }
    } on Object catch (error) {
      if (mounted) _showError(error, localizations);
    }
  }

  Future<bool> _confirmDestructiveRestore(
    AppLocalizations localizations,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(localizations.restoreConfirmationTitle),
        content: Text(localizations.restoreConfirmationMessage),
        actions: [
          TextButton(
            key: const Key('restore-confirmation-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations.cancelAction),
          ),
          FilledButton(
            key: const Key('restore-confirmation-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(localizations.restoreReplaceAction),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showError(Object error, AppLocalizations localizations) {
    final message = switch (error) {
      LifeOsBackupOperationException(:final code) => switch (code) {
        LifeOsBackupOperationErrorCode.invalidBackup =>
          localizations.backupInvalidError,
        LifeOsBackupOperationErrorCode.unsupportedBackup =>
          localizations.backupUnsupportedError,
        LifeOsBackupOperationErrorCode.checksumMismatch =>
          localizations.backupChecksumError,
        LifeOsBackupOperationErrorCode.destinationAlreadyExists =>
          localizations.backupDestinationExistsError,
        LifeOsBackupOperationErrorCode.fileSystemFailure =>
          localizations.backupFileSystemError,
        LifeOsBackupOperationErrorCode.confirmationRequired =>
          localizations.restoreConfirmationRequiredError,
        LifeOsBackupOperationErrorCode.restorePersistenceFailure =>
          localizations.restorePersistenceError,
      },
      _ => localizations.backupFileSystemError,
    };
    _setPhase(_DataTransferPhase.error, message);
  }

  void _setPhase(_DataTransferPhase phase, [String? message]) {
    setState(() {
      _phase = phase;
      _statusMessage = message;
    });
  }
}
