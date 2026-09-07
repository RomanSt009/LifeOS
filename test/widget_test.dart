import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:lifeos/application/use_cases/get_lifeos_identity.dart';
import 'package:lifeos/presentation/shell/lifeos_shell_page.dart';

void main() {
  testWidgets('LifeOS shell displays the application title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LifeosShellPage(getLifeOsIdentity: GetLifeOsIdentity()),
      ),
    );

    expect(find.text('LifeOS'), findsNWidgets(2));
    expect(find.text('Personal Operating System'), findsOneWidget);
  });
}
