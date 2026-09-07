import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/get_lifeos_identity.dart';
import 'package:lifeos/domain/core/lifeos_identity.dart';

void main() {
  test('GetLifeOsIdentity returns the expected domain object', () {
    const getLifeOsIdentity = GetLifeOsIdentity();

    expect(
      getLifeOsIdentity(),
      const LifeOsIdentity(
        applicationName: 'LifeOS',
        applicationDescription: 'Personal Operating System',
      ),
    );
  });
}
