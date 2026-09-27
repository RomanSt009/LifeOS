import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'lifeos_ollama_configuration.dart';

enum LifeOsOllamaTransportFailure { unavailable, timeout, unexpected }

final class LifeOsOllamaTransportException implements Exception {
  const LifeOsOllamaTransportException(this.failure);

  final LifeOsOllamaTransportFailure failure;
}

final class LifeOsOllamaHttpResponse {
  const LifeOsOllamaHttpResponse({
    required this.statusCode,
    required this.bodyBytes,
  });

  final int statusCode;
  final List<int> bodyBytes;
}

abstract interface class LifeOsOllamaHttpTransport {
  Future<String> getVersion();

  Future<String> getInstalledModels();

  Future<LifeOsOllamaHttpResponse> postChat(String body);
}

final class FixedLoopbackLifeOsOllamaHttpTransport
    implements LifeOsOllamaHttpTransport {
  FixedLoopbackLifeOsOllamaHttpTransport(
    this._client, {
    this.availabilityTimeout = lifeOsOllamaAvailabilityTimeout,
    this.inferenceTimeout = lifeOsOllamaInferenceTimeout,
  });

  static final Uri _versionUri = Uri.parse('$lifeOsOllamaBaseUri/api/version');
  static final Uri _tagsUri = Uri.parse('$lifeOsOllamaBaseUri/api/tags');
  static final Uri _chatUri = Uri.parse('$lifeOsOllamaBaseUri/api/chat');

  final http.Client _client;
  final Duration availabilityTimeout;
  final Duration inferenceTimeout;

  @override
  Future<String> getVersion() async {
    final response = await _send(
      () => _client.get(_versionUri),
      availabilityTimeout,
    );
    return _successfulBody(response);
  }

  @override
  Future<String> getInstalledModels() async {
    final response = await _send(
      () => _client.get(_tagsUri),
      availabilityTimeout,
    );
    return _successfulBody(response);
  }

  @override
  Future<LifeOsOllamaHttpResponse> postChat(String body) async {
    final response = await _send(
      () => _client.post(
        _chatUri,
        headers: const {'content-type': 'application/json; charset=utf-8'},
        body: body,
      ),
      inferenceTimeout,
    );
    return LifeOsOllamaHttpResponse(
      statusCode: response.statusCode,
      bodyBytes: List.unmodifiable(response.bodyBytes),
    );
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
    Duration timeout,
  ) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw const LifeOsOllamaTransportException(
        LifeOsOllamaTransportFailure.timeout,
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

  String _successfulBody(http.Response response) {
    if (response.statusCode != HttpStatus.ok) {
      throw const LifeOsOllamaTransportException(
        LifeOsOllamaTransportFailure.unexpected,
      );
    }
    return response.body;
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
