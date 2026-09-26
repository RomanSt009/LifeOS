import '../../domain/entities/lifeos_entity.dart';
import 'lifeos_ai_context.dart';

enum LifeOsAiRequestPurpose { workspaceQuestion }

enum LifeOsAiRequestValidationError { emptyInstruction }

final class LifeOsAiRequestValidationException implements Exception {
  const LifeOsAiRequestValidationException(this.error);

  final LifeOsAiRequestValidationError error;

  @override
  String toString() => 'LifeOsAiRequestValidationException($error)';
}

enum LifeOsAiProviderError {
  unavailable,
  invalidConfiguration,
  authentication,
  rateLimited,
  network,
  requestRejected,
  invalidResponse,
  unknown,
}

final class LifeOsAiProviderException implements Exception {
  const LifeOsAiProviderException(this.error);

  final LifeOsAiProviderError error;

  @override
  String toString() => 'LifeOsAiProviderException($error)';
}

final class LifeOsAiRequest {
  LifeOsAiRequest({
    required this.purpose,
    required String userInstruction,
    required this.context,
  }) : userInstruction = _normalizeInstruction(userInstruction);

  final LifeOsAiRequestPurpose purpose;
  final String userInstruction;
  final LifeOsAiContext context;
}

final class LifeOsAiResponse {
  LifeOsAiResponse({
    required this.text,
    Iterable<LifeOsEntityId> contextReferences = const [],
  }) : contextReferences = List.unmodifiable(contextReferences) {
    if (text.trim().isEmpty) {
      throw const LifeOsAiProviderException(
        LifeOsAiProviderError.invalidResponse,
      );
    }
  }

  final String text;
  final List<LifeOsEntityId> contextReferences;
}

/// Single-turn, non-streaming outbound boundary for an already-built context.
///
/// Implementations must keep vendor, transport, credentials and prompt
/// formatting outside Application. They must not log full instructions,
/// context content, secrets or private responses.
abstract interface class LifeOsAiProvider {
  Future<LifeOsAiResponse> generate(LifeOsAiRequest request);
}

String _normalizeInstruction(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw const LifeOsAiRequestValidationException(
      LifeOsAiRequestValidationError.emptyInstruction,
    );
  }
  return normalized;
}
