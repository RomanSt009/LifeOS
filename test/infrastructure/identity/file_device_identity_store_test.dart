import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/infrastructure/identity/file_device_identity_store.dart';

void main() {
  test('creates one device identity and reuses it after reopening', () async {
    final supportDirectory = await Directory.systemTemp.createTemp(
      'lifeos-device-identity-',
    );
    addTearDown(() => supportDirectory.delete(recursive: true));
    var generationCount = 0;

    String generateIdentity() {
      generationCount += 1;
      return 'device-$generationCount';
    }

    final firstIdentity = await FileDeviceIdentityStore(
      supportDirectory,
      generateIdentity,
    ).resolve();
    final reopenedIdentity = await FileDeviceIdentityStore(
      supportDirectory,
      generateIdentity,
    ).resolve();

    expect(firstIdentity, 'device-1');
    expect(reopenedIdentity, firstIdentity);
    expect(generationCount, 1);
  });
}
