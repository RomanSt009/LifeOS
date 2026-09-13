import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/app.dart';
import 'package:lifeos/l10n/app_localizations.dart';

void main() {
  test('loads English and Russian localization resources', () async {
    final english = await AppLocalizations.delegate.load(const Locale('en'));
    final russian = await AppLocalizations.delegate.load(const Locale('ru'));

    expect(english.taskListTitle, 'Tasks');
    expect(english.taskCreateAction, 'Add Task');
    expect(english.taskCompletionError, 'Unable to update Task completion');
    expect(english.taskEditAction, 'Edit Task');
    expect(english.taskEditDialogTitle, 'Edit Task');
    expect(english.taskSaveAction, 'Save');
    expect(english.taskEditError, 'Unable to save Task');
    expect(english.trashAction, 'Trash');
    expect(english.deleteTaskDialogTitle, 'Move Task to Trash?');
    expect(english.restoreTaskAction, 'Restore Task');
    expect(english.deleteNoteDialogTitle, 'Move Note to Trash?');
    expect(english.noteEditAction, 'Edit Note');
    expect(english.restoreNoteAction, 'Restore Note');
    expect(english.retryAction, 'Retry');
    expect(english.relationshipUnlinkDialogTitle, 'Remove relationship?');
    expect(english.relationshipEndpointError, 'Unable to load related item');
    expect(english.navigationHome, 'Home');
    expect(english.navigationTasks, 'Tasks');
    expect(english.navigationSearch, 'Search');
    expect(english.searchClearAction, 'Clear search');
    expect(
      english.homeAlphaDescription,
      'Use the navigation to work with Tasks and Notes or search Task titles.',
    );
    expect(english.searchTitle, 'Search');
    expect(english.searchQueryFieldLabel, 'Task title');
    expect(english.searchAction, 'Search');
    expect(english.searchInitial, 'Enter a Task title to search');
    expect(english.searchNoResults, 'No Tasks found');
    expect(english.searchError, 'Unable to search Tasks');
    expect(russian.taskListTitle, 'Задачи');
    expect(russian.taskCreateAction, 'Добавить задачу');
    expect(russian.taskCompletionError, 'Не удалось изменить состояние задачи');
    expect(russian.taskEditAction, 'Изменить задачу');
    expect(russian.taskEditDialogTitle, 'Изменить задачу');
    expect(russian.taskSaveAction, 'Сохранить');
    expect(russian.taskEditError, 'Не удалось сохранить задачу');
    expect(russian.trashAction, 'Корзина');
    expect(russian.deleteTaskDialogTitle, 'Переместить задачу в корзину?');
    expect(russian.restoreTaskAction, 'Восстановить задачу');
    expect(russian.deleteNoteDialogTitle, 'Переместить заметку в корзину?');
    expect(russian.noteEditAction, 'Изменить заметку');
    expect(russian.restoreNoteAction, 'Восстановить заметку');
    expect(russian.retryAction, 'Повторить');
    expect(russian.relationshipUnlinkDialogTitle, 'Удалить связь?');
    expect(
      russian.relationshipEndpointError,
      'Не удалось загрузить связанный объект',
    );
    expect(russian.navigationHome, 'Главная');
    expect(russian.navigationTasks, 'Задачи');
    expect(russian.navigationSearch, 'Поиск');
    expect(russian.searchClearAction, 'Очистить поиск');
    expect(
      russian.homeAlphaDescription,
      'Используйте навигацию для работы с задачами и заметками или поиска по названиям задач.',
    );
    expect(russian.searchTitle, 'Поиск');
    expect(russian.searchQueryFieldLabel, 'Название задачи');
    expect(russian.searchAction, 'Найти');
    expect(russian.searchInitial, 'Введите название задачи для поиска');
    expect(russian.searchNoResults, 'Задачи не найдены');
    expect(russian.searchError, 'Не удалось выполнить поиск задач');
  });

  test('configures English and Russian as the supported locales', () {
    expect(AppLocalizations.supportedLocales, const [
      Locale('en'),
      Locale('ru'),
    ]);
  });

  testWidgets('uses the English platform locale', (tester) async {
    await pumpLocalizedAppForPlatformLocale(tester, const Locale('en'));

    expect(find.text('Personal Operating System'), findsOneWidget);
  });

  testWidgets('uses the Russian platform locale', (tester) async {
    await pumpLocalizedAppForPlatformLocale(tester, const Locale('ru'));

    expect(find.text('Персональная операционная система'), findsOneWidget);
  });

  testWidgets('falls back to English for an unsupported platform locale', (
    tester,
  ) async {
    await pumpLocalizedAppForPlatformLocale(tester, const Locale('de'));

    expect(find.text('Personal Operating System'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> pumpLocalizedAppForPlatformLocale(
  WidgetTester tester,
  Locale locale,
) async {
  tester.binding.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveLifeOsLocale,
      home: Builder(
        builder: (context) => Text(AppLocalizations.of(context).appDescription),
      ),
    ),
  );
  await tester.pump();
}
