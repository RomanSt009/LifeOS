import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/ai/lifeos_local_ai_availability.dart';
import 'package:lifeos/application/use_cases/check_lifeos_local_ai_availability.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/ai/local_ai_providers.dart';
import 'package:lifeos/presentation/ai/local_ai_settings_section.dart';

void main() {
  testWidgets('does not check at startup and refreshes to ready', (
    tester,
  ) async {
    final reader = _AvailabilityReader([
      LifeOsLocalAiAvailability.runtimeAvailableModelAvailable,
    ]);
    await _pump(tester, reader);

    expect(find.text('Status not checked'), findsOneWidget);
    expect(reader.calls, 0);

    await tester.tap(find.byKey(const Key('refresh-local-ai-status')));
    await tester.pumpAndSettle();

    expect(reader.calls, 1);
    expect(
      find.text('Ollama and the required model are available'),
      findsOneWidget,
    );
    expect(find.text('Required model: qwen2.5-coder:7b'), findsOneWidget);
  });

  testWidgets('distinguishes runtime and fixed-model recovery instructions', (
    tester,
  ) async {
    final reader = _AvailabilityReader([
      LifeOsLocalAiAvailability.runtimeUnavailable,
      LifeOsLocalAiAvailability.runtimeAvailableModelMissing,
    ]);
    await _pump(tester, reader);

    await tester.tap(find.byKey(const Key('refresh-local-ai-status')));
    await tester.pumpAndSettle();
    expect(find.text('Ollama is unavailable'), findsOneWidget);
    expect(
      find.text('Install and start Ollama, then refresh the status.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('refresh-local-ai-status')));
    await tester.pumpAndSettle();
    expect(
      find.text('Ollama is available, but the required model is missing'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Install the model manually with: ollama pull qwen2.5-coder:7b',
      ),
      findsOneWidget,
    );
  });

  testWidgets('recovers from a failed explicit status check', (tester) async {
    final reader = _AvailabilityReader([
      StateError('local failure'),
      LifeOsLocalAiAvailability.runtimeAvailableModelAvailable,
    ]);
    await _pump(tester, reader);

    await tester.tap(find.byKey(const Key('refresh-local-ai-status')));
    await tester.pumpAndSettle();
    expect(find.text('Unable to check local AI'), findsOneWidget);

    await tester.tap(find.byKey(const Key('refresh-local-ai-status')));
    await tester.pumpAndSettle();
    expect(
      find.text('Ollama and the required model are available'),
      findsOneWidget,
    );
  });

  testWidgets('runtime guidance remains usable on narrow desktop', (
    tester,
  ) async {
    final reader = _AvailabilityReader([
      LifeOsLocalAiAvailability.runtimeUnavailable,
    ]);
    await _pump(tester, reader, size: const Size(640, 600));
    await tester.tap(find.byKey(const Key('refresh-local-ai-status')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ollama is unavailable'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
  testWidgets('localizes Local AI settings in Russian', (tester) async {
    await _pump(
      tester,
      _AvailabilityReader(const []),
      locale: const Locale('ru'),
    );

    expect(find.text('Локальный ИИ'), findsOneWidget);
    expect(find.text('Требуемая модель: qwen2.5-coder:7b'), findsOneWidget);
    expect(find.text('Статус не проверен'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester,
  _AvailabilityReader reader, {
  Locale locale = const Locale('en'),
  Size size = const Size(1280, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        checkLifeOsLocalAiAvailabilityProvider.overrideWithValue(
          CheckLifeOsLocalAiAvailability(reader),
        ),
        lifeOsLocalAiModelNameProvider.overrideWithValue('qwen2.5-coder:7b'),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: LocalAiSettingsSection()),
        ),
      ),
    ),
  );
}

final class _AvailabilityReader implements LifeOsLocalAiAvailabilityReader {
  _AvailabilityReader(this.results);

  final List<Object> results;
  var calls = 0;

  @override
  Future<LifeOsLocalAiAvailability> read() async {
    final result = results[calls++];
    if (result is LifeOsLocalAiAvailability) return result;
    throw result;
  }
}
