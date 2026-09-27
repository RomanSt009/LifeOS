import '../../domain/entities/lifeos_entity.dart';
import '../ai/lifeos_ai_context.dart';
import '../ai/lifeos_ai_provider.dart';
import 'build_lifeos_ai_context.dart';
import 'request_lifeos_ai_completion.dart';

final class AskAboutLifeOsWorkspace {
  AskAboutLifeOsWorkspace({
    required BuildLifeOsAiContext buildContext,
    required RequestLifeOsAiCompletion requestCompletion,
  }) : // Keep stable public names while the collaborators remain encapsulated.
       // ignore: prefer_initializing_formals
       _buildContext = buildContext,
       // ignore: prefer_initializing_formals
       _requestCompletion = requestCompletion;

  final BuildLifeOsAiContext _buildContext;
  final RequestLifeOsAiCompletion _requestCompletion;

  Future<LifeOsAiResponse> call({
    required LifeOsEntityId workspaceId,
    required String question,
  }) async {
    if (question.trim().isEmpty) {
      throw const LifeOsAiRequestValidationException(
        LifeOsAiRequestValidationError.emptyInstruction,
      );
    }

    final context = await _buildContext(
      BuildLifeOsAiContextInput(
        workspaceId: workspaceId,
        budget: LifeOsAiContextBudget(
          maxItems: 30,
          maxCharacters: 24000,
          maxCharactersPerItem: 4000,
        ),
      ),
    );
    return _requestCompletion(
      purpose: LifeOsAiRequestPurpose.workspaceQuestion,
      userInstruction: question,
      context: context,
    );
  }
}
