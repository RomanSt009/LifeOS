import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LifeOS'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Personal Operating System'**
  String get appDescription;

  /// No description provided for @navigationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navigationHome;

  /// No description provided for @navigationTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navigationTasks;

  /// No description provided for @navigationNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get navigationNotes;

  /// No description provided for @navigationSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navigationSearch;

  /// No description provided for @navigationSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navigationSettings;

  /// No description provided for @homeAlphaDescription.
  ///
  /// In en, this message translates to:
  /// **'Use the navigation to work with Tasks and Notes or search Task titles.'**
  String get homeAlphaDescription;

  /// No description provided for @homeQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActionsTitle;

  /// No description provided for @homeNewTaskAction.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get homeNewTaskAction;

  /// No description provided for @homeNewNoteAction.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get homeNewNoteAction;

  /// No description provided for @homeSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get homeSearchAction;

  /// No description provided for @homeSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Settings / Backup'**
  String get homeSettingsAction;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @backupDataSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup and data'**
  String get backupDataSectionTitle;

  /// No description provided for @backupDataSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Create an unencrypted local backup, export your data, or replace current data from a backup.'**
  String get backupDataSectionDescription;

  /// No description provided for @backupCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create backup'**
  String get backupCreateAction;

  /// No description provided for @exportDataAction.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportDataAction;

  /// No description provided for @restoreBackupAction.
  ///
  /// In en, this message translates to:
  /// **'Restore backup'**
  String get restoreBackupAction;

  /// No description provided for @backupZipFileTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'LifeOS backup'**
  String get backupZipFileTypeLabel;

  /// No description provided for @jsonFileTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'JSON document'**
  String get jsonFileTypeLabel;

  /// No description provided for @backupOperationSelecting.
  ///
  /// In en, this message translates to:
  /// **'Choosing a file…'**
  String get backupOperationSelecting;

  /// No description provided for @backupOperationRunning.
  ///
  /// In en, this message translates to:
  /// **'Operation in progress…'**
  String get backupOperationRunning;

  /// No description provided for @backupCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully.'**
  String get backupCreateSuccess;

  /// No description provided for @exportDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'Export created successfully.'**
  String get exportDataSuccess;

  /// No description provided for @restoreBackupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup restored successfully.'**
  String get restoreBackupSuccess;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @restoreConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace current LifeOS data?'**
  String get restoreConfirmationTitle;

  /// No description provided for @restoreConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Current local LifeOS data will be replaced by this backup. This is not a merge, and local changes still waiting to sync will not remain queued after restore.'**
  String get restoreConfirmationMessage;

  /// No description provided for @restoreReplaceAction.
  ///
  /// In en, this message translates to:
  /// **'Restore and replace'**
  String get restoreReplaceAction;

  /// No description provided for @backupInvalidError.
  ///
  /// In en, this message translates to:
  /// **'This backup is invalid or corrupted.'**
  String get backupInvalidError;

  /// No description provided for @backupUnsupportedError.
  ///
  /// In en, this message translates to:
  /// **'This backup version is not supported.'**
  String get backupUnsupportedError;

  /// No description provided for @backupChecksumError.
  ///
  /// In en, this message translates to:
  /// **'The backup integrity check failed.'**
  String get backupChecksumError;

  /// No description provided for @backupDestinationExistsError.
  ///
  /// In en, this message translates to:
  /// **'A file already exists at the selected destination.'**
  String get backupDestinationExistsError;

  /// No description provided for @backupFileSystemError.
  ///
  /// In en, this message translates to:
  /// **'The selected file could not be read or written.'**
  String get backupFileSystemError;

  /// No description provided for @restoreConfirmationRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Confirmation is required before replacing current data.'**
  String get restoreConfirmationRequiredError;

  /// No description provided for @restorePersistenceError.
  ///
  /// In en, this message translates to:
  /// **'The backup could not replace current LifeOS data.'**
  String get restorePersistenceError;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchQueryFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get searchQueryFieldLabel;

  /// No description provided for @searchAction.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchAction;

  /// No description provided for @searchClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClearAction;

  /// No description provided for @searchInitial.
  ///
  /// In en, this message translates to:
  /// **'Enter a Task title to search'**
  String get searchInitial;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No Tasks found'**
  String get searchNoResults;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Unable to search Tasks'**
  String get searchError;

  /// No description provided for @taskListTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get taskListTitle;

  /// No description provided for @taskListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Tasks yet'**
  String get taskListEmpty;

  /// No description provided for @taskFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get taskFilterAll;

  /// No description provided for @taskFilterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get taskFilterOpen;

  /// No description provided for @taskFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskFilterCompleted;

  /// No description provided for @taskFilterOpenEmpty.
  ///
  /// In en, this message translates to:
  /// **'No open Tasks'**
  String get taskFilterOpenEmpty;

  /// No description provided for @taskFilterCompletedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed Tasks'**
  String get taskFilterCompletedEmpty;

  /// No description provided for @taskLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load Tasks'**
  String get taskLoadError;

  /// No description provided for @taskUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Task unavailable'**
  String get taskUnavailable;

  /// No description provided for @taskCompletionMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get taskCompletionMarkComplete;

  /// No description provided for @taskCompletionMarkIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Mark incomplete'**
  String get taskCompletionMarkIncomplete;

  /// No description provided for @taskCompletionError.
  ///
  /// In en, this message translates to:
  /// **'Unable to update Task completion'**
  String get taskCompletionError;

  /// No description provided for @taskTitleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get taskTitleFieldLabel;

  /// No description provided for @taskTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a Task title'**
  String get taskTitleRequired;

  /// No description provided for @taskCreateError.
  ///
  /// In en, this message translates to:
  /// **'Unable to create Task'**
  String get taskCreateError;

  /// No description provided for @taskCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get taskCreateAction;

  /// No description provided for @taskEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get taskEditAction;

  /// No description provided for @taskEditDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get taskEditDialogTitle;

  /// No description provided for @taskSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get taskSaveAction;

  /// No description provided for @taskEditError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save Task'**
  String get taskEditError;

  /// No description provided for @trashAction.
  ///
  /// In en, this message translates to:
  /// **'Trash'**
  String get trashAction;

  /// No description provided for @backToTasksAction.
  ///
  /// In en, this message translates to:
  /// **'Back to Tasks'**
  String get backToTasksAction;

  /// No description provided for @backToNotesAction.
  ///
  /// In en, this message translates to:
  /// **'Back to Notes'**
  String get backToNotesAction;

  /// No description provided for @deleteTaskAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTaskAction;

  /// No description provided for @deleteTaskDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Move Task to Trash?'**
  String get deleteTaskDialogTitle;

  /// No description provided for @moveToTrashAction.
  ///
  /// In en, this message translates to:
  /// **'Move to Trash'**
  String get moveToTrashAction;

  /// No description provided for @moveTaskToTrashConfirmation.
  ///
  /// In en, this message translates to:
  /// **'{title} will be moved to Trash and can be restored.'**
  String moveTaskToTrashConfirmation(String title);

  /// No description provided for @restoreTaskAction.
  ///
  /// In en, this message translates to:
  /// **'Restore Task'**
  String get restoreTaskAction;

  /// No description provided for @taskTrashEmpty.
  ///
  /// In en, this message translates to:
  /// **'No deleted Tasks'**
  String get taskTrashEmpty;

  /// No description provided for @taskDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete Task'**
  String get taskDeleteError;

  /// No description provided for @taskRestoreError.
  ///
  /// In en, this message translates to:
  /// **'Unable to restore Task'**
  String get taskRestoreError;

  /// No description provided for @noteListTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get noteListTitle;

  /// No description provided for @noteListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Notes yet'**
  String get noteListEmpty;

  /// No description provided for @noteLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load Notes'**
  String get noteLoadError;

  /// No description provided for @noteUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled Note'**
  String get noteUntitled;

  /// No description provided for @noteCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get noteCreateAction;

  /// No description provided for @noteEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get noteEditAction;

  /// No description provided for @noteTitleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Note title'**
  String get noteTitleFieldLabel;

  /// No description provided for @noteContentFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Note content'**
  String get noteContentFieldLabel;

  /// No description provided for @noteContentRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title or content'**
  String get noteContentRequired;

  /// No description provided for @noteSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save Note'**
  String get noteSaveAction;

  /// No description provided for @noteSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save Note'**
  String get noteSaveError;

  /// No description provided for @noteUnsavedChangesIndicator.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get noteUnsavedChangesIndicator;

  /// No description provided for @noteSavedStatus.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get noteSavedStatus;

  /// No description provided for @noteUnsavedChangesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save changes to this Note?'**
  String get noteUnsavedChangesDialogTitle;

  /// No description provided for @noteUnsavedChangesDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost if you continue.'**
  String get noteUnsavedChangesDialogMessage;

  /// No description provided for @saveChangesAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveChangesAction;

  /// No description provided for @discardChangesAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardChangesAction;

  /// No description provided for @noteTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleted Notes'**
  String get noteTrashTitle;

  /// No description provided for @noteTrashDescription.
  ///
  /// In en, this message translates to:
  /// **'Deleted Notes can be restored from this list.'**
  String get noteTrashDescription;

  /// No description provided for @deleteNoteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNoteAction;

  /// No description provided for @deleteNoteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Move Note to Trash?'**
  String get deleteNoteDialogTitle;

  /// No description provided for @moveNoteToTrashConfirmation.
  ///
  /// In en, this message translates to:
  /// **'{title} will be moved to Trash and can be restored.'**
  String moveNoteToTrashConfirmation(String title);

  /// No description provided for @restoreNoteAction.
  ///
  /// In en, this message translates to:
  /// **'Restore Note'**
  String get restoreNoteAction;

  /// No description provided for @noteTrashEmpty.
  ///
  /// In en, this message translates to:
  /// **'No deleted Notes'**
  String get noteTrashEmpty;

  /// No description provided for @noteDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete Note'**
  String get noteDeleteError;

  /// No description provided for @noteRestoreError.
  ///
  /// In en, this message translates to:
  /// **'Unable to restore Note'**
  String get noteRestoreError;

  /// No description provided for @relationshipSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Related'**
  String get relationshipSectionTitle;

  /// No description provided for @relationshipAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add relationship'**
  String get relationshipAddAction;

  /// No description provided for @relationshipUnlinkAction.
  ///
  /// In en, this message translates to:
  /// **'Remove relationship'**
  String get relationshipUnlinkAction;

  /// No description provided for @relationshipEmpty.
  ///
  /// In en, this message translates to:
  /// **'No related Tasks or Notes'**
  String get relationshipEmpty;

  /// No description provided for @relationshipLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading related item…'**
  String get relationshipLoading;

  /// No description provided for @relationshipLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load relationships'**
  String get relationshipLoadError;

  /// No description provided for @relationshipSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to update relationships'**
  String get relationshipSaveError;

  /// No description provided for @relationshipUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Related item unavailable'**
  String get relationshipUnavailable;

  /// No description provided for @relationshipPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Task or Note'**
  String get relationshipPickerTitle;

  /// No description provided for @relationshipPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No other Tasks or Notes are available'**
  String get relationshipPickerEmpty;

  /// No description provided for @relationshipEndpointChoicesError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load available Tasks and Notes'**
  String get relationshipEndpointChoicesError;

  /// No description provided for @relationshipEndpointError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load related item'**
  String get relationshipEndpointError;

  /// No description provided for @relationshipUnlinkDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove relationship?'**
  String get relationshipUnlinkDialogTitle;

  /// No description provided for @relationshipUnlinkDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'The relationship will be removed from Related. The Task or Note will not be deleted.'**
  String get relationshipUnlinkDialogMessage;

  /// No description provided for @relationshipTaskLabel.
  ///
  /// In en, this message translates to:
  /// **'Task: {title}'**
  String relationshipTaskLabel(String title);

  /// No description provided for @relationshipNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note: {title}'**
  String relationshipNoteLabel(String title);

  /// No description provided for @workspaceListTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get workspaceListTitle;

  /// No description provided for @workspaceListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Workspaces yet'**
  String get workspaceListEmpty;

  /// No description provided for @workspaceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load Workspaces'**
  String get workspaceLoadError;

  /// No description provided for @workspaceCreateAction.
  ///
  /// In en, this message translates to:
  /// **'New Workspace'**
  String get workspaceCreateAction;

  /// No description provided for @workspaceEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit Workspace'**
  String get workspaceEditAction;

  /// No description provided for @workspaceActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Workspace actions'**
  String get workspaceActionsTooltip;

  /// No description provided for @workspaceTitleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Workspace title'**
  String get workspaceTitleFieldLabel;

  /// No description provided for @workspaceTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a Workspace title'**
  String get workspaceTitleRequired;

  /// No description provided for @workspaceDescriptionFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get workspaceDescriptionFieldLabel;

  /// No description provided for @workspaceNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get workspaceNoDescription;

  /// No description provided for @workspaceSaveError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save Workspace'**
  String get workspaceSaveError;

  /// No description provided for @workspaceMoveToTrashAction.
  ///
  /// In en, this message translates to:
  /// **'Move Workspace to Trash'**
  String get workspaceMoveToTrashAction;

  /// No description provided for @workspaceDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Move Workspace to Trash?'**
  String get workspaceDeleteDialogTitle;

  /// No description provided for @workspaceMoveToTrashConfirmation.
  ///
  /// In en, this message translates to:
  /// **'{title} will be moved to Trash. Its Tasks, Notes, memberships, and relationships will not be deleted.'**
  String workspaceMoveToTrashConfirmation(String title);

  /// No description provided for @workspaceDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Unable to move Workspace to Trash'**
  String get workspaceDeleteError;

  /// No description provided for @workspaceTrashTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspace Trash'**
  String get workspaceTrashTitle;

  /// No description provided for @workspaceTrashEmpty.
  ///
  /// In en, this message translates to:
  /// **'No deleted Workspaces'**
  String get workspaceTrashEmpty;

  /// No description provided for @workspaceRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore Workspace'**
  String get workspaceRestoreAction;

  /// No description provided for @workspaceRestoreError.
  ///
  /// In en, this message translates to:
  /// **'Unable to restore Workspace'**
  String get workspaceRestoreError;

  /// No description provided for @backToWorkspacesAction.
  ///
  /// In en, this message translates to:
  /// **'Back to Workspaces'**
  String get backToWorkspacesAction;

  /// No description provided for @workspaceSelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a Workspace'**
  String get workspaceSelectPrompt;

  /// No description provided for @workspaceAddTaskAction.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get workspaceAddTaskAction;

  /// No description provided for @workspaceAddNoteAction.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get workspaceAddNoteAction;

  /// No description provided for @workspaceAttachExistingAction.
  ///
  /// In en, this message translates to:
  /// **'Add existing'**
  String get workspaceAttachExistingAction;

  /// No description provided for @workspaceTasksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Tasks in this Workspace'**
  String get workspaceTasksEmpty;

  /// No description provided for @workspaceNotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Notes in this Workspace'**
  String get workspaceNotesEmpty;

  /// No description provided for @workspaceMembersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load Workspace members'**
  String get workspaceMembersLoadError;

  /// No description provided for @workspaceTaskCreateError.
  ///
  /// In en, this message translates to:
  /// **'Unable to create Task in Workspace'**
  String get workspaceTaskCreateError;

  /// No description provided for @workspaceNoteCreateError.
  ///
  /// In en, this message translates to:
  /// **'Unable to create Note in Workspace'**
  String get workspaceNoteCreateError;

  /// No description provided for @workspaceAttachPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Task or Note'**
  String get workspaceAttachPickerTitle;

  /// No description provided for @workspaceAttachPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No unattached active Tasks or Notes are available'**
  String get workspaceAttachPickerEmpty;

  /// No description provided for @workspaceAttachError.
  ///
  /// In en, this message translates to:
  /// **'Unable to add item to Workspace'**
  String get workspaceAttachError;

  /// No description provided for @workspaceDetachAction.
  ///
  /// In en, this message translates to:
  /// **'Remove from Workspace'**
  String get workspaceDetachAction;

  /// No description provided for @workspaceDetachDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from Workspace?'**
  String get workspaceDetachDialogTitle;

  /// No description provided for @workspaceDetachDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'The Task or Note will remain available outside this Workspace. Its relationships will not be changed.'**
  String get workspaceDetachDialogMessage;

  /// No description provided for @workspaceDetachError.
  ///
  /// In en, this message translates to:
  /// **'Unable to remove item from Workspace'**
  String get workspaceDetachError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
