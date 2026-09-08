import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/app.dart';
import 'package:lifeos/app/dependencies.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_task_repository.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';

void main() {
  testWidgets('closes the owned database when the app lifecycle ends', (
    tester,
  ) async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    final dependencies = LifeOsAppDependencies(
      database: database,
      taskRepository: DriftLifeOsTaskRepository(
        database,
        () => 'change-test',
        'device-test',
      ),
    );

    await tester.pumpWidget(LifeOSApp(dependencies: dependencies));
    await database.customSelect('SELECT 1').get();

    await tester.pumpWidget(const SizedBox.shrink());
    await dependencies.close();

    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(isA<StateError>()),
    );
  });

  testWidgets('provides the composed Domain repository to Presentation', (
    tester,
  ) async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    final repository = DriftLifeOsTaskRepository(
      database,
      () => 'change-test',
      'device-test',
    );
    final dependencies = LifeOsAppDependencies(
      database: database,
      taskRepository: repository,
    );

    await tester.pumpWidget(LifeOSApp(dependencies: dependencies));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );

    expect(container.read(lifeOsTaskRepositoryProvider), same(repository));

    await tester.pumpWidget(const SizedBox.shrink());
    await dependencies.close();
  });
}
