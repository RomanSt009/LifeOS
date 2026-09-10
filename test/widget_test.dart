import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/shell/lifeos_shell_page.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';

void main() {
  testWidgets('LifeOS shell displays the application title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lifeOsTaskRepositoryProvider.overrideWithValue(
            EmptyLifeOsTaskRepository(),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LifeosShellPage(),
        ),
      ),
    );

    expect(find.text('LifeOS'), findsNWidgets(2));
    expect(find.text('Personal Operating System'), findsOneWidget);
  });
}

class EmptyLifeOsTaskRepository implements LifeOsTaskRepository {
  @override
  Future<List<LifeOsTask>> getAll() async => [];

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async => null;

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async => [];

  @override
  Future<void> save(LifeOsTask task) async {}
}
