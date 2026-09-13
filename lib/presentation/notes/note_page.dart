import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../l10n/app_localizations.dart';
import '../relationships/related_entities_section.dart';
import '../settings/backup_settings_providers.dart';
import 'note_providers.dart';

class NotePage extends ConsumerStatefulWidget {
  const NotePage({super.key});

  @override
  ConsumerState<NotePage> createState() => _NotePageState();
}

class _NotePageState extends ConsumerState<NotePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  LifeOsEntityId? _selectedId;
  String _savedTitle = '';
  String _savedContent = '';
  bool _isSaving = false;
  bool _showTrash = false;
  bool _isLifecycleMutating = false;
  bool _lifecycleFailed = false;
  _NoteEditorError? _error;

  bool get _isDirty =>
      _titleController.text != _savedTitle ||
      _contentController.text != _savedContent;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_draftChanged);
    _contentController.addListener(_draftChanged);
  }

  void _draftChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_draftChanged);
    _contentController.removeListener(_draftChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _startNew() {
    setState(() {
      _selectedId = null;
      _savedTitle = '';
      _savedContent = '';
      _titleController.clear();
      _contentController.clear();
      _error = null;
    });
  }

  void _select(LifeOsNote note) {
    setState(() {
      _selectedId = note.id;
      _savedTitle = note.title;
      _savedContent = note.content;
      _titleController.text = note.title;
      _contentController.text = note.content;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      setState(() => _error = _NoteEditorError.contentRequired);
      return;
    }
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final controller = ref.read(noteListControllerProvider.notifier);
      final LifeOsNote? saved;
      if (_selectedId case final id?) {
        saved = await controller.edit(
          id,
          title: _titleController.text,
          content: _contentController.text,
        );
      } else {
        saved = await controller.create(
          title: _titleController.text,
          content: _contentController.text,
        );
      }
      if (saved == null) {
        throw StateError('The selected Note no longer exists.');
      }
      if (mounted) {
        _select(saved);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = _NoteEditorError.saveFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(backupRestoreRevisionProvider, (_, _) => _startNew());
    final localizations = AppLocalizations.of(context);
    final notes = ref.watch(
      _showTrash ? noteTrashControllerProvider : noteListControllerProvider,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(localizations.noteLoadError)),
        data: (items) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _showTrash
                        ? localizations.noteTrashTitle
                        : localizations.noteListTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (!_showTrash)
                        Expanded(
                          child: FilledButton.icon(
                            key: const Key('new-note-button'),
                            onPressed: _startNew,
                            icon: const Icon(Icons.note_add_outlined),
                            label: Text(localizations.noteCreateAction),
                          ),
                        ),
                      if (!_showTrash) const SizedBox(width: 8),
                      Tooltip(
                        message: _isDirty
                            ? localizations.saveNoteBeforeTrash
                            : '',
                        child: TextButton.icon(
                          key: const Key('note-trash-toggle'),
                          onPressed: _isDirty || _isLifecycleMutating
                              ? null
                              : _toggleTrash,
                          icon: Icon(
                            _showTrash
                                ? Icons.arrow_back
                                : Icons.delete_outline,
                          ),
                          label: Text(
                            _showTrash
                                ? localizations.backToNotesAction
                                : localizations.trashAction,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_lifecycleFailed)
                    Text(
                      localizations.noteRestoreError,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (items.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          _showTrash
                              ? localizations.noteTrashEmpty
                              : localizations.noteListEmpty,
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final note = items[index];
                          return ListTile(
                            key: ValueKey(
                              '${_showTrash ? 'deleted-' : ''}note-${note.id.value}',
                            ),
                            selected: note.id == _selectedId,
                            title: Text(
                              note.title.isEmpty
                                  ? localizations.noteUntitled
                                  : note.title,
                            ),
                            trailing: _showTrash
                                ? IconButton(
                                    key: ValueKey(
                                      'restore-note-${note.id.value}',
                                    ),
                                    tooltip: localizations.restoreNoteAction,
                                    onPressed: _isLifecycleMutating
                                        ? null
                                        : () => _restoreNote(note),
                                    icon: const Icon(Icons.restore),
                                  )
                                : null,
                            onTap: _showTrash ? null : () => _select(note),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 32),
            Expanded(
              child: _showTrash
                  ? Center(child: Text(localizations.noteTrashDescription))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          key: const Key('note-title-field'),
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: localizations.noteTitleFieldLabel,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TextField(
                            key: const Key('note-content-field'),
                            controller: _contentController,
                            expands: true,
                            maxLines: null,
                            minLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              labelText: localizations.noteContentFieldLabel,
                              alignLabelWithHint: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        if (_selectedId case final selectedId?) ...[
                          const SizedBox(height: 8),
                          RelatedEntitiesSection(entityId: selectedId),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error == _NoteEditorError.contentRequired
                                ? localizations.noteContentRequired
                                : localizations.noteSaveError,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_selectedId != null)
                              Tooltip(
                                message: _isDirty
                                    ? localizations.saveNoteBeforeDelete
                                    : '',
                                child: TextButton.icon(
                                  key: const Key('delete-note-button'),
                                  onPressed: _isDirty || _isSaving
                                      ? null
                                      : _confirmDeleteNote,
                                  icon: const Icon(Icons.delete_outline),
                                  label: Text(localizations.deleteNoteAction),
                                ),
                              ),
                            const SizedBox(width: 8),
                            FilledButton(
                              key: const Key('save-note-button'),
                              onPressed: _isSaving ? null : _save,
                              child: Text(localizations.noteSaveAction),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleTrash() {
    setState(() {
      _showTrash = !_showTrash;
      _selectedId = null;
      _savedTitle = '';
      _savedContent = '';
      _titleController.clear();
      _contentController.clear();
      _lifecycleFailed = false;
      _error = null;
    });
  }

  Future<void> _confirmDeleteNote() async {
    final id = _selectedId;
    if (id == null || _isDirty) return;
    final note = ref
        .read(noteListControllerProvider)
        .requireValue
        .where((item) => item.id == id)
        .firstOrNull;
    if (note == null) return;
    final deleted = await showDialog<bool>(
      context: context,
      builder: (context) => _NoteDeleteDialog(
        note: note,
        onDelete: () =>
            ref.read(noteListControllerProvider.notifier).delete(id),
      ),
    );
    if (deleted == true && mounted) _startNew();
  }

  Future<void> _restoreNote(LifeOsNote note) async {
    setState(() {
      _isLifecycleMutating = true;
      _lifecycleFailed = false;
    });
    try {
      await ref.read(noteTrashControllerProvider.notifier).restore(note.id);
    } catch (_) {
      if (mounted) setState(() => _lifecycleFailed = true);
    } finally {
      if (mounted) setState(() => _isLifecycleMutating = false);
    }
  }
}

enum _NoteEditorError { contentRequired, saveFailed }

class _NoteDeleteDialog extends StatefulWidget {
  const _NoteDeleteDialog({required this.note, required this.onDelete});

  final LifeOsNote note;
  final Future<void> Function() onDelete;

  @override
  State<_NoteDeleteDialog> createState() => _NoteDeleteDialogState();
}

class _NoteDeleteDialogState extends State<_NoteDeleteDialog> {
  bool _isDeleting = false;
  bool _failed = false;

  Future<void> _delete() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _failed = false;
    });
    try {
      await widget.onDelete();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(localizations.deleteNoteDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.moveNoteToTrashConfirmation(
              widget.note.title.isEmpty
                  ? localizations.noteUntitled
                  : widget.note.title,
            ),
          ),
          if (_failed) ...[
            const SizedBox(height: 8),
            Text(
              localizations.noteDeleteError,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: Text(localizations.cancelAction),
        ),
        FilledButton(
          key: const Key('confirm-delete-note-button'),
          onPressed: _isDeleting ? null : _delete,
          child: _isDeleting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(localizations.moveToTrashAction),
        ),
      ],
    );
  }
}
