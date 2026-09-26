import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/ai/lifeos_ai_context.dart';
import 'package:lifeos/application/ai/lifeos_ai_provider.dart';
import 'package:lifeos/application/use_cases/request_lifeos_ai_completion.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';

void main() {
  const workspaceId = LifeOsEntityId(
    value: 'workspace-1',
    entityType: LifeOsEntityType.workspace,
  );
  const taskId = LifeOsEntityId(
    value: 'task-1',
    entityType: LifeOsEntityType.task,
  );

  test('preserves structured context and normalized instruction', () async {
    final context = _context(workspaceId, taskId);
    final provider = _FakeProvider(
      (request) async =>
          LifeOsAiResponse(text: 'Result', contextReferences: [taskId]),
    );

    final response = await RequestLifeOsAiCompletion(provider)(
      purpose: LifeOsAiRequestPurpose.workspaceQuestion,
      userInstruction: '  What matters?  ',
      context: context,
    );

    expect(response.text, 'Result');
    expect(response.contextReferences, [taskId]);
    expect(provider.requests, hasLength(1));
    expect(
      provider.requests.single.purpose,
      LifeOsAiRequestPurpose.workspaceQuestion,
    );
    expect(provider.requests.single.userInstruction, 'What matters?');
    expect(provider.requests.single.context, same(context));
    expect(context.items.single, isA<LifeOsAiTaskContextItem>());
    expect((context.items.single as LifeOsAiTaskContextItem).title, 'Task');
  });

  test('rejects an empty instruction before calling provider', () async {
    final provider = _FakeProvider(
      (request) async => LifeOsAiResponse(text: 'unused'),
    );

    await expectLater(
      RequestLifeOsAiCompletion(provider)(
        purpose: LifeOsAiRequestPurpose.workspaceQuestion,
        userInstruction: '   ',
        context: _context(workspaceId, taskId),
      ),
      throwsA(
        isA<LifeOsAiRequestValidationException>().having(
          (error) => error.error,
          'error',
          LifeOsAiRequestValidationError.emptyInstruction,
        ),
      ),
    );
    expect(provider.requests, isEmpty);
  });

  test('rejects an empty provider response with typed error', () {
    expect(
      () => LifeOsAiResponse(text: ' \n '),
      throwsA(
        isA<LifeOsAiProviderException>().having(
          (error) => error.error,
          'error',
          LifeOsAiProviderError.invalidResponse,
        ),
      ),
    );
  });

  test('preserves provider-neutral failures', () async {
    const failure = LifeOsAiProviderException(
      LifeOsAiProviderError.unavailable,
    );
    final provider = _FakeProvider((request) async => throw failure);

    await expectLater(
      RequestLifeOsAiCompletion(provider)(
        purpose: LifeOsAiRequestPurpose.workspaceQuestion,
        userInstruction: 'Question',
        context: _context(workspaceId, taskId),
      ),
      throwsA(same(failure)),
    );
  });

  test('rejects response references outside the request context', () async {
    const unrelatedId = LifeOsEntityId(
      value: 'note-unrelated',
      entityType: LifeOsEntityType.note,
    );
    final provider = _FakeProvider(
      (request) async =>
          LifeOsAiResponse(text: 'Result', contextReferences: [unrelatedId]),
    );

    await expectLater(
      RequestLifeOsAiCompletion(provider)(
        purpose: LifeOsAiRequestPurpose.workspaceQuestion,
        userInstruction: 'Question',
        context: _context(workspaceId, taskId),
      ),
      throwsA(
        isA<LifeOsAiProviderException>().having(
          (error) => error.error,
          'error',
          LifeOsAiProviderError.invalidResponse,
        ),
      ),
    );
  });
}

LifeOsAiContext _context(LifeOsEntityId workspaceId, LifeOsEntityId taskId) {
  final budget = LifeOsAiContextBudget(
    maxItems: 1,
    maxCharacters: 20,
    maxCharactersPerItem: 10,
  );
  return LifeOsAiContext(
    rootWorkspace: LifeOsAiWorkspaceContextRoot(
      workspaceId: workspaceId,
      title: 'Work',
      description: null,
      descriptionTruncated: false,
      originalDescriptionCharacterCount: 0,
      characterCount: 4,
    ),
    items: [
      LifeOsAiTaskContextItem(
        entityId: taskId,
        title: 'Task',
        isCompleted: false,
        characterCount: 4,
      ),
    ],
    budget: budget,
    usage: const LifeOsAiContextBudgetUsage(
      itemCount: 1,
      characterCount: 8,
      omittedItemCount: 0,
      deduplicatedItemCount: 0,
      truncatedProjectionCount: 0,
    ),
  );
}

final class _FakeProvider implements LifeOsAiProvider {
  _FakeProvider(this._handler);

  final Future<LifeOsAiResponse> Function(LifeOsAiRequest request) _handler;
  final requests = <LifeOsAiRequest>[];

  @override
  Future<LifeOsAiResponse> generate(LifeOsAiRequest request) {
    requests.add(request);
    return _handler(request);
  }
}
