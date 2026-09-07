import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/core/lifeos_identity.dart';

void main() {
  test('LifeOsIdentity contains the expected values', () {
    const identity = LifeOsIdentity(
      applicationName: 'LifeOS',
      applicationDescription: 'Personal Operating System',
    );

    expect(identity.applicationName, 'LifeOS');
    expect(identity.applicationDescription, 'Personal Operating System');
  });
}
