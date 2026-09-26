import '../ai/lifeos_ai_context.dart';
import '../ai/lifeos_ai_provider.dart';

final class RequestLifeOsAiCompletion {
  const RequestLifeOsAiCompletion(this._provider);

  final LifeOsAiProvider _provider;

  Future<LifeOsAiResponse> call({
    required LifeOsAiRequestPurpose purpose,
    required String userInstruction,
    required LifeOsAiContext context,
  }) async {
    final request = LifeOsAiRequest(
      purpose: purpose,
      userInstruction: userInstruction,
      context: context,
    );
    final response = await _provider.generate(request);
    final allowedReferences = {
      context.rootWorkspace.workspaceId,
      ...context.items.map((item) => item.entityId),
    };
    if (response.contextReferences.any(
      (reference) => !allowedReferences.contains(reference),
    )) {
      throw const LifeOsAiProviderException(
        LifeOsAiProviderError.invalidResponse,
      );
    }
    return response;
  }
}
