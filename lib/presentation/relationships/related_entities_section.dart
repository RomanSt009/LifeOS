import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../domain/entities/lifeos_relationship.dart';
import '../../domain/entities/lifeos_task.dart';
import '../../l10n/app_localizations.dart';
import '../notes/note_providers.dart';
import '../tasks/task_list_providers.dart';
import 'relationship_providers.dart';

class RelatedEntitiesSection extends ConsumerStatefulWidget {
  const RelatedEntitiesSection({
    required this.entityId,
    this.maxListHeight,
    super.key,
  }) : assert(maxListHeight == null || maxListHeight > 0);

  final LifeOsEntityId entityId;
  final double? maxListHeight;

  @override
  ConsumerState<RelatedEntitiesSection> createState() =>
      _RelatedEntitiesSectionState();
}

class _RelatedEntitiesSectionState
    extends ConsumerState<RelatedEntitiesSection> {
  bool _isMutating = false;
  bool _mutationFailed = false;
  bool _endpointLoadFailed = false;

  Future<void> _add() async {
    final localizations = AppLocalizations.of(context);
    setState(() => _endpointLoadFailed = false);
    late final List<Object> results;
    try {
      results = await Future.wait<Object>([
        ref.read(getLifeOsTasksProvider)(),
        ref.read(getLifeOsNotesProvider)(),
      ]);
    } catch (_) {
      if (mounted) setState(() => _endpointLoadFailed = true);
      return;
    }
    if (!mounted) return;
    final choices = <_EndpointChoice>[
      for (final task in results[0] as List<LifeOsTask>)
        if (task.id != widget.entityId)
          _EndpointChoice(
            task.id,
            localizations.relationshipTaskLabel(task.title),
            Icons.task_alt_outlined,
          ),
      for (final note in results[1] as List<LifeOsNote>)
        if (note.id != widget.entityId)
          _EndpointChoice(
            note.id,
            localizations.relationshipNoteLabel(
              note.title.isEmpty ? localizations.noteUntitled : note.title,
            ),
            Icons.notes_outlined,
          ),
    ];
    final selected = await showDialog<LifeOsEntityId>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(localizations.relationshipPickerTitle),
        children: choices.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(localizations.relationshipPickerEmpty),
                ),
              ]
            : [
                for (final choice in choices)
                  SimpleDialogOption(
                    key: ValueKey('relationship-choice-${choice.id.value}'),
                    onPressed: () => Navigator.pop(context, choice.id),
                    child: Row(
                      children: [
                        Icon(choice.icon),
                        const SizedBox(width: 12),
                        Expanded(child: Text(choice.label)),
                      ],
                    ),
                  ),
              ],
      ),
    );
    if (selected == null || !mounted) return;
    await _mutate(
      () =>
          ref.read(createLifeOsRelationshipProvider)(widget.entityId, selected),
    );
  }

  Future<void> _confirmUnlink(LifeOsRelationship relationship) async {
    final removed = await showDialog<bool>(
      context: context,
      builder: (context) => _RelationshipUnlinkDialog(
        onUnlink: () =>
            ref.read(unlinkLifeOsRelationshipProvider)(relationship.id),
      ),
    );
    if (mounted && removed == true) {
      ref.invalidate(relationshipsForEntityProvider(widget.entityId));
      setState(() => _mutationFailed = false);
    }
  }

  Future<void> _mutate(Future<Object?> Function() operation) async {
    setState(() {
      _isMutating = true;
      _mutationFailed = false;
    });
    try {
      await operation();
      final _ = await ref.refresh(
        relationshipsForEntityProvider(widget.entityId).future,
      );
    } catch (_) {
      if (mounted) setState(() => _mutationFailed = true);
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final relationships = ref.watch(
      relationshipsForEntityProvider(widget.entityId),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localizations.relationshipSectionTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                key: ValueKey('add-relationship-${widget.entityId.value}'),
                tooltip: localizations.relationshipAddAction,
                onPressed: _isMutating ? null : _add,
                icon: Icon(
                  Icons.add_link,
                  semanticLabel: localizations.relationshipAddAction,
                ),
              ),
            ],
          ),
          relationships.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizations.relationshipLoadError),
                TextButton.icon(
                  key: ValueKey('retry-relationships-${widget.entityId.value}'),
                  onPressed: () => ref.invalidate(
                    relationshipsForEntityProvider(widget.entityId),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: Text(localizations.retryAction),
                ),
              ],
            ),
            data: (items) => items.isEmpty
                ? Text(localizations.relationshipEmpty)
                : _relationshipList(items),
          ),
          if (_endpointLoadFailed)
            Row(
              children: [
                Expanded(
                  child: Text(localizations.relationshipEndpointChoicesError),
                ),
                TextButton(
                  key: ValueKey(
                    'retry-relationship-choices-${widget.entityId.value}',
                  ),
                  onPressed: _add,
                  child: Text(localizations.retryAction),
                ),
              ],
            ),
          if (_mutationFailed) Text(localizations.relationshipSaveError),
        ],
      ),
    );
  }

  Widget _relationshipList(List<LifeOsRelationship> items) {
    final children = [
      for (final relationship in items)
        _RelatedEntityTile(
          currentId: widget.entityId,
          relationship: relationship,
          onUnlink: _isMutating ? null : () => _confirmUnlink(relationship),
        ),
    ];
    final maxListHeight = widget.maxListHeight;
    if (maxListHeight == null) {
      return Column(children: children);
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxListHeight),
      child: ListView(
        key: ValueKey('relationship-list-${widget.entityId.value}'),
        primary: false,
        shrinkWrap: true,
        children: children,
      ),
    );
  }
}

class _RelatedEntityTile extends ConsumerStatefulWidget {
  const _RelatedEntityTile({
    required this.currentId,
    required this.relationship,
    required this.onUnlink,
  });

  final LifeOsEntityId currentId;
  final LifeOsRelationship relationship;
  final VoidCallback? onUnlink;

  @override
  ConsumerState<_RelatedEntityTile> createState() => _RelatedEntityTileState();
}

class _RelatedEntityTileState extends ConsumerState<_RelatedEntityTile> {
  Future<String>? _labelFuture;

  LifeOsEntityId get _endpoint =>
      widget.relationship.firstEntityId == widget.currentId
      ? widget.relationship.secondEntityId
      : widget.relationship.firstEntityId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _labelFuture ??= _loadLabel();
  }

  @override
  void didUpdateWidget(covariant _RelatedEntityTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.relationship != widget.relationship ||
        oldWidget.currentId != widget.currentId) {
      _labelFuture = _loadLabel();
    }
  }

  void _retryLabel() {
    final future = _loadLabel();
    setState(() {
      _labelFuture = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    final endpoint = _endpoint;
    final localizations = AppLocalizations.of(context);
    return FutureBuilder<String>(
      future: _labelFuture,
      builder: (context, snapshot) => ListTile(
        dense: true,
        leading: Icon(
          endpoint.entityType == LifeOsEntityType.task
              ? Icons.task_alt_outlined
              : Icons.notes_outlined,
        ),
        title: snapshot.hasError
            ? Row(
                children: [
                  Expanded(
                    child: Text(localizations.relationshipEndpointError),
                  ),
                  TextButton(
                    key: ValueKey(
                      'retry-relationship-endpoint-${widget.relationship.id.value}',
                    ),
                    onPressed: _retryLabel,
                    child: Text(localizations.retryAction),
                  ),
                ],
              )
            : Text(snapshot.data ?? localizations.relationshipLoading),
        trailing: IconButton(
          key: ValueKey('unlink-relationship-${widget.relationship.id.value}'),
          tooltip: localizations.relationshipUnlinkAction,
          onPressed: widget.onUnlink,
          icon: const Icon(Icons.link_off),
        ),
      ),
    );
  }

  Future<String> _loadLabel() =>
      _label(ref, _endpoint, AppLocalizations.of(context));

  Future<String> _label(
    WidgetRef ref,
    LifeOsEntityId endpoint,
    AppLocalizations localizations,
  ) async {
    switch (endpoint.entityType) {
      case LifeOsEntityType.task:
        final tasks = await ref.read(getLifeOsTasksProvider)();
        final task = tasks.where((item) => item.id == endpoint).firstOrNull;
        return task == null
            ? localizations.relationshipUnavailable
            : localizations.relationshipTaskLabel(task.title);
      case LifeOsEntityType.note:
        final notes = await ref.read(getLifeOsNotesProvider)();
        final note = notes.where((item) => item.id == endpoint).firstOrNull;
        return note == null
            ? localizations.relationshipUnavailable
            : localizations.relationshipNoteLabel(
                note.title.isEmpty ? localizations.noteUntitled : note.title,
              );
      case LifeOsEntityType.relationship:
        return localizations.relationshipUnavailable;
    }
  }
}

class _RelationshipUnlinkDialog extends StatefulWidget {
  const _RelationshipUnlinkDialog({required this.onUnlink});

  final Future<void> Function() onUnlink;

  @override
  State<_RelationshipUnlinkDialog> createState() =>
      _RelationshipUnlinkDialogState();
}

class _RelationshipUnlinkDialogState extends State<_RelationshipUnlinkDialog> {
  bool _isUnlinking = false;
  bool _failed = false;

  Future<void> _unlink() async {
    if (_isUnlinking) return;
    setState(() {
      _isUnlinking = true;
      _failed = false;
    });
    try {
      await widget.onUnlink();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isUnlinking = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PopScope(
      canPop: !_isUnlinking,
      child: AlertDialog(
        title: Text(localizations.relationshipUnlinkDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.relationshipUnlinkDialogMessage),
            if (_failed) ...[
              const SizedBox(height: 8),
              Text(
                localizations.relationshipSaveError,
                key: const Key('relationship-unlink-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            key: const Key('cancel-relationship-unlink'),
            onPressed: _isUnlinking
                ? null
                : () => Navigator.of(context).pop(false),
            child: Text(localizations.cancelAction),
          ),
          FilledButton(
            key: const Key('confirm-relationship-unlink'),
            onPressed: _isUnlinking ? null : _unlink,
            child: _isUnlinking
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(localizations.relationshipUnlinkAction),
          ),
        ],
      ),
    );
  }
}

final class _EndpointChoice {
  const _EndpointChoice(this.id, this.label, this.icon);

  final LifeOsEntityId id;
  final String label;
  final IconData icon;
}
