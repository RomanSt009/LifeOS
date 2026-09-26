import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'lifeos_ollama_configuration.dart';

enum LifeOsOllamaTransportFailure { unavailable, unexpected }

final class LifeOsOllamaTransportException implements Exception {
  const LifeOsOllamaTransportException(this.failure);

  final LifeOsOllamaTransportFailure failure;
}

abstract interface class LifeOsOllamaHttpTransport {
  Future<String> getVersion();

  Future<String> getInstalledModels();
}

final class FixedLoopbackLifeOsOllamaHttpTransport
    implements LifeOsOllamaHttpTransport {
  FixedLoopbackLifeOsOllamaHttpTransport(
    this._client, {
    this.timeout = lifeOsOllamaAvailabilityTimeout,
  });

  static final Uri _versionUri = Uri.parse('$lifeOsOllamaBaseUri/api/version');
  static final Uri _tagsUri = Uri.parse('$lifeOsOllamaBaseUri/api/tags');

  final http.Client _client;
  final Duration timeout;

  @override
  Future<String> getVersion() => _get(_versionUri);

  @override
  Future<String> getInstalledModels() => _get(_tagsUri);

  Future<String> _get(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        throw const LifeOsOllamaTransportException(
          LifeOsOllamaTransportFailure.unexpected,
        );
      }
      return response.body;
    } on TimeoutException {
      throw const LifeOsOllamaTransportException(
        LifeOsOllamaTransportFailure.unavailable,
      );
    } on SocketException {
      throw const LifeOsOllamaTransportException(
        LifeOsOllamaTransportFailure.unavailable,
      );
    } on http.ClientException {
      throw const LifeOsOllamaTransportException(
        LifeOsOllamaTransportFailure.unavailable,
      );
    } on LifeOsOllamaTransportException {
      rethrow;
    } catch (_) {
      throw const LifeOsOllamaTransportException(
        LifeOsOllamaTransportFailure.unexpected,
      );
    }
  }
}

http.Client createDirectLifeOsOllamaHttpClient() {
  final ioClient = HttpClient();
  configureDirectLifeOsOllamaHttpClient(ioClient);
  return IOClient(ioClient);
}

void configureDirectLifeOsOllamaHttpClient(HttpClient client) {
  client.findProxy = lifeOsOllamaDirectProxy;
}

String lifeOsOllamaDirectProxy(Uri _) => 'DIRECT';
