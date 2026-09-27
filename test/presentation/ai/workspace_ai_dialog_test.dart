import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/ai/lifeos_ai_provider.dart';
import 'package:lifeos/application/ai/lifeos_local_ai_availability.dart';
import 'package:lifeos/application/use_cases/ask_about_lifeos_workspace.dart';
import 'package:lifeos/application/use_cases/build_lifeos_ai_context.dart';
import 'package:lifeos/application/use_cases/check_lifeos_local_ai_availability.dart';
import 'package:lifeos/application/use_cases/request_lifeos_ai_completion.dart';
import 'package:lifeos/application/workspaces/lifeos_workspace_context_reader.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_workspace.dart';
import 'package:lifeos/domain/repositories/lifeos_workspace_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/ai/local_ai_providers.dart';
import 'package:lifeos/presentation/ai/workspace_ai_dialog.dart';

void main() {
  testWidgets('checks explicitly and returns one local plain-text response', (
    tester,
  ) async {
    final harness = _Harness();
    await _pump(tester, harness);
    await tester.pumpAndSettle();

    expect(harness.availability.calls, 1);
    expect(find.text('Local model qwen2.5-coder:7b is ready.'), findsOneWidget);
    expect(find.byKey(const Key('workspace-ai-local-notice')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('workspace-ai-question-field')),
      '  What matters?  ',
    );
    await tester.tap(find.byKey(const Key('workspace-ai-send')));
    await tester.pumpAndSettle();

    expect(harness.provider.requests, hasLength(1));
    expect(harness.provider.requests.single.userInstruction, 'What matters?');
    expect(find.text('Local answer'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
  });

  testWidgets('blocks duplicate send while one request is pending', (
    tester,
  ) async {
    final pending = Completer<LifeOsAiResponse>();
    final harness = _Harness(providerResults: [pending.future]);
    await _pump(tester, harness);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workspace-ai-question-field')),
      'Question',
    );

    await tester.tap(find.byKey(const Key('workspace-ai-send')));
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('workspace-ai-send')),
      warnIfMissed: false,
    );
    expect(harness.provider.requests, hasLength(1));
    expect(find.byKey(const Key('workspace-ai-progress')), findsOneWidget);

    pending.complete(LifeOsAiResponse(text: 'Done'));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('recovers from request error with an explicit fresh retry', (
    tester,
  ) async {
    final harness = _Harness(
      providerResults: [
        const LifeOsAiProviderException(LifeOsAiProviderError.network),
        LifeOsAiResponse(text: 'Recovered'),
      ],
    );
    await _pump(tester, harness);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workspace-ai-question-field')),
      'Question',
    );

    await tester.tap(find.byKey(const Key('workspace-ai-send')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-ai-error')), findsOneWidget);

    await tester.tap(find.byKey(const Key('workspace-ai-retry')));
    await tester.pumpAndSettle();
    expect(harness.provider.requests, hasLength(2));
    expect(find.text('Recovered'), findsOneWidget);
  });

  testWidgets('shows runtime/model unavailable states without sending', (
    tester,
  ) async {
    for (final availability in [
      LifeOsLocalAiAvailability.runtimeUnavailable,
      LifeOsLocalAiAvailability.runtimeAvailableModelMissing,
    ]) {
      final harness = _Harness(availability: availability);
      await _pump(tester, harness);
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          Key(
            availability == LifeOsLocalAiAvailability.runtimeUnavailable
                ? 'workspace-ai-runtime-unavailable'
                : 'workspace-ai-model-missing',
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('workspace-ai-send')))
            .onPressed,
        isNull,
      );
      expect(harness.provider.requests, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('ignores a late response after dialog disposal', (tester) async {
    final pending = Completer<LifeOsAiResponse>();
    final harness = _Harness(providerResults: [pending.future]);
    await _pump(tester, harness);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workspace-ai-question-field')),
      'Question',
    );
    await tester.tap(find.byKey(const Key('workspace-ai-send')));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(LifeOsAiResponse(text: 'Late'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('localizes the dialog and fixed model status in Russian', (
    tester,
  ) async {
    await _pump(tester, _Harness(), locale: const Locale('ru'));
    await tester.pumpAndSettle();

    expect(find.text('Спросить об этом пространстве'), findsOneWidget);
    expect(
      find.text('Локальная модель qwen2.5-coder:7b готова.'),
      findsOneWidget,
    );
    expect(find.text('Отправить'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  _Harness harness, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        checkLifeOsLocalAiAvailabilityProvider.overrideWithValue(
          CheckLifeOsLocalAiAvailability(harness.availability),
        ),
        askAboutLifeOsWorkspaceProvider.overrideWithValue(harness.ask),
        lifeOsLocalAiModelNameProvider.overrideWithValue('qwen2.5-coder:7b'),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: WorkspaceAiDialog(workspaceId: harness.workspace.id),
        ),
      ),
    ),
  );
}

final class _Harness {
  _Harness({
    LifeOsLocalAiAvailability availability =
        LifeOsLocalAiAvailability.runtimeAvailableModelAvailable,
    List<Object>? providerResults,
  }) : workspace = LifeOsWorkspace(
         id: const LifeOsEntityId(
           value: 'workspace-1',
           entityType: LifeOsEntityType.workspace,
         ),
         title: 'Workspace',
         description: null,
         createdAt: DateTime.utc(2026, 9, 27),
         updatedAt: DateTime.utc(2026, 9, 27),
         lifecycle: LifeOsEntityLifecycle.active,
         version: 1,
         source: LifeOsEntitySource.user,
       ),
       availability = _AvailabilityReader(availability),
       provider = _Provider(
         providerResults ?? [LifeOsAiResponse(text: 'Local answer')],
       ) {
    ask = AskAboutLifeOsWorkspace(
      buildContext: BuildLifeOsAiContext(
        workspaceRepository: _WorkspaceRepository(workspace),
        workspaceContextReader: const _ContextReader(),
      ),
      requestCompletion: RequestLifeOsAiCompletion(provider),
    );
  }

  final LifeOsWorkspace workspace;
  final _AvailabilityReader availability;
  final _Provider provider;
  late final AskAboutLifeOsWorkspace ask;
}

final class _AvailabilityReader implements LifeOsLocalAiAvailabilityReader {
  _AvailabilityReader(this.result);

  final LifeOsLocalAiAvailability result;
  var calls = 0;

  @override
  Future<LifeOsLocalAiAvailability> read() async {
    calls++;
    return result;
  }
}

final class _Provider implements LifeOsAiProvider {
  _Provider(this.results);

  final List<Object> results;
  final requests = <LifeOsAiRequest>[];

  @override
  Future<LifeOsAiResponse> generate(LifeOsAiRequest request) async {
    requests.add(request);
    final result = results.removeAt(0);
    if (result is Future<LifeOsAiResponse>) return result;
    if (result is LifeOsAiResponse) return result;
    throw result;
  }
}

final class _WorkspaceRepository implements LifeOsWorkspaceRepository {
  const _WorkspaceRepository(this.workspace);

  final LifeOsWorkspace workspace;

  @override
  Future<LifeOsWorkspace?> getById(LifeOsEntityId id) async =>
      workspace.id == id ? workspace : null;

  @override
  Future<List<LifeOsWorkspace>> getAll() async => [workspace];

  @override
  Future<List<LifeOsWorkspace>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async => workspace.lifecycle == lifecycle ? [workspace] : [];

  @override
  Future<void> save(LifeOsWorkspace workspace) async {}
}

final class _ContextReader implements LifeOsWorkspaceContextReader {
  const _ContextReader();

  @override
  Future<List<LifeOsWorkspaceMember>> getDirectMembers(
    LifeOsEntityId workspaceId,
  ) async => const [];

  @override
  Future<List<LifeOsWorkspaceMember>> getUnassigned() async => const [];
}
