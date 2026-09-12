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
