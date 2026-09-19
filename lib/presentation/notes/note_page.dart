import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../l10n/app_localizations.dart';
import '../navigation/lifeos_feature_command.dart';
import '../relationships/related_entities_section.dart';
import '../settings/backup_settings_providers.dart';
import 'note_providers.dart';

class NotePage extends ConsumerStatefulWidget {
  const NotePage({
    this.featureCommand,
    this.onFeatureCommandHandled,
    super.key,
  });

  final LifeOsFeatureCommand? featureCommand;
  final ValueChanged<int>? onFeatureCommandHandled;

  @override
  ConsumerState<NotePage> createState() => _NotePageState();
}

class _NotePageState extends ConsumerState<NotePage> {
  static const _compactEditorBreakpoint = 400.0;
  static const _compactRelationshipsMaxListHeight = 80.0;
  static const _relationshipsMaxListHeight = 160.0;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _featureFocusNode = FocusNode(debugLabel: 'Note feature actions');
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  final _relationshipKey = GlobalKey();
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
    if (event is KeyDownEvent && HardwareKeyboard.instance.isControlPressed) {
      if (event.logicalKey == LogicalKeyboardKey.keyS) {
        if (!_showTrash) _save();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyN) {
        if (!_showTrash && !_isLifecycleMutating) _startNewSafely();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleFeatureKeyEvent(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyN) {
      if (!_showTrash && !_isLifecycleMutating) _startNewSafely();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.delete &&
        !_showTrash &&
        !_isLifecycleMutating &&
        !_hasEditableTextFocus() &&
        _selectedId != null) {
      _confirmDeleteNoteSafely();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _hasEditableTextFocus() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context?.widget is EditableText ||
        context?.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _draftChanged() {
    if (!mounted || _isReplacingDraft) return;
    setState(() {
      _showSavedFeedback = false;
      _error = null;
    });
  }

  @override
  void didUpdateWidget(covariant NotePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final command = widget.featureCommand;
    if (command == null || command.id == oldWidget.featureCommand?.id) return;
    if (command.type == LifeOsFeatureCommandType.newNote) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.featureCommand?.id != command.id) return;
        widget.onFeatureCommandHandled?.call(command.id);
        _startNewFromShell();
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_draftChanged);
    _contentController.removeListener(_draftChanged);
    _featureFocusNode.dispose();
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

  Future<void> _startNewFromShell() async {
    if (!await _resolveDirtyDraft() || !mounted) return;
    if (_showTrash) {
      setState(() {
        _showTrash = false;
        _lifecycleFailed = false;
      });
    }
    _startNew();
  }

  Future<bool> _selectSafely(
    LifeOsEntityId targetId, {
    bool requestEditorFocus = true,
  }) async {
    if (targetId == _selectedId) {
      if (requestEditorFocus) _requestFocus(_contentFocusNode);
      return true;
    }
    if (!await _resolveDirtyDraft() || !mounted) return false;
    final target = ref
        .read(noteListControllerProvider)
        .requireValue
        .where((note) => note.id == targetId)
        .firstOrNull;
    if (target == null) return false;
    _select(target, requestFocus: requestEditorFocus);
    if (!requestEditorFocus) _requestFocus(_featureFocusNode);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(backupRestoreRevisionProvider, (_, _) => _startNew());
    final localizations = AppLocalizations.of(context);
    final notes = ref.watch(
      _showTrash ? noteTrashControllerProvider : noteListControllerProvider,
    );

    return Focus(
      focusNode: _featureFocusNode,
      autofocus: true,
      onKeyEvent: _handleFeatureKeyEvent,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: notes.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(localizations.noteLoadError),
                const SizedBox(height: 8),
                TextButton.icon(
                  key: const Key('retry-note-list'),
                  onPressed: _retryLoad,
                  icon: const Icon(Icons.refresh),
                  label: Text(localizations.retryAction),
                ),
              ],
            ),
          ),
          data: (items) => _reconcileSelectionAndReturn(
            items,
            Row(
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          if (!_showTrash)
                            IconButton.filled(
                              key: const Key('new-note-button'),
                              tooltip: localizations.noteCreateAction,
                              onPressed: _isSaving || _isLifecycleMutating
                                  ? null
                                  : _startNewSafely,
                              icon: Icon(
                                Icons.note_add_outlined,
                                semanticLabel: localizations.noteCreateAction,
                              ),
                            ),
                          IconButton(
                            key: const Key('note-trash-toggle'),
                            tooltip: _showTrash
                                ? localizations.backToNotesAction
                                : localizations.trashAction,
                            onPressed: _isSaving || _isLifecycleMutating
                                ? null
                                : _toggleTrashSafely,
                            icon: Icon(
                              _showTrash
                                  ? Icons.arrow_back
                                  : Icons.delete_outline,
                              semanticLabel: _showTrash
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
                              return GestureDetector(
                                onSecondaryTapDown: (details) => _showNoteMenu(
                                  note,
                                  details.globalPosition,
                                  deleted: _showTrash,
                                ),
                                child: ListTile(
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
                                          tooltip:
                                              localizations.restoreNoteAction,
                                          onPressed: _isLifecycleMutating
                                              ? null
                                              : () => _restoreNote(note),
                                          icon: Icon(
                                            Icons.restore,
                                            semanticLabel:
                                                localizations.restoreNoteAction,
                                          ),
                                        )
                                      : null,
                                  onTap: _showTrash || _isSaving
                                      ? null
                                      : () => _selectSafely(
                                          note.id,
                                          requestEditorFocus: false,
                                        ),
                                ),
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
                                  labelText:
                                      localizations.noteContentFieldLabel,
                                  alignLabelWithHint: true,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            if (_selectedId case final selectedId?) ...[
                              const SizedBox(height: 8),
                              LayoutBuilder(
                                builder: (context, constraints) =>
                                    RelatedEntitiesSection(
                                      key: _relationshipKey,
                                      entityId: selectedId,
                                      maxListHeight:
                                          constraints.maxWidth <
                                              _compactEditorBreakpoint
                                          ? _compactRelationshipsMaxListHeight
                                          : _relationshipsMaxListHeight,
                                    ),
                              ),
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
                            _buildEditorFooter(localizations),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorFooter(AppLocalizations localizations) {
    final hasStatus = _isDirty || _showSavedFeedback;
    final status = _isDirty
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
        : const SizedBox.shrink();
    final deleteButton = TextButton.icon(
      key: const Key('delete-note-button'),
      onPressed: _isSaving || _isLifecycleMutating
          ? null
          : _confirmDeleteNoteSafely,
      icon: const Icon(Icons.delete_outline),
      label: Text(localizations.deleteNoteAction),
    );
    final saveButton = FilledButton(
      key: const Key('save-note-button'),
      onPressed: _isSaving || (_selectedId != null && !_isDirty) ? null : _save,
      child: _isSaving
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(localizations.noteSaveAction),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _compactEditorBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasStatus) ...[status, const SizedBox(height: 8)],
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [if (_selectedId != null) deleteButton, saveButton],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: status),
            if (_selectedId != null) deleteButton,
            const SizedBox(width: 8),
            saveButton,
          ],
        );
      },
    );
  }

  void _retryLoad() {
    ref.invalidate(
      _showTrash ? noteTrashControllerProvider : noteListControllerProvider,
    );
  }

  Widget _reconcileSelectionAndReturn(List<LifeOsNote> notes, Widget child) {
    _reconcileSelection(notes);
    return child;
  }

  void _reconcileSelection(List<LifeOsNote> notes) {
    final selectedId = _selectedId;
    if (_showTrash ||
        selectedId == null ||
        _isDirty ||
        _isSaving ||
        notes.any((note) => note.id == selectedId)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedId == selectedId && !_isDirty && !_isSaving) {
        _startNew(requestFocus: false);
      }
    });
  }

  Future<void> _showNoteMenu(
    LifeOsNote note,
    Offset position, {
    required bool deleted,
  }) async {
    final localizations = AppLocalizations.of(context);
    final action = await showMenu<_NoteContextAction>(
      context: context,
      position: _menuPosition(context, position),
      items: deleted
          ? [
              PopupMenuItem(
                key: const Key('note-context-restore'),
                value: _NoteContextAction.restore,
                child: Text(localizations.restoreNoteAction),
              ),
            ]
          : [
              PopupMenuItem(
                key: const Key('note-context-edit'),
                value: _NoteContextAction.edit,
                child: Text(localizations.noteEditAction),
              ),
              PopupMenuItem(
                key: const Key('note-context-relationships'),
                value: _NoteContextAction.relationships,
                child: Text(localizations.relationshipSectionTitle),
              ),
              PopupMenuItem(
                key: const Key('note-context-move-to-trash'),
                value: _NoteContextAction.moveToTrash,
                child: Text(localizations.moveToTrashAction),
              ),
            ],
    );
    if (!mounted) return;
    switch (action) {
      case _NoteContextAction.edit:
        await _selectSafely(note.id);
      case _NoteContextAction.relationships:
        if (await _selectSafely(note.id, requestEditorFocus: false)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final relationshipContext = _relationshipKey.currentContext;
            if (relationshipContext != null) {
              Scrollable.ensureVisible(
                relationshipContext,
                duration: const Duration(milliseconds: 150),
              );
            }
          });
        }
      case _NoteContextAction.moveToTrash:
        if (await _selectSafely(note.id, requestEditorFocus: false)) {
          await _confirmDeleteNoteSafely();
        }
      case _NoteContextAction.restore:
        await _restoreNote(note);
      case null:
        _featureFocusNode.requestFocus();
    }
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

enum _NoteContextAction { edit, relationships, moveToTrash, restore }

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

RelativeRect _menuPosition(BuildContext context, Offset globalPosition) {
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  return RelativeRect.fromRect(
    Rect.fromPoints(globalPosition, globalPosition),
    Offset.zero & overlay.size,
  );
}
