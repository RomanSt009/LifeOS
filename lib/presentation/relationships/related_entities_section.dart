import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/relationships/lifeos_related_entity_reader.dart';
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
    this.onOpenTask,
    this.onOpenNote,
    super.key,
  }) : assert(maxListHeight == null || maxListHeight > 0);

  final LifeOsEntityId entityId;
  final double? maxListHeight;
  final ValueChanged<LifeOsEntityId>? onOpenTask;
  final ValueChanged<LifeOsEntityId>? onOpenNote;

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
      ref.invalidate(directLifeOsRelatedNeighborsProvider(widget.entityId));
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
        directLifeOsRelatedNeighborsProvider(widget.entityId).future,
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
    final neighbors = ref.watch(
      directLifeOsRelatedNeighborsProvider(widget.entityId),
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
          neighbors.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizations.relationshipLoadError),
                TextButton.icon(
                  key: ValueKey('retry-relationships-${widget.entityId.value}'),
                  onPressed: () => ref.invalidate(
                    directLifeOsRelatedNeighborsProvider(widget.entityId),
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

  Widget _relationshipList(List<LifeOsRelatedNeighbor> items) {
    final children = [
      for (final neighbor in items)
        _RelatedEntityTile(
          neighbor: neighbor,
          onOpen: switch (neighbor) {
            LifeOsRelatedTaskNeighbor() =>
              widget.onOpenTask == null
                  ? null
                  : () => widget.onOpenTask!(neighbor.entityId),
            LifeOsRelatedNoteNeighbor() =>
              widget.onOpenNote == null
                  ? null
                  : () => widget.onOpenNote!(neighbor.entityId),
          },
          onUnlink: _isMutating
              ? null
              : () => _confirmUnlink(neighbor.relationship),
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

class _RelatedEntityTile extends StatelessWidget {
  const _RelatedEntityTile({
    required this.neighbor,
    required this.onOpen,
    required this.onUnlink,
  });

  final LifeOsRelatedNeighbor neighbor;
  final VoidCallback? onOpen;
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final (label, semanticsLabel, icon) = switch (neighbor) {
      LifeOsRelatedTaskNeighbor(:final task) => (
        localizations.relationshipTaskLabel(task.title),
        localizations.relationshipOpenTaskAction(task.title),
        task.isCompleted ? Icons.check_circle : Icons.task_alt_outlined,
      ),
      LifeOsRelatedNoteNeighbor(:final note) => (
        localizations.relationshipNoteLabel(
          note.title.isEmpty ? localizations.noteUntitled : note.title,
        ),
        localizations.relationshipOpenNoteAction(
          note.title.isEmpty ? localizations.noteUntitled : note.title,
        ),
        Icons.notes_outlined,
      ),
    };
    return ListTile(
      key: ValueKey('open-related-${neighbor.relationship.id.value}'),
      dense: true,
      onTap: onOpen,
      leading: Icon(icon),
      title: Semantics(
        button: onOpen != null,
        label: semanticsLabel,
        excludeSemantics: true,
        child: Text(label),
      ),
      trailing: IconButton(
        key: ValueKey('unlink-relationship-${neighbor.relationship.id.value}'),
        tooltip: localizations.relationshipUnlinkAction,
        onPressed: onUnlink,
        icon: Icon(
          Icons.link_off,
          semanticLabel: localizations.relationshipUnlinkAction,
        ),
      ),
    );
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
