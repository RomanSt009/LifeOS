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
}
