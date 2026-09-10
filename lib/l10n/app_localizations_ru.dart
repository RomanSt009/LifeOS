// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'LifeOS';

  @override
  String get appDescription => 'Персональная операционная система';

  @override
  String get navigationHome => 'Главная';

  @override
  String get navigationTasks => 'Задачи';

  @override
  String get taskListTitle => 'Задачи';

  @override
  String get taskListEmpty => 'Задач пока нет';

  @override
  String get taskLoadError => 'Не удалось загрузить задачи';

  @override
  String get taskUnavailable => 'Задача недоступна';

  @override
  String get taskCompletionMarkComplete => 'Отметить выполненной';

  @override
  String get taskCompletionMarkIncomplete => 'Отметить невыполненной';

  @override
  String get taskTitleFieldLabel => 'Название задачи';

  @override
  String get taskTitleRequired => 'Введите название задачи';

  @override
  String get taskCreateError => 'Не удалось создать задачу';

  @override
  String get taskCreateAction => 'Добавить задачу';
}
