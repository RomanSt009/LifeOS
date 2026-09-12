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
  const RelatedEntitiesSection({required this.entityId, super.key});

  final LifeOsEntityId entityId;

  @override
  ConsumerState<RelatedEntitiesSection> createState() =>
      _RelatedEntitiesSectionState();
}

class _RelatedEntitiesSectionState
    extends ConsumerState<RelatedEntitiesSection> {
  bool _isMutating = false;
  bool _mutationFailed = false;

  Future<void> _add() async {
    final localizations = AppLocalizations.of(context);
    late final List<Object> results;
    try {
      results = await Future.wait<Object>([
        ref.read(getLifeOsTasksProvider)(),
        ref.read(getLifeOsNotesProvider)(),
      ]);
    } catch (_) {
      if (mounted) setState(() => _mutationFailed = true);
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

  Future<void> _unlink(LifeOsRelationship relationship) => _mutate(
    () => ref.read(unlinkLifeOsRelationshipProvider)(relationship.id),
  );

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
              TextButton.icon(
                key: ValueKey('add-relationship-${widget.entityId.value}'),
                onPressed: _isMutating ? null : _add,
                icon: const Icon(Icons.add_link),
                label: Text(localizations.relationshipAddAction),
              ),
            ],
          ),
          relationships.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => Text(localizations.relationshipLoadError),
            data: (items) => items.isEmpty
                ? Text(localizations.relationshipEmpty)
                : Column(
                    children: [
                      for (final relationship in items)
                        _RelatedEntityTile(
                          currentId: widget.entityId,
                          relationship: relationship,
                          onUnlink: _isMutating
                              ? null
                              : () => _unlink(relationship),
                        ),
                    ],
                  ),
          ),
          if (_mutationFailed) Text(localizations.relationshipSaveError),
        ],
      ),
    );
  }
}

class _RelatedEntityTile extends ConsumerWidget {
  const _RelatedEntityTile({
    required this.currentId,
    required this.relationship,
    required this.onUnlink,
  });

  final LifeOsEntityId currentId;
  final LifeOsRelationship relationship;
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final endpoint = relationship.firstEntityId == currentId
        ? relationship.secondEntityId
        : relationship.firstEntityId;
    return FutureBuilder<String>(
      future: _label(ref, endpoint, AppLocalizations.of(context)),
      builder: (context, snapshot) => ListTile(
        dense: true,
        leading: Icon(
          endpoint.entityType == LifeOsEntityType.task
              ? Icons.task_alt_outlined
              : Icons.notes_outlined,
        ),
        title: Text(
          snapshot.data ?? AppLocalizations.of(context).relationshipLoading,
        ),
        trailing: IconButton(
          key: ValueKey('unlink-relationship-${relationship.id.value}'),
          tooltip: AppLocalizations.of(context).relationshipUnlinkAction,
          onPressed: onUnlink,
          icon: const Icon(Icons.link_off),
        ),
      ),
    );
  }

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

final class _EndpointChoice {
  const _EndpointChoice(this.id, this.label, this.icon);

  final LifeOsEntityId id;
  final String label;
  final IconData icon;
}
