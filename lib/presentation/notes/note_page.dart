import 'package:flutter/services.dart';
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
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  _PersistedNoteDraft _persistedDraft = const _PersistedNoteDraft.empty();
  bool _isSaving = false;
  bool _showTrash = false;
  bool _isLifecycleMutating = false;
  bool _lifecycleFailed = false;
  bool _isReplacingDraft = false;
  bool _showSavedFeedback = false;
  _NoteEditorError? _error;

  LifeOsEntityId? get _selectedId => _persistedDraft.id;

  bool get _isDirty =>
      _titleController.text.trim() != _persistedDraft.title ||
      _contentController.text != _persistedDraft.content;

  @override
  void initState() {
    super.initState();
    _titleFocusNode.onKeyEvent = _handleEditorKeyEvent;
    _contentFocusNode.onKeyEvent = _handleEditorKeyEvent;
    _titleController.addListener(_draftChanged);
    _contentController.addListener(_draftChanged);
  }

  KeyEventResult _handleEditorKeyEvent(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyS &&
        HardwareKeyboard.instance.isControlPressed) {
      if (!_showTrash) _save();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _draftChanged() {
    if (!mounted || _isReplacingDraft) return;
    setState(() {
      _showSavedFeedback = false;
      _error = null;
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_draftChanged);
    _contentController.removeListener(_draftChanged);
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _replaceDraft({required String title, required String content}) {
    _isReplacingDraft = true;
    _titleController.text = title;
    _contentController.text = content;
    _isReplacingDraft = false;
  }

  void _startNew({bool requestFocus = true}) {
    setState(() {
      _persistedDraft = const _PersistedNoteDraft.empty();
      _replaceDraft(title: '', content: '');
      _error = null;
      _showSavedFeedback = false;
    });
    if (requestFocus) _requestFocus(_titleFocusNode);
  }

  void _select(
    LifeOsNote note, {
    bool requestFocus = true,
    bool showSavedFeedback = false,
  }) {
    setState(() {
      _persistedDraft = _PersistedNoteDraft.fromNote(note);
      _replaceDraft(title: note.title, content: note.content);
      _error = null;
      _showSavedFeedback = showSavedFeedback;
    });
    if (requestFocus) _requestFocus(_contentFocusNode);
  }

  void _requestFocus(FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focusNode.requestFocus();
    });
  }

  Future<_NoteSaveResult> _save() async {
    if (_isSaving) return _NoteSaveResult.inProgress;
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      setState(() => _error = _NoteEditorError.contentRequired);
      return _NoteSaveResult.invalid;
    }
    if (_selectedId != null && !_isDirty) {
      setState(() {
        _error = null;
        _showSavedFeedback = true;
      });
      return _NoteSaveResult.saved;
    }
    setState(() {
      _isSaving = true;
      _error = null;
      _showSavedFeedback = false;
    });
    final submittedId = _selectedId;
    final submittedTitle = _titleController.text;
    final submittedContent = _contentController.text;

    try {
      final controller = ref.read(noteListControllerProvider.notifier);
      final LifeOsNote? saved;
      if (submittedId case final id?) {
        saved = await controller.edit(
          id,
          title: submittedTitle,
          content: submittedContent,
        );
      } else {
        saved = await controller.create(
          title: submittedTitle,
          content: submittedContent,
        );
      }
      if (saved == null) {
        throw StateError('The selected Note no longer exists.');
      }
      if (mounted) {
        _acceptSavedNote(
          saved,
          submittedId: submittedId,
          submittedTitle: submittedTitle,
          submittedContent: submittedContent,
        );
      }
      return _NoteSaveResult.saved;
    } catch (_) {
      if (mounted) {
        setState(() => _error = _NoteEditorError.saveFailed);
      }
      return _NoteSaveResult.failed;
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _acceptSavedNote(
    LifeOsNote saved, {
    required LifeOsEntityId? submittedId,
    required String submittedTitle,
    required String submittedContent,
  }) {
    if (_selectedId != submittedId) return;
    final draftWasUnchanged =
        _titleController.text == submittedTitle &&
        _contentController.text == submittedContent;
    if (draftWasUnchanged) {
      _select(saved, requestFocus: false, showSavedFeedback: true);
      return;
    }
    setState(() {
      _persistedDraft = _PersistedNoteDraft.fromNote(saved);
      _error = null;
      _showSavedFeedback = false;
    });
  }

  Future<bool> _resolveDirtyDraft() async {
    if (!_isDirty) return true;
    final decision = await showDialog<_UnsavedNoteDecision>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UnsavedNoteDialog(onSave: _save),
    );
    if (!mounted) return false;
    switch (decision) {
      case _UnsavedNoteDecision.saved:
        return true;
      case _UnsavedNoteDecision.discarded:
        _discardDraft();
        return true;
      case _UnsavedNoteDecision.cancelled:
      case null:
        return false;
    }
  }

  void _discardDraft() {
    setState(() {
      _replaceDraft(
        title: _persistedDraft.title,
        content: _persistedDraft.content,
      );
      _error = null;
      _showSavedFeedback = false;
    });
  }

  Future<void> _startNewSafely() async {
    if (!await _resolveDirtyDraft()) return;
    _startNew();
  }

  Future<void> _selectSafely(LifeOsEntityId targetId) async {
    if (targetId == _selectedId) return;
    if (!await _resolveDirtyDraft() || !mounted) return;
    final target = ref
        .read(noteListControllerProvider)
        .requireValue
        .where((note) => note.id == targetId)
        .firstOrNull;
    if (target != null) _select(target);
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
                            onPressed: _isSaving || _isLifecycleMutating
                                ? null
                                : _startNewSafely,
                            icon: const Icon(Icons.note_add_outlined),
                            label: Text(localizations.noteCreateAction),
                          ),
                        ),
                      if (!_showTrash) const SizedBox(width: 8),
                      TextButton.icon(
                        key: const Key('note-trash-toggle'),
                        onPressed: _isSaving || _isLifecycleMutating
                            ? null
                            : _toggleTrashSafely,
                        icon: Icon(
                          _showTrash ? Icons.arrow_back : Icons.delete_outline,
                        ),
                        label: Text(
                          _showTrash
                              ? localizations.backToNotesAction
                              : localizations.trashAction,
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
                            onTap: _showTrash || _isSaving
                                ? null
                                : () => _selectSafely(note.id),
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
                          focusNode: _titleFocusNode,
                          decoration: InputDecoration(
                            labelText: localizations.noteTitleFieldLabel,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: TextField(
                            key: const Key('note-content-field'),
                            controller: _contentController,
                            focusNode: _contentFocusNode,
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
                          children: [
                            Expanded(
                              child: _isDirty
                                  ? Text(
                                      localizations.noteUnsavedChangesIndicator,
                                      key: const Key('note-unsaved-indicator'),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : _showSavedFeedback
                                  ? Text(
                                      localizations.noteSavedStatus,
                                      key: const Key('note-saved-status'),
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            if (_selectedId != null)
                              TextButton.icon(
                                key: const Key('delete-note-button'),
                                onPressed: _isSaving || _isLifecycleMutating
                                    ? null
                                    : _confirmDeleteNoteSafely,
                                icon: const Icon(Icons.delete_outline),
                                label: Text(localizations.deleteNoteAction),
                              ),
                            const SizedBox(width: 8),
                            FilledButton(
                              key: const Key('save-note-button'),
                              onPressed:
                                  _isSaving ||
                                      (_selectedId != null && !_isDirty)
                                  ? null
                                  : _save,
                              child: _isSaving
                                  ? const SizedBox.square(
                                      dimension: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(localizations.noteSaveAction),
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

  Future<void> _toggleTrashSafely() async {
    if (!await _resolveDirtyDraft()) return;
    _toggleTrash();
  }

  void _toggleTrash() {
    setState(() {
      _showTrash = !_showTrash;
      _persistedDraft = const _PersistedNoteDraft.empty();
      _replaceDraft(title: '', content: '');
      _lifecycleFailed = false;
      _error = null;
      _showSavedFeedback = false;
    });
  }

  Future<void> _confirmDeleteNoteSafely() async {
    if (!await _resolveDirtyDraft() || !mounted) return;
    final id = _selectedId;
    if (id == null) return;
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

enum _NoteSaveResult { saved, invalid, failed, inProgress }

enum _UnsavedNoteDecision { saved, discarded, cancelled }

class _PersistedNoteDraft {
  const _PersistedNoteDraft({
    required this.id,
    required this.title,
    required this.content,
  });

  const _PersistedNoteDraft.empty() : id = null, title = '', content = '';

  factory _PersistedNoteDraft.fromNote(LifeOsNote note) => _PersistedNoteDraft(
    id: note.id,
    title: note.title,
    content: note.content,
  );

  final LifeOsEntityId? id;
  final String title;
  final String content;
}

class _UnsavedNoteDialog extends StatefulWidget {
  const _UnsavedNoteDialog({required this.onSave});

  final Future<_NoteSaveResult> Function() onSave;

  @override
  State<_UnsavedNoteDialog> createState() => _UnsavedNoteDialogState();
}

class _UnsavedNoteDialogState extends State<_UnsavedNoteDialog> {
  bool _isSaving = false;
  _NoteSaveResult? _saveResult;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _saveResult = null;
    });
    final result = await widget.onSave();
    if (!mounted) return;
    if (result == _NoteSaveResult.saved) {
      Navigator.of(context).pop(_UnsavedNoteDecision.saved);
      return;
    }
    setState(() {
      _isSaving = false;
      _saveResult = result;
    });
  }

  void _cancel() {
    if (!_isSaving) {
      Navigator.of(context).pop(_UnsavedNoteDecision.cancelled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return PopScope(
      canPop: !_isSaving,
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              !_isSaving) {
            _cancel();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AlertDialog(
          title: Text(localizations.noteUnsavedChangesDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localizations.noteUnsavedChangesDialogMessage),
              if (_saveResult case final result?) ...[
                const SizedBox(height: 8),
                Text(
                  result == _NoteSaveResult.invalid
                      ? localizations.noteContentRequired
                      : localizations.noteSaveError,
                  key: const Key('unsaved-note-save-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              key: const Key('unsaved-note-cancel'),
              onPressed: _isSaving ? null : _cancel,
              child: Text(localizations.cancelAction),
            ),
            TextButton(
              key: const Key('unsaved-note-discard'),
              onPressed: _isSaving
                  ? null
                  : () =>
                        Navigator.of(context)
                            .pop(_UnsavedNoteDecision.discarded),
              child: Text(localizations.discardChangesAction),
            ),
            FilledButton(
              key: const Key('unsaved-note-save'),
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(localizations.saveChangesAction),
            ),
          ],
        ),
      ),
    );
  }
}

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
