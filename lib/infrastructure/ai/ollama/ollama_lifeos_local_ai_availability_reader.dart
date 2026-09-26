import 'dart:convert';

import '../../../application/ai/lifeos_local_ai_availability.dart';
import 'lifeos_ollama_configuration.dart';
import 'lifeos_ollama_http_transport.dart';

final class OllamaLifeOsLocalAiAvailabilityReader
    implements LifeOsLocalAiAvailabilityReader {
  const OllamaLifeOsLocalAiAvailabilityReader(this._transport);

  final LifeOsOllamaHttpTransport _transport;

  @override
  Future<LifeOsLocalAiAvailability> read() async {
    final String versionBody;
    try {
      versionBody = await _transport.getVersion();
    } on LifeOsOllamaTransportException catch (error) {
      return _mapTransportFailure(error);
    }
    _validateVersion(versionBody);

    final String modelsBody;
    try {
      modelsBody = await _transport.getInstalledModels();
    } on LifeOsOllamaTransportException catch (error) {
      return _mapTransportFailure(error);
    }

    final installedModels = _parseInstalledModels(modelsBody);
    return installedModels.contains(lifeOsOllamaModel)
        ? LifeOsLocalAiAvailability.runtimeAvailableModelAvailable
        : LifeOsLocalAiAvailability.runtimeAvailableModelMissing;
  }

  Never _throwFailure(LifeOsLocalAiAvailabilityFailure failure) {
    throw LifeOsLocalAiAvailabilityException(failure);
  }

  LifeOsLocalAiAvailability _mapTransportFailure(
    LifeOsOllamaTransportException error,
  ) {
    return switch (error.failure) {
      LifeOsOllamaTransportFailure.unavailable =>
        LifeOsLocalAiAvailability.runtimeUnavailable,
      LifeOsOllamaTransportFailure.unexpected => _throwFailure(
        LifeOsLocalAiAvailabilityFailure.unexpectedTransport,
      ),
    };
  }

  void _validateVersion(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      _throwFailure(LifeOsLocalAiAvailabilityFailure.malformedResponse);
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] is! String ||
        (decoded['version'] as String).trim().isEmpty) {
      _throwFailure(LifeOsLocalAiAvailabilityFailure.malformedResponse);
    }
  }

  Set<String> _parseInstalledModels(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      _throwFailure(LifeOsLocalAiAvailabilityFailure.malformedResponse);
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['models'] is! List<Object?>) {
      _throwFailure(LifeOsLocalAiAvailabilityFailure.malformedResponse);
    }

    final names = <String>{};
    for (final model in decoded['models'] as List<Object?>) {
      if (model is! Map<String, dynamic> || model['name'] is! String) {
        _throwFailure(LifeOsLocalAiAvailabilityFailure.malformedResponse);
      }
      names.add(model['name'] as String);
    }
    return names;
  }
}
