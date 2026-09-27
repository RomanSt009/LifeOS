import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/ai/lifeos_ai_context.dart';
import 'package:lifeos/application/ai/lifeos_ai_provider.dart';
import 'package:lifeos/application/use_cases/ask_about_lifeos_workspace.dart';
import 'package:lifeos/application/use_cases/build_lifeos_ai_context.dart';
import 'package:lifeos/application/use_cases/request_lifeos_ai_completion.dart';
import 'package:lifeos/application/workspaces/lifeos_workspace_context_reader.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_workspace.dart';
import 'package:lifeos/domain/repositories/lifeos_workspace_repository.dart';

void main() {
  const workspaceId = LifeOsEntityId(
    value: 'workspace-1',
    entityType: LifeOsEntityType.workspace,
  );
  final timestamp = DateTime.utc(2026, 9, 27);

  test(
    'builds fresh context on each explicit ask and calls provider once',
    () async {
      final repository = _WorkspaceRepository(
        _workspace(workspaceId, timestamp),
      );
      final reader = _ContextReader([
        _taskMember(_task('task-1', timestamp, title: 'First')),
      ]);
      final provider = _RecordingProvider();
      final ask = _ask(repository, reader, provider);

      expect(
        (await ask(workspaceId: workspaceId, question: '  First?  ')).text,
        'Answer 1',
      );
      reader.members = [
        _taskMember(_task('task-2', timestamp, title: 'Fresh')),
      ];
      expect(
        (await ask(workspaceId: workspaceId, question: 'Second?')).text,
        'Answer 2',
      );

      expect(provider.requests, hasLength(2));
      expect(provider.requests.first.userInstruction, 'First?');
      expect(
        provider.requests.first.context.items.single.entityId.value,
        'task-1',
      );
      expect(
        provider.requests.last.context.items.single.entityId.value,
        'task-2',
      );
      expect(repository.getByIdCount, 2);
      expect(reader.readCount, 2);
      expect(repository.saveCount, 0);
    },
  );

  test(
    'rejects whitespace-only question before context or provider work',
    () async {
      final repository = _WorkspaceRepository(
        _workspace(workspaceId, timestamp),
      );
      final reader = _ContextReader(const []);
      final provider = _RecordingProvider();

      await expectLater(
        _ask(repository, reader, provider)(
          workspaceId: workspaceId,
          question: '  \n ',
        ),
        throwsA(isA<LifeOsAiRequestValidationException>()),
      );
      expect(repository.getByIdCount, 0);
      expect(reader.readCount, 0);
      expect(provider.requests, isEmpty);
    },
  );

  test('does not call provider for missing or inactive Workspace', () async {
    for (final workspace in <LifeOsWorkspace?>[
      null,
      _workspace(
        workspaceId,
        timestamp,
        lifecycle: LifeOsEntityLifecycle.archived,
      ),
    ]) {
      final provider = _RecordingProvider();
      final reader = _ContextReader(const []);

      await expectLater(
        _ask(_WorkspaceRepository(workspace), reader, provider)(
          workspaceId: workspaceId,
          question: 'Question',
        ),
        throwsA(isA<LifeOsAiContextBuildException>()),
      );
      expect(provider.requests, isEmpty);
      expect(reader.readCount, 0);
    }
  });

  test('preserves provider-neutral failure unchanged', () async {
    const failure = LifeOsAiProviderException(LifeOsAiProviderError.network);
    final provider = _RecordingProvider(failure: failure);

    await expectLater(
      _ask(
        _WorkspaceRepository(_workspace(workspaceId, timestamp)),
        _ContextReader(const []),
        provider,
      )(workspaceId: workspaceId, question: 'Question'),
      throwsA(same(failure)),
    );
    expect(provider.requests, hasLength(1));
  });
}

AskAboutLifeOsWorkspace _ask(
  _WorkspaceRepository repository,
  _ContextReader reader,
  LifeOsAiProvider provider,
) {
  return AskAboutLifeOsWorkspace(
    buildContext: BuildLifeOsAiContext(
      workspaceRepository: repository,
      workspaceContextReader: reader,
    ),
    requestCompletion: RequestLifeOsAiCompletion(provider),
  );
}

LifeOsWorkspace _workspace(
  LifeOsEntityId id,
  DateTime timestamp, {
  LifeOsEntityLifecycle lifecycle = LifeOsEntityLifecycle.active,
}) => LifeOsWorkspace(
  id: id,
  title: 'Workspace',
  description: null,
  createdAt: timestamp,
  updatedAt: timestamp,
  lifecycle: lifecycle,
  version: 1,
  source: LifeOsEntitySource.user,
);

LifeOsTask _task(String id, DateTime timestamp, {required String title}) =>
    LifeOsTask(
      id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.task),
      title: title,
      isCompleted: false,
      createdAt: timestamp,
      updatedAt: timestamp,
      lifecycle: LifeOsEntityLifecycle.active,
      version: 1,
      source: LifeOsEntitySource.user,
    );

LifeOsWorkspaceTaskMember _taskMember(LifeOsTask task) =>
    LifeOsWorkspaceTaskMember(membershipId: null, task: task);

final class _WorkspaceRepository implements LifeOsWorkspaceRepository {
  _WorkspaceRepository(this.workspace);

  LifeOsWorkspace? workspace;
  var getByIdCount = 0;
  var saveCount = 0;

  @override
  Future<LifeOsWorkspace?> getById(LifeOsEntityId id) async {
    getByIdCount++;
    return workspace?.id == id ? workspace : null;
  }

  @override
  Future<List<LifeOsWorkspace>> getAll() async =>
      workspace == null ? [] : [workspace!];

  @override
  Future<List<LifeOsWorkspace>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async => workspace?.lifecycle == lifecycle ? [workspace!] : [];

  @override
  Future<void> save(LifeOsWorkspace workspace) async {
    saveCount++;
  }
}

final class _ContextReader implements LifeOsWorkspaceContextReader {
  _ContextReader(this.members);

  List<LifeOsWorkspaceMember> members;
  var readCount = 0;

  @override
  Future<List<LifeOsWorkspaceMember>> getDirectMembers(
    LifeOsEntityId workspaceId,
  ) async {
    readCount++;
    return members;
  }

  @override
  Future<List<LifeOsWorkspaceMember>> getUnassigned() async => const [];
}

final class _RecordingProvider implements LifeOsAiProvider {
  _RecordingProvider({this.failure});

  final LifeOsAiProviderException? failure;
  final requests = <LifeOsAiRequest>[];

  @override
  Future<LifeOsAiResponse> generate(LifeOsAiRequest request) async {
    requests.add(request);
    if (failure case final failure?) throw failure;
    return LifeOsAiResponse(text: 'Answer ${requests.length}');
  }
}
