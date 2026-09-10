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
