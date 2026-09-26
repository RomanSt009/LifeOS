import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lifeos/application/ai/lifeos_local_ai_availability.dart';
import 'package:lifeos/infrastructure/ai/ollama/lifeos_ollama_configuration.dart';
import 'package:lifeos/infrastructure/ai/ollama/lifeos_ollama_http_transport.dart';
import 'package:lifeos/infrastructure/ai/ollama/ollama_lifeos_local_ai_availability_reader.dart';

void main() {
  group('Ollama local AI availability', () {
    test('uses only the fixed loopback version and tags endpoints', () async {
      final requests = <http.Request>[];
      final reader = _reader(
        MockClient((request) async {
          requests.add(request);
          return switch (request.url.path) {
            '/api/version' => http.Response('{"version":"0.12.0"}', 200),
            '/api/tags' => http.Response(
              '{"models":[{"name":"qwen3:4b"}]}',
              200,
            ),
            _ => http.Response('', 404),
          };
        }),
      );

      expect(
        await reader.read(),
        LifeOsLocalAiAvailability.runtimeAvailableModelAvailable,
      );
      expect(requests.map((request) => request.url.toString()), [
        'http://127.0.0.1:11434/api/version',
        'http://127.0.0.1:11434/api/tags',
      ]);
      expect(requests.every((request) => request.method == 'GET'), isTrue);
    });

    test('reports an unavailable runtime after a connection failure', () async {
      final reader = _reader(
        MockClient((_) async => throw http.ClientException('offline')),
      );

      expect(await reader.read(), LifeOsLocalAiAvailability.runtimeUnavailable);
    });

    test('reports an unavailable runtime after the bounded timeout', () async {
      final reader = _reader(
        MockClient((_) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 1),
      );

      expect(await reader.read(), LifeOsLocalAiAvailability.runtimeUnavailable);
    });

    test('reports a missing fixed model without choosing a fallback', () async {
      final reader = _reader(
        _successfulClient(modelsJson: '{"models":[{"name":"qwen3:8b"}]}'),
      );

      expect(
        await reader.read(),
        LifeOsLocalAiAvailability.runtimeAvailableModelMissing,
      );
    });

    test('matches the fixed model identifier exactly', () async {
      final reader = _reader(
        _successfulClient(
          modelsJson: '{"models":[{"name":"qwen3:4b-latest"}]}',
        ),
      );

      expect(
        await reader.read(),
        LifeOsLocalAiAvailability.runtimeAvailableModelMissing,
      );
      expect(lifeOsOllamaModel, 'qwen3:4b');
    });

    test('maps malformed version JSON to a typed failure', () async {
      final reader = _reader(
        MockClient((request) async => http.Response('{"version":""}', 200)),
      );

      await expectLater(
        reader.read(),
        throwsA(_failure(LifeOsLocalAiAvailabilityFailure.malformedResponse)),
      );
    });

    test('maps malformed tags JSON to a typed failure', () async {
      final reader = _reader(_successfulClient(modelsJson: '{"models":[{}]}'));

      await expectLater(
        reader.read(),
        throwsA(_failure(LifeOsLocalAiAvailabilityFailure.malformedResponse)),
      );
    });

    test('maps an unexpected transport error without leaking it', () async {
      final reader = _reader(
        MockClient((_) async => throw StateError('private transport detail')),
      );

      await expectLater(
        reader.read(),
        throwsA(_failure(LifeOsLocalAiAvailabilityFailure.unexpectedTransport)),
      );
    });

    test('uses an inspectable DIRECT proxy resolver for loopback access', () {
      expect(
        lifeOsOllamaDirectProxy(Uri.parse('$lifeOsOllamaBaseUri/api/version')),
        'DIRECT',
      );
    });
  });
}

OllamaLifeOsLocalAiAvailabilityReader _reader(
  http.Client client, {
  Duration timeout = lifeOsOllamaAvailabilityTimeout,
}) {
  return OllamaLifeOsLocalAiAvailabilityReader(
    FixedLoopbackLifeOsOllamaHttpTransport(client, timeout: timeout),
  );
}

MockClient _successfulClient({required String modelsJson}) {
  return MockClient((request) async {
    return switch (request.url.path) {
      '/api/version' => http.Response('{"version":"0.12.0"}', 200),
      '/api/tags' => http.Response(modelsJson, 200),
      _ => http.Response('', 404),
    };
  });
}

Matcher _failure(LifeOsLocalAiAvailabilityFailure failure) {
  return isA<LifeOsLocalAiAvailabilityException>().having(
    (error) => error.failure,
    'failure',
    failure,
  );
}
