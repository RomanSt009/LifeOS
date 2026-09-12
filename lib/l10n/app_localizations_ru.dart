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
  String get navigationNotes => 'Заметки';

  @override
  String get navigationSearch => 'Поиск';

  @override
  String get navigationSettings => 'Настройки';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get backupDataSectionTitle => 'Резервная копия и данные';

  @override
  String get backupDataSectionDescription =>
      'Создайте незашифрованную локальную резервную копию, экспортируйте данные или замените текущие данные из резервной копии.';

  @override
  String get backupCreateAction => 'Создать копию';

  @override
  String get exportDataAction => 'Экспортировать JSON';

  @override
  String get restoreBackupAction => 'Восстановить копию';

  @override
  String get backupZipFileTypeLabel => 'Резервная копия LifeOS';

  @override
  String get jsonFileTypeLabel => 'Документ JSON';

  @override
  String get backupOperationSelecting => 'Выбор файла…';

  @override
  String get backupOperationRunning => 'Операция выполняется…';

  @override
  String get backupCreateSuccess => 'Резервная копия создана.';

  @override
  String get exportDataSuccess => 'Экспорт успешно создан.';

  @override
  String get restoreBackupSuccess => 'Данные успешно восстановлены.';

  @override
  String get cancelAction => 'Отмена';

  @override
  String get restoreConfirmationTitle => 'Заменить текущие данные LifeOS?';

  @override
  String get restoreConfirmationMessage =>
      'Текущие локальные данные LifeOS будут заменены данными из резервной копии. Это не объединение данных, а локальные изменения, ожидающие синхронизации, не сохранятся в очереди после восстановления.';

  @override
  String get restoreReplaceAction => 'Восстановить и заменить';

  @override
  String get backupInvalidError =>
      'Резервная копия повреждена или имеет неверный формат.';

  @override
  String get backupUnsupportedError =>
      'Эта версия резервной копии не поддерживается.';

  @override
  String get backupChecksumError =>
      'Не удалось подтвердить целостность резервной копии.';

  @override
  String get backupDestinationExistsError =>
      'В выбранном месте уже существует файл.';

  @override
  String get backupFileSystemError =>
      'Не удалось прочитать или записать выбранный файл.';

  @override
  String get restoreConfirmationRequiredError =>
      'Перед заменой текущих данных требуется подтверждение.';

  @override
  String get restorePersistenceError =>
      'Не удалось заменить текущие данные LifeOS из резервной копии.';

  @override
  String get searchTitle => 'Поиск';

  @override
  String get searchQueryFieldLabel => 'Название задачи';

  @override
  String get searchAction => 'Найти';

  @override
  String get searchInitial => 'Введите название задачи для поиска';

  @override
  String get searchNoResults => 'Задачи не найдены';

  @override
  String get searchError => 'Не удалось выполнить поиск задач';

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

  @override
  String get noteListTitle => 'Заметки';

  @override
  String get noteListEmpty => 'Заметок пока нет';

  @override
  String get noteLoadError => 'Не удалось загрузить заметки';

  @override
  String get noteUntitled => 'Заметка без названия';

  @override
  String get noteCreateAction => 'Новая заметка';

  @override
  String get noteTitleFieldLabel => 'Название заметки';

  @override
  String get noteContentFieldLabel => 'Текст заметки';

  @override
  String get noteContentRequired => 'Введите название или текст';

  @override
  String get noteSaveAction => 'Сохранить заметку';

  @override
  String get noteSaveError => 'Не удалось сохранить заметку';
}
