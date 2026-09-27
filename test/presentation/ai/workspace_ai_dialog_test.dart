import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('ignores a late error after dialog disposal', (tester) async {
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
    pending.completeError(
      const LifeOsAiProviderException(LifeOsAiProviderError.network),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Ctrl+Enter sends once and cannot duplicate a pending request', (
    tester,
  ) async {
    final pending = Completer<LifeOsAiResponse>();
    final harness = _Harness(providerResults: [pending.future]);
    await _pump(tester, harness);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workspace-ai-question-field')),
      'Keyboard question',
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(harness.provider.requests, hasLength(1));

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(harness.provider.requests, hasLength(1));

    pending.complete(LifeOsAiResponse(text: 'Keyboard answer'));
    await tester.pumpAndSettle();
    expect(find.text('Keyboard answer'), findsOneWidget);
  });

  testWidgets('closing resets state and isolates another Workspace', (
    tester,
  ) async {
    final first = _Harness(
      workspaceId: 'workspace-a',
      providerResults: [LifeOsAiResponse(text: 'Answer A')],
    );
    await _pump(tester, first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workspace-ai-question-field')),
      'Question A',
    );
    await tester.tap(find.byKey(const Key('workspace-ai-send')));
    await tester.pumpAndSettle();
    expect(find.text('Answer A'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    final second = _Harness(
      workspaceId: 'workspace-b',
      providerResults: [LifeOsAiResponse(text: 'Answer B')],
    );
    await _pump(tester, second);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('workspace-ai-question-field')),
    );
    expect(field.controller!.text, isEmpty);
    expect(find.text('Answer A'), findsNothing);
    expect(second.provider.requests, isEmpty);

    await tester.enterText(
      find.byKey(const Key('workspace-ai-question-field')),
      'Question B',
    );
    await tester.tap(find.byKey(const Key('workspace-ai-send')));
    await tester.pumpAndSettle();
    expect(find.text('Answer B'), findsOneWidget);
    expect(
      second.provider.requests.single.context.rootWorkspace.workspaceId.value,
      'workspace-b',
    );
  });

  testWidgets('remains scrollable with enlarged text on narrow desktop', (
    tester,
  ) async {
    final harness = _Harness(
      providerResults: [LifeOsAiResponse(text: 'Long response ' * 800)],
    );
    await _pump(
      tester,
      harness,
      size: const Size(640, 600),
      textScaler: const TextScaler.linear(1.5),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('workspace-ai-question-field')),
      'Long question\n' * 20,
    );
    await tester.tap(find.byKey(const Key('workspace-ai-send')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.byKey(const Key('workspace-ai-response')), findsOneWidget);
  });
  testWidgets('maps every provider-neutral error without raw details', (
    tester,
  ) async {
    for (final error in LifeOsAiProviderError.values) {
      final harness = _Harness(
        providerResults: [LifeOsAiProviderException(error)],
      );
      await _pump(tester, harness);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('workspace-ai-question-field')),
        'Question',
      );
      await tester.tap(find.byKey(const Key('workspace-ai-send')));
      await tester.pumpAndSettle();

      if (error == LifeOsAiProviderError.unavailable) {
        expect(
          find.byKey(const Key('workspace-ai-runtime-unavailable')),
          findsOneWidget,
        );
      } else if (error == LifeOsAiProviderError.invalidConfiguration) {
        expect(
          find.byKey(const Key('workspace-ai-model-missing')),
          findsOneWidget,
        );
      } else {
        expect(find.byKey(const Key('workspace-ai-error')), findsOneWidget);
      }
      expect(find.textContaining('private'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('exposes labeled keyboard-accessible dialog controls', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _Harness());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Question'), findsOneWidget);
    expect(find.bySemanticsLabel('Send'), findsOneWidget);
    expect(find.bySemanticsLabel('Clear'), findsOneWidget);
    expect(find.bySemanticsLabel('Cancel'), findsOneWidget);
    expect(find.text('Local model qwen2.5-coder:7b is ready.'), findsOneWidget);
    semantics.dispose();
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
  Size size = const Size(1280, 800),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
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
    String workspaceId = 'workspace-1',
  }) : workspace = LifeOsWorkspace(
         id: LifeOsEntityId(
           value: workspaceId,
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
