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
  String get navigationWorkspaces => 'Пространства';

  @override
  String get navigationTasks => 'Задачи';

  @override
  String get navigationNotes => 'Заметки';

  @override
  String get navigationSearch => 'Поиск';

  @override
  String get navigationSettings => 'Настройки';

  @override
  String get homeAlphaDescription =>
      'Используйте навигацию для работы с задачами, заметками и пространствами или поиска по локальным данным.';

  @override
  String get homeContextDescription =>
      'Организуйте задачи и заметки вокруг важных жизненных контекстов.';

  @override
  String get homeWorkspacesTitle => 'Ваши рабочие пространства';

  @override
  String get homeWorkspacesEmpty =>
      'Создайте рабочее пространство, чтобы организовать жизненный контекст.';

  @override
  String get homeQuickActionsTitle => 'Быстрые действия';

  @override
  String get homeSecondaryActionsTitle => 'Другие действия';

  @override
  String get homeNewTaskAction => 'Новая задача';

  @override
  String get homeNewNoteAction => 'Новая заметка';

  @override
  String get homeSearchAction => 'Поиск';

  @override
  String get homeSettingsAction => 'Настройки / резервная копия';

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
  String get retryAction => 'Повторить';

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
  String get searchQueryFieldLabel => 'Поиск задач, заметок и пространств';

  @override
  String get searchAction => 'Найти';

  @override
  String get searchClearAction => 'Очистить поиск';

  @override
  String get searchInitial => 'Введите текст для поиска по локальным данным';

  @override
  String get searchNoResults => 'Ничего не найдено';

  @override
  String get searchError => 'Не удалось выполнить поиск по локальным данным';

  @override
  String get searchResultTaskType => 'Задача';

  @override
  String get searchResultNoteType => 'Заметка';

  @override
  String get searchResultWorkspaceType => 'Рабочее пространство';

  @override
  String get taskListTitle => 'Задачи';

  @override
  String get taskListEmpty => 'Задач пока нет';

  @override
  String get taskFilterAll => 'Все';

  @override
  String get taskFilterOpen => 'Активные';

  @override
  String get taskFilterCompleted => 'Выполненные';

  @override
  String get taskFilterOpenEmpty => 'Нет активных задач';

  @override
  String get taskFilterCompletedEmpty => 'Нет выполненных задач';

  @override
  String get taskLoadError => 'Не удалось загрузить задачи';

  @override
  String get taskUnavailable => 'Задача недоступна';

  @override
  String get taskCompletionMarkComplete => 'Отметить выполненной';

  @override
  String get taskCompletionMarkIncomplete => 'Отметить невыполненной';

  @override
  String get taskCompletionError => 'Не удалось изменить состояние задачи';

  @override
  String get taskTitleFieldLabel => 'Название задачи';

  @override
  String get taskTitleRequired => 'Введите название задачи';

  @override
  String get taskCreateError => 'Не удалось создать задачу';

  @override
  String get taskCreateAction => 'Добавить задачу';

  @override
  String get taskEditAction => 'Изменить задачу';

  @override
  String get taskEditDialogTitle => 'Изменить задачу';

  @override
  String get taskSaveAction => 'Сохранить';

  @override
  String get taskEditError => 'Не удалось сохранить задачу';

  @override
  String get trashAction => 'Корзина';

  @override
  String get backToTasksAction => 'Назад к задачам';

  @override
  String get backToNotesAction => 'Назад к заметкам';

  @override
  String get deleteTaskAction => 'Удалить задачу';

  @override
  String get deleteTaskDialogTitle => 'Переместить задачу в корзину?';

  @override
  String get moveToTrashAction => 'Переместить в корзину';

  @override
  String moveTaskToTrashConfirmation(String title) {
    return 'Задача «$title» будет перемещена в корзину, откуда её можно восстановить.';
  }

  @override
  String get restoreTaskAction => 'Восстановить задачу';

  @override
  String get taskTrashEmpty => 'Удалённых задач нет';

  @override
  String get taskDeleteError => 'Не удалось удалить задачу';

  @override
  String get taskRestoreError => 'Не удалось восстановить задачу';

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
  String get noteEditAction => 'Изменить заметку';

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

  @override
  String get noteUnsavedChangesIndicator => 'Есть несохранённые изменения';

  @override
  String get noteSavedStatus => 'Сохранено';

  @override
  String get noteUnsavedChangesDialogTitle => 'Сохранить изменения заметки?';

  @override
  String get noteUnsavedChangesDialogMessage =>
      'Несохранённые изменения будут потеряны, если продолжить.';

  @override
  String get saveChangesAction => 'Сохранить';

  @override
  String get discardChangesAction => 'Не сохранять';

  @override
  String get noteTrashTitle => 'Удалённые заметки';

  @override
  String get noteTrashDescription =>
      'Удалённые заметки можно восстановить из этого списка.';

  @override
  String get deleteNoteAction => 'Удалить заметку';

  @override
  String get deleteNoteDialogTitle => 'Переместить заметку в корзину?';

  @override
  String moveNoteToTrashConfirmation(String title) {
    return 'Заметка «$title» будет перемещена в корзину, откуда её можно восстановить.';
  }

  @override
  String get restoreNoteAction => 'Восстановить заметку';

  @override
  String get noteTrashEmpty => 'Удалённых заметок нет';

  @override
  String get noteDeleteError => 'Не удалось удалить заметку';

  @override
  String get noteRestoreError => 'Не удалось восстановить заметку';

  @override
  String get relationshipSectionTitle => 'Связанные';

  @override
  String get relationshipAddAction => 'Добавить связь';

  @override
  String get relationshipUnlinkAction => 'Удалить связь';

  @override
  String get relationshipEmpty => 'Нет связанных задач или заметок';

  @override
  String get relationshipLoading => 'Загрузка связанного объекта…';

  @override
  String get relationshipLoadError => 'Не удалось загрузить связи';

  @override
  String get relationshipSaveError => 'Не удалось обновить связи';

  @override
  String get relationshipUnavailable => 'Связанный объект недоступен';

  @override
  String get relationshipPickerTitle => 'Выберите задачу или заметку';

  @override
  String get relationshipPickerEmpty => 'Нет других задач или заметок';

  @override
  String get relationshipEndpointChoicesError =>
      'Не удалось загрузить доступные задачи и заметки';

  @override
  String get relationshipEndpointError =>
      'Не удалось загрузить связанный объект';

  @override
  String get relationshipUnlinkDialogTitle => 'Удалить связь?';

  @override
  String get relationshipUnlinkDialogMessage =>
      'Связь будет удалена из раздела «Связанные». Задача или заметка не будет удалена.';

  @override
  String relationshipTaskLabel(String title) {
    return 'Задача: $title';
  }

  @override
  String relationshipNoteLabel(String title) {
    return 'Заметка: $title';
  }

  @override
  String relationshipOpenTaskAction(String title) {
    return 'Открыть связанную задачу $title';
  }

  @override
  String relationshipOpenNoteAction(String title) {
    return 'Открыть связанную заметку $title';
  }

  @override
  String get workspaceListTitle => 'Рабочие пространства';

  @override
  String get workspaceListEmpty => 'Рабочих пространств пока нет';

  @override
  String get workspaceLoadError => 'Не удалось загрузить рабочие пространства';

  @override
  String get workspaceCreateAction => 'Новое рабочее пространство';

  @override
  String get workspaceEditAction => 'Изменить рабочее пространство';

  @override
  String get workspaceActionsTooltip => 'Действия с рабочим пространством';

  @override
  String get workspaceTitleFieldLabel => 'Название рабочего пространства';

  @override
  String get workspaceTitleRequired => 'Введите название рабочего пространства';

  @override
  String get workspaceDescriptionFieldLabel => 'Описание';

  @override
  String get workspaceNoDescription => 'Без описания';

  @override
  String get workspaceSaveError => 'Не удалось сохранить рабочее пространство';

  @override
  String get workspaceMoveToTrashAction => 'Переместить пространство в корзину';

  @override
  String get workspaceDeleteDialogTitle =>
      'Переместить пространство в корзину?';

  @override
  String workspaceMoveToTrashConfirmation(String title) {
    return 'Рабочее пространство «$title» будет перемещено в корзину. Его задачи, заметки, принадлежность и связи не будут удалены.';
  }

  @override
  String get workspaceDeleteError =>
      'Не удалось переместить пространство в корзину';

  @override
  String get workspaceTrashTitle => 'Корзина рабочих пространств';

  @override
  String get workspaceTrashEmpty => 'Удалённых рабочих пространств нет';

  @override
  String get workspaceRestoreAction => 'Восстановить рабочее пространство';

  @override
  String get workspaceRestoreError =>
      'Не удалось восстановить рабочее пространство';

  @override
  String get backToWorkspacesAction => 'Назад к рабочим пространствам';

  @override
  String get workspaceSelectPrompt => 'Выберите рабочее пространство';

  @override
  String get workspaceOpenAction => 'Открыть рабочее пространство';

  @override
  String get workspaceAddTaskAction => 'Добавить задачу';

  @override
  String get workspaceAddNoteAction => 'Добавить заметку';

  @override
  String get workspaceAttachExistingAction => 'Добавить существующее';

  @override
  String get workspaceTasksEmpty => 'В этом рабочем пространстве нет задач';

  @override
  String get workspaceNotesEmpty => 'В этом рабочем пространстве нет заметок';

  @override
  String get workspaceMembersLoadError =>
      'Не удалось загрузить содержимое рабочего пространства';

  @override
  String get workspaceTaskCreateError =>
      'Не удалось создать задачу в рабочем пространстве';

  @override
  String get workspaceNoteCreateError =>
      'Не удалось создать заметку в рабочем пространстве';

  @override
  String get workspaceAttachPickerTitle => 'Выберите задачу или заметку';

  @override
  String get workspaceAttachPickerEmpty =>
      'Нет доступных активных задач или заметок вне этого пространства';

  @override
  String get workspaceAttachError =>
      'Не удалось добавить объект в рабочее пространство';

  @override
  String get workspaceDetachAction => 'Убрать из рабочего пространства';

  @override
  String get workspaceDetachDialogTitle => 'Убрать из рабочего пространства?';

  @override
  String get workspaceDetachDialogMessage =>
      'Задача или заметка останется доступна вне этого рабочего пространства. Её связи не изменятся.';

  @override
  String get workspaceDetachError =>
      'Не удалось убрать объект из рабочего пространства';

  @override
  String get unassignedTitle => 'Без пространства';

  @override
  String get unassignedDescription =>
      'Активные задачи и заметки без активного контекста рабочего пространства.';

  @override
  String get unassignedEmpty =>
      'Нет задач или заметок без рабочего пространства';

  @override
  String get unassignedLoadError =>
      'Не удалось загрузить объекты без рабочего пространства';

  @override
  String get assignToWorkspaceAction => 'Добавить в пространство';

  @override
  String get assignWorkspaceEmpty =>
      'Сначала создайте активное рабочее пространство.';

  @override
  String get assignWorkspaceError =>
      'Не удалось добавить объект в рабочее пространство';
}
