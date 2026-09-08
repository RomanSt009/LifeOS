import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/infrastructure/identity/uuid_v4_generator.dart';

void main() {
  test('generates UUID version 4 identifiers', () {
    final identifier = generateUuidV4();

    expect(
      identifier,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });
}
