import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai/lifeos_ai_provider.dart';
import '../../application/ai/lifeos_local_ai_availability.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../l10n/app_localizations.dart';
import 'local_ai_providers.dart';

enum _WorkspaceAiAvailability {
  checking,
  ready,
  runtimeUnavailable,
  modelMissing,
  error,
}

enum _WorkspaceAiRequestPhase { idle, sending, response, error }

class WorkspaceAiDialog extends ConsumerStatefulWidget {
  const WorkspaceAiDialog({required this.workspaceId, super.key});

  final LifeOsEntityId workspaceId;

  @override
  ConsumerState<WorkspaceAiDialog> createState() => _WorkspaceAiDialogState();
}

class _WorkspaceAiDialogState extends ConsumerState<WorkspaceAiDialog> {
  final _questionController = TextEditingController();
  _WorkspaceAiAvailability _availability = _WorkspaceAiAvailability.checking;
  _WorkspaceAiRequestPhase _requestPhase = _WorkspaceAiRequestPhase.idle;
  String? _response;
  bool _questionMissing = false;
  var _availabilityRequestId = 0;
  var _sendRequestId = 0;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final requestId = ++_availabilityRequestId;
    setState(() => _availability = _WorkspaceAiAvailability.checking);
    try {
      final availability = await ref.read(
        checkLifeOsLocalAiAvailabilityProvider,
      )();
      if (!mounted || requestId != _availabilityRequestId) return;
      setState(() {
        _availability = switch (availability) {
          LifeOsLocalAiAvailability.runtimeUnavailable =>
            _WorkspaceAiAvailability.runtimeUnavailable,
          LifeOsLocalAiAvailability.runtimeAvailableModelMissing =>
            _WorkspaceAiAvailability.modelMissing,
          LifeOsLocalAiAvailability.runtimeAvailableModelAvailable =>
            _WorkspaceAiAvailability.ready,
        };
      });
    } catch (_) {
      if (mounted && requestId == _availabilityRequestId) {
        setState(() => _availability = _WorkspaceAiAvailability.error);
      }
    }
  }

  Future<void> _send() async {
    if (_availability != _WorkspaceAiAvailability.ready ||
        _requestPhase == _WorkspaceAiRequestPhase.sending) {
      return;
    }
    if (_questionController.text.trim().isEmpty) {
      setState(() => _questionMissing = true);
      return;
    }

    final requestId = ++_sendRequestId;
    setState(() {
      _questionMissing = false;
      _requestPhase = _WorkspaceAiRequestPhase.sending;
      _response = null;
    });
    try {
      final response = await ref.read(askAboutLifeOsWorkspaceProvider)(
        workspaceId: widget.workspaceId,
        question: _questionController.text,
      );
      if (!mounted || requestId != _sendRequestId) return;
      setState(() {
        _response = response.text;
        _requestPhase = _WorkspaceAiRequestPhase.response;
      });
    } on LifeOsAiProviderException catch (error) {
      if (!mounted || requestId != _sendRequestId) return;
      setState(() {
        if (error.error == LifeOsAiProviderError.unavailable) {
          _availability = _WorkspaceAiAvailability.runtimeUnavailable;
          _requestPhase = _WorkspaceAiRequestPhase.idle;
        } else if (error.error == LifeOsAiProviderError.invalidConfiguration) {
          _availability = _WorkspaceAiAvailability.modelMissing;
          _requestPhase = _WorkspaceAiRequestPhase.idle;
        } else {
          _requestPhase = _WorkspaceAiRequestPhase.error;
        }
      });
    } catch (_) {
      if (mounted && requestId == _sendRequestId) {
        setState(() => _requestPhase = _WorkspaceAiRequestPhase.error);
      }
    }
  }

  void _clear() {
    _sendRequestId++;
    _questionController.clear();
    setState(() {
      _questionMissing = false;
      _response = null;
      _requestPhase = _WorkspaceAiRequestPhase.idle;
    });
  }

  @override
  void dispose() {
    _availabilityRequestId++;
    _sendRequestId++;
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final model = ref.watch(lifeOsLocalAiModelNameProvider);
    final ready = _availability == _WorkspaceAiAvailability.ready;
    final sending = _requestPhase == _WorkspaceAiRequestPhase.sending;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _send,
      },
      child: AlertDialog(
        title: Text(localizations.workspaceAiDialogTitle),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  localizations.localAiProcessingNotice,
                  key: const Key('workspace-ai-local-notice'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                _availabilityContent(localizations, model),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('workspace-ai-question-field'),
                  controller: _questionController,
                  autofocus: true,
                  enabled: ready && !sending,
                  minLines: 3,
                  maxLines: 7,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    labelText: localizations.workspaceAiQuestionLabel,
                    errorText: _questionMissing
                        ? localizations.workspaceAiQuestionRequired
                        : null,
                  ),
                ),
                if (sending) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(
                    key: Key('workspace-ai-progress'),
                  ),
                ],
                if (_requestPhase == _WorkspaceAiRequestPhase.error) ...[
                  const SizedBox(height: 12),
                  Text(
                    localizations.workspaceAiRequestError,
                    key: const Key('workspace-ai-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('workspace-ai-retry'),
                      onPressed: _send,
                      icon: const Icon(Icons.refresh),
                      label: Text(localizations.retryAction),
                    ),
                  ),
                ],
                if (_response case final response?) ...[
                  const SizedBox(height: 16),
                  Text(
                    localizations.workspaceAiResponseLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    response,
                    key: const Key('workspace-ai-response'),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            key: const Key('workspace-ai-clear'),
            onPressed: sending ? null : _clear,
            child: Text(localizations.workspaceAiClearAction),
          ),
          TextButton(
            key: const Key('workspace-ai-close'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.cancelAction),
          ),
          FilledButton.icon(
            key: const Key('workspace-ai-send'),
            onPressed: ready && !sending ? _send : null,
            icon: const Icon(Icons.send_outlined),
            label: Text(localizations.workspaceAiSendAction),
          ),
        ],
      ),
    );
  }

  Widget _availabilityContent(AppLocalizations localizations, String model) {
    return switch (_availability) {
      _WorkspaceAiAvailability.checking => Row(
        key: const Key('workspace-ai-checking'),
        children: [
          const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(localizations.workspaceAiChecking)),
        ],
      ),
      _WorkspaceAiAvailability.ready => Text(
        localizations.workspaceAiReady(model),
        key: const Key('workspace-ai-ready'),
      ),
      _WorkspaceAiAvailability.runtimeUnavailable => _UnavailableContent(
        key: const Key('workspace-ai-runtime-unavailable'),
        message: localizations.workspaceAiRuntimeUnavailable,
        instruction: localizations.localAiRuntimeSetupInstruction,
        onRefresh: _checkAvailability,
      ),
      _WorkspaceAiAvailability.modelMissing => _UnavailableContent(
        key: const Key('workspace-ai-model-missing'),
        message: localizations.workspaceAiModelMissing(model),
        instruction: localizations.localAiModelSetupInstruction(model),
        onRefresh: _checkAvailability,
      ),
      _WorkspaceAiAvailability.error => _UnavailableContent(
        key: const Key('workspace-ai-availability-error'),
        message: localizations.localAiStatusError,
        instruction: null,
        onRefresh: _checkAvailability,
      ),
    };
  }
}

class _UnavailableContent extends StatelessWidget {
  const _UnavailableContent({
    required this.message,
    required this.instruction,
    required this.onRefresh,
    super.key,
  });

  final String message;
  final String? instruction;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message),
        if (instruction case final instruction?) ...[
          const SizedBox(height: 6),
          Text(instruction),
        ],
        const SizedBox(height: 6),
        TextButton.icon(
          key: const Key('workspace-ai-refresh'),
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: Text(localizations.localAiRefreshAction),
        ),
      ],
    );
  }
}
