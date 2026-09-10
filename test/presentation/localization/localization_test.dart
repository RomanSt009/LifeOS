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
    expect(english.navigationHome, 'Home');
    expect(english.navigationTasks, 'Tasks');
    expect(english.searchTitle, 'Search');
    expect(english.searchQueryFieldLabel, 'Task title');
    expect(english.searchAction, 'Search');
    expect(english.searchInitial, 'Enter a Task title to search');
    expect(english.searchNoResults, 'No Tasks found');
    expect(english.searchError, 'Unable to search Tasks');
    expect(russian.taskListTitle, 'Задачи');
    expect(russian.taskCreateAction, 'Добавить задачу');
    expect(russian.navigationHome, 'Главная');
    expect(russian.navigationTasks, 'Задачи');
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
