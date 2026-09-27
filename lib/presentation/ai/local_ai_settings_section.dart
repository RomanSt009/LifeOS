import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/lifeos_local_ai_availability.dart';
import '../../l10n/app_localizations.dart';
import 'local_ai_providers.dart';

enum _LocalAiSettingsPhase {
  notChecked,
  checking,
  ready,
  runtimeUnavailable,
  modelMissing,
  error,
}

class LocalAiSettingsSection extends ConsumerStatefulWidget {
  const LocalAiSettingsSection({super.key});

  @override
  ConsumerState<LocalAiSettingsSection> createState() =>
      _LocalAiSettingsSectionState();
}

class _LocalAiSettingsSectionState
    extends ConsumerState<LocalAiSettingsSection> {
  _LocalAiSettingsPhase _phase = _LocalAiSettingsPhase.notChecked;
  var _requestId = 0;

  Future<void> _refresh() async {
    if (_phase == _LocalAiSettingsPhase.checking) return;
    final requestId = ++_requestId;
    setState(() => _phase = _LocalAiSettingsPhase.checking);
    try {
      final availability = await ref.read(
        checkLifeOsLocalAiAvailabilityProvider,
      )();
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _phase = switch (availability) {
          LifeOsLocalAiAvailability.runtimeUnavailable =>
            _LocalAiSettingsPhase.runtimeUnavailable,
          LifeOsLocalAiAvailability.runtimeAvailableModelMissing =>
            _LocalAiSettingsPhase.modelMissing,
          LifeOsLocalAiAvailability.runtimeAvailableModelAvailable =>
            _LocalAiSettingsPhase.ready,
        };
      });
    } catch (_) {
      if (mounted && requestId == _requestId) {
        setState(() => _phase = _LocalAiSettingsPhase.error);
      }
    }
  }

  @override
  void dispose() {
    _requestId++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final model = ref.watch(lifeOsLocalAiModelNameProvider);
    final (status, icon, color) = switch (_phase) {
      _LocalAiSettingsPhase.notChecked => (
        localizations.localAiStatusNotChecked,
        Icons.help_outline,
        null,
      ),
      _LocalAiSettingsPhase.checking => (
        localizations.localAiStatusChecking,
        Icons.sync,
        null,
      ),
      _LocalAiSettingsPhase.ready => (
        localizations.localAiStatusReady,
        Icons.check_circle_outline,
        Theme.of(context).colorScheme.primary,
      ),
      _LocalAiSettingsPhase.runtimeUnavailable => (
        localizations.localAiStatusRuntimeUnavailable,
        Icons.error_outline,
        Theme.of(context).colorScheme.error,
      ),
      _LocalAiSettingsPhase.modelMissing => (
        localizations.localAiStatusModelMissing,
        Icons.warning_amber_outlined,
        Theme.of(context).colorScheme.error,
      ),
      _LocalAiSettingsPhase.error => (
        localizations.localAiStatusError,
        Icons.error_outline,
        Theme.of(context).colorScheme.error,
      ),
    };

    return Card(
      key: const Key('local-ai-settings-section'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.localAiSectionTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(localizations.localAiSectionDescription),
            const SizedBox(height: 12),
            Text(localizations.localAiRequiredModel(model)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_phase == _LocalAiSettingsPhase.checking)
                  const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(status, key: const Key('local-ai-status')),
                ),
                OutlinedButton.icon(
                  key: const Key('refresh-local-ai-status'),
                  onPressed: _phase == _LocalAiSettingsPhase.checking
                      ? null
                      : _refresh,
                  icon: const Icon(Icons.refresh),
                  label: Text(localizations.localAiRefreshAction),
                ),
              ],
            ),
            if (_phase == _LocalAiSettingsPhase.runtimeUnavailable) ...[
              const SizedBox(height: 12),
              Text(localizations.localAiRuntimeSetupInstruction),
            ],
            if (_phase == _LocalAiSettingsPhase.modelMissing) ...[
              const SizedBox(height: 12),
              Text(localizations.localAiModelSetupInstruction(model)),
            ],
            const SizedBox(height: 12),
            Text(
              localizations.localAiProcessingNotice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
