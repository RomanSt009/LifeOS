import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/navigation/lifeos_destination.dart';
import 'package:lifeos/presentation/shell/lifeos_shell_page.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';
import 'package:lifeos/presentation/tasks/task_list.dart';

void main() {
  testWidgets('exposes only the justified initial destinations', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const Locale('en')));
    await tester.pumpAndSettle();

    final navigationRail = tester.widget<NavigationRail>(
      find.byType(NavigationRail),
    );

    expect(LifeOsDestination.values, [
      LifeOsDestination.home,
      LifeOsDestination.tasks,
    ]);
    expect(navigationRail.destinations, hasLength(2));
    expect(destinationLabels(navigationRail), ['Home', 'Tasks']);
  });

  testWidgets('shows a persistent desktop frame with Tasks selected', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const Locale('en')));
    await tester.pumpAndSettle();

    final navigationRail = tester.widget<NavigationRail>(
      find.byType(NavigationRail),
    );

    expect(navigationRail.selectedIndex, LifeOsDestination.tasks.index);
    expect(navigationRail.labelType, NavigationRailLabelType.all);
    expect(destinationLabels(navigationRail), ['Home', 'Tasks']);
    expect(find.byType(TaskList), findsOneWidget);
    expect(find.byKey(const Key('task-title-field')), findsOneWidget);
  });

  testWidgets('switches shell-local destination state and keeps Task content', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const Locale('en')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      LifeOsDestination.home.index,
    );
    expect(find.byKey(const Key('home-placeholder-title')), findsOneWidget);
    expect(find.byType(TaskList), findsNothing);
    expect(find.byType(TaskList, skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      LifeOsDestination.tasks.index,
    );
    expect(find.byKey(const Key('task-title-field')), findsOneWidget);
  });

  testWidgets('localizes shell navigation labels in Russian', (tester) async {
    await tester.pumpWidget(testApp(const Locale('ru')));
    await tester.pumpAndSettle();

    final navigationRail = tester.widget<NavigationRail>(
      find.byType(NavigationRail),
    );

    expect(destinationLabels(navigationRail), ['Главная', 'Задачи']);
  });
}

List<String> destinationLabels(NavigationRail navigationRail) {
  return [
    for (final destination in navigationRail.destinations)
      (destination.label as Text).data!,
  ];
}

Widget testApp(Locale locale) {
  return ProviderScope(
    overrides: [
      lifeOsTaskRepositoryProvider.overrideWithValue(
        EmptyLifeOsTaskRepository(),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LifeosShellPage(),
    ),
  );
}

class EmptyLifeOsTaskRepository implements LifeOsTaskRepository {
  @override
  Future<List<LifeOsTask>> getAll() async => [];

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async => null;

  @override
  Future<void> save(LifeOsTask task) async {}
}
