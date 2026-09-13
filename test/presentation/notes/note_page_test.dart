import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/create_lifeos_note.dart';
import 'package:lifeos/application/use_cases/delete_lifeos_note.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_note.dart';
import 'package:lifeos/application/use_cases/restore_lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/repositories/lifeos_note_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/notes/note_page.dart';
import 'package:lifeos/presentation/notes/note_providers.dart';

void main() {
  testWidgets('creates, selects, edits, and saves a localized Note', (
    tester,
  ) async {
    final repository = _MemoryNoteRepository();
    final timestamps = [
      DateTime.utc(2026, 9, 12, 10),
      DateTime.utc(2026, 9, 12, 11),
    ];
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => timestamps.removeAt(0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Notes yet'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      '  Note  ',
    );
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      ' exact\ncontent ',
    );
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();

    expect(repository.notes.single.title, 'Note');
    expect(repository.notes.single.content, ' exact\ncontent ');
    expect(find.byKey(const ValueKey('note-note-created')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'edited',
    );
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();

    expect(repository.notes.single.content, 'edited');
    expect(repository.notes.single.version, 2);
  });

  testWidgets('shows Russian strings and validates an empty Note', (
    tester,
  ) async {
    final repository = _MemoryNoteRepository();
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('ru'),
        utcClock: () => DateTime.utc(2026, 9, 12),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Заметки'), findsOneWidget);
    expect(find.text('Новая заметка'), findsOneWidget);
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pump();
    expect(find.text('Введите название или текст'), findsOneWidget);
    expect(repository.notes, isEmpty);
  });

  testWidgets('protects a dirty Note, then deletes and restores it', (
    tester,
  ) async {
    final repository = _MemoryNoteRepository();
    final timestamps = [
      DateTime.utc(2026, 9, 12, 10),
      DateTime.utc(2026, 9, 12, 11),
      DateTime.utc(2026, 9, 12, 12),
      DateTime.utc(2026, 9, 12, 13),
    ];
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => timestamps.removeAt(0),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-title-field')), 'Note');
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Unsaved draft',
    );
    await tester.pump();
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('delete-note-button')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('note-trash-toggle')))
          .onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-note-button')));
    await tester.pumpAndSettle();
    expect(find.text('Move Note to Trash?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-note-button')));
    await tester.pumpAndSettle();
    expect(repository.notes.single.lifecycle, LifeOsEntityLifecycle.deleted);

    await tester.tap(find.byKey(const Key('note-trash-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('deleted-note-note-created')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('restore-note-note-created')));
    await tester.pumpAndSettle();
    expect(repository.notes.single.lifecycle, LifeOsEntityLifecycle.active);
  });
}

Widget _testApp(
  _MemoryNoteRepository repository, {
  required Locale locale,
  required DateTime Function() utcClock,
}) {
  return ProviderScope(
    overrides: [
      lifeOsNoteRepositoryProvider.overrideWithValue(repository),
      createLifeOsNoteProvider.overrideWithValue(
        CreateLifeOsNote(
          repository: repository,
          entityIdGenerator: () => 'note-created',
          utcClock: utcClock,
        ),
      ),
      editLifeOsNoteProvider.overrideWithValue(
        EditLifeOsNote(repository: repository, utcClock: utcClock),
      ),
      deleteLifeOsNoteProvider.overrideWithValue(
        DeleteLifeOsNote(repository: repository, utcClock: utcClock),
      ),
      restoreLifeOsNoteProvider.overrideWithValue(
        RestoreLifeOsNote(repository: repository, utcClock: utcClock),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: NotePage()),
    ),
  );
}

class _MemoryNoteRepository implements LifeOsNoteRepository {
  final List<LifeOsNote> notes = [];

  @override
  Future<List<LifeOsNote>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async => notes.where((note) => note.lifecycle == lifecycle).toList();

  @override
  Future<List<LifeOsNote>> getAll() async => List.of(notes);

  @override
  Future<LifeOsNote?> getById(LifeOsEntityId id) async {
    for (final note in notes) {
      if (note.id == id) {
        return note;
      }
    }
    return null;
  }

  @override
  Future<void> save(LifeOsNote note) async {
    notes.removeWhere((current) => current.id == note.id);
    notes.add(note);
  }
}
