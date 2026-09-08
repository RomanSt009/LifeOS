import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/app.dart';
import 'package:lifeos/app/dependencies.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';

void main() {
  testWidgets('closes the owned database when the app lifecycle ends', (
    tester,
  ) async {
    final database = LifeOsDatabase(NativeDatabase.memory());
    final dependencies = LifeOsAppDependencies(database: database);

    await tester.pumpWidget(LifeOSApp(dependencies: dependencies));
    await database.customSelect('SELECT 1').get();

    await tester.pumpWidget(const SizedBox.shrink());
    await dependencies.close();

    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(isA<StateError>()),
    );
  });
}
