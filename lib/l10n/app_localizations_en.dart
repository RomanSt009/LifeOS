// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LifeOS';

  @override
  String get appDescription => 'Personal Operating System';

  @override
  String get navigationHome => 'Home';

  @override
  String get navigationTasks => 'Tasks';

  @override
  String get navigationNotes => 'Notes';

  @override
  String get navigationSearch => 'Search';

  @override
  String get navigationSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get backupDataSectionTitle => 'Backup and data';

  @override
  String get backupDataSectionDescription =>
      'Create an unencrypted local backup, export your data, or replace current data from a backup.';

  @override
  String get backupCreateAction => 'Create backup';

  @override
  String get exportDataAction => 'Export JSON';

  @override
  String get restoreBackupAction => 'Restore backup';

  @override
  String get backupZipFileTypeLabel => 'LifeOS backup';

  @override
  String get jsonFileTypeLabel => 'JSON document';

  @override
  String get backupOperationSelecting => 'Choosing a file…';

  @override
  String get backupOperationRunning => 'Operation in progress…';

  @override
  String get backupCreateSuccess => 'Backup created successfully.';

  @override
  String get exportDataSuccess => 'Export created successfully.';

  @override
  String get restoreBackupSuccess => 'Backup restored successfully.';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get restoreConfirmationTitle => 'Replace current LifeOS data?';

  @override
  String get restoreConfirmationMessage =>
      'Current local LifeOS data will be replaced by this backup. This is not a merge, and local changes still waiting to sync will not remain queued after restore.';

  @override
  String get restoreReplaceAction => 'Restore and replace';

  @override
  String get backupInvalidError => 'This backup is invalid or corrupted.';

  @override
  String get backupUnsupportedError => 'This backup version is not supported.';

  @override
  String get backupChecksumError => 'The backup integrity check failed.';

  @override
  String get backupDestinationExistsError =>
      'A file already exists at the selected destination.';

  @override
  String get backupFileSystemError =>
      'The selected file could not be read or written.';

  @override
  String get restoreConfirmationRequiredError =>
      'Confirmation is required before replacing current data.';

  @override
  String get restorePersistenceError =>
      'The backup could not replace current LifeOS data.';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchQueryFieldLabel => 'Task title';

  @override
  String get searchAction => 'Search';

  @override
  String get searchInitial => 'Enter a Task title to search';

  @override
  String get searchNoResults => 'No Tasks found';

  @override
  String get searchError => 'Unable to search Tasks';

  @override
  String get taskListTitle => 'Tasks';

  @override
  String get taskListEmpty => 'No Tasks yet';

  @override
  String get taskLoadError => 'Unable to load Tasks';

  @override
  String get taskUnavailable => 'Task unavailable';

  @override
  String get taskCompletionMarkComplete => 'Mark complete';

  @override
  String get taskCompletionMarkIncomplete => 'Mark incomplete';

  @override
  String get taskTitleFieldLabel => 'Task title';

  @override
  String get taskTitleRequired => 'Enter a Task title';

  @override
  String get taskCreateError => 'Unable to create Task';

  @override
  String get taskCreateAction => 'Add Task';

  @override
  String get noteListTitle => 'Notes';

  @override
  String get noteListEmpty => 'No Notes yet';

  @override
  String get noteLoadError => 'Unable to load Notes';

  @override
  String get noteUntitled => 'Untitled Note';

  @override
  String get noteCreateAction => 'New Note';

  @override
  String get noteTitleFieldLabel => 'Note title';

  @override
  String get noteContentFieldLabel => 'Note content';

  @override
  String get noteContentRequired => 'Enter a title or content';

  @override
  String get noteSaveAction => 'Save Note';

  @override
  String get noteSaveError => 'Unable to save Note';

  @override
  String get relationshipSectionTitle => 'Related';

  @override
  String get relationshipAddAction => 'Add relationship';

  @override
  String get relationshipUnlinkAction => 'Remove relationship';

  @override
  String get relationshipEmpty => 'No related Tasks or Notes';

  @override
  String get relationshipLoading => 'Loading related item…';

  @override
  String get relationshipLoadError => 'Unable to load relationships';

  @override
  String get relationshipSaveError => 'Unable to update relationships';

  @override
  String get relationshipUnavailable => 'Related item unavailable';

  @override
  String get relationshipPickerTitle => 'Choose a Task or Note';

  @override
  String get relationshipPickerEmpty => 'No other Tasks or Notes are available';

  @override
  String relationshipTaskLabel(String title) {
    return 'Task: $title';
  }

  @override
  String relationshipNoteLabel(String title) {
    return 'Note: $title';
  }
}
