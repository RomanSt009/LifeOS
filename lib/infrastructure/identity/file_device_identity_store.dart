import 'dart:io';

import 'package:path/path.dart' as path;

import 'uuid_v4_generator.dart';

const productionDeviceIdFileName = 'device_id';

class FileDeviceIdentityStore {
  FileDeviceIdentityStore(this._supportDirectory, this._identifierGenerator);

  final Directory _supportDirectory;
  final IdentifierGenerator _identifierGenerator;

  Future<String> resolve() async {
    await _supportDirectory.create(recursive: true);
    final identityFile = File(
      path.join(_supportDirectory.path, productionDeviceIdFileName),
    );

    if (await identityFile.exists()) {
      final storedIdentity = (await identityFile.readAsString()).trim();
      if (storedIdentity.isEmpty) {
        throw StateError('The stored LifeOS device identity is empty.');
      }
      return storedIdentity;
    }

    final identity = _identifierGenerator();
    if (identity.isEmpty) {
      throw StateError('The generated LifeOS device identity is empty.');
    }
    await identityFile.writeAsString(identity, flush: true);
    return identity;
  }
}
