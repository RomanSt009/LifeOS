import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../l10n/app_localizations.dart';
import '../relationships/related_entities_section.dart';
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
  bool _isSaving = false;
  _NoteEditorError? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _startNew() {
    setState(() {
      _selectedId = null;
      _titleController.clear();
      _contentController.clear();
      _error = null;
    });
  }

  void _select(LifeOsNote note) {
    setState(() {
      _selectedId = note.id;
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
    final localizations = AppLocalizations.of(context);
    final notes = ref.watch(noteListControllerProvider);

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
                    localizations.noteListTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('new-note-button'),
                    onPressed: _startNew,
                    icon: const Icon(Icons.note_add_outlined),
                    label: Text(localizations.noteCreateAction),
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    Expanded(
                      child: Center(child: Text(localizations.noteListEmpty)),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final note = items[index];
                          return ListTile(
                            key: ValueKey('note-${note.id.value}'),
                            selected: note.id == _selectedId,
                            title: Text(
                              note.title.isEmpty
                                  ? localizations.noteUntitled
                                  : note.title,
                            ),
                            onTap: () => _select(note),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const VerticalDivider(width: 32),
            Expanded(
              child: Column(
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      key: const Key('save-note-button'),
                      onPressed: _isSaving ? null : _save,
                      child: Text(localizations.noteSaveAction),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NoteEditorError { contentRequired, saveFailed }
