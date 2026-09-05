import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/app.dart';

void main() {
  testWidgets('LifeOS shell displays the application title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LifeOSApp());

    expect(find.text('LifeOS'), findsNWidgets(2));
    expect(find.text('Personal Operating System'), findsOneWidget);
  });
}
