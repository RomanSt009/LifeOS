import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:lifeos/presentation/settings/backup_settings_providers.dart';

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
    await tester.pump();
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
    expect(find.byTooltip('Новая заметка'), findsOneWidget);
    expect(find.byTooltip('Корзина'), findsOneWidget);
    expect(
      (tester.widget<IconButton>(find.byKey(const Key('new-note-button'))).icon
              as Icon)
          .semanticLabel,
      'Новая заметка',
    );
    await tester.tap(find.byKey(const Key('save-note-button')));
    await tester.pump();
    expect(find.text('Введите название или текст'), findsOneWidget);
    expect(repository.notes, isEmpty);
  });

  testWidgets('guards dirty selection with Cancel, Discard, and Save', (
    tester,
  ) async {
    final first = _note('first', title: 'First', content: 'First content');
    final second = _note('second', title: 'Second', content: 'Second content');
    final repository = _MemoryNoteRepository([first, second]);
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 11),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('note-first')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Changed first',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('note-second')));
    await tester.pumpAndSettle();
    expect(find.text('Save changes to this Note?'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'note-content-field'), 'Changed first');

    await tester.tap(find.byKey(const ValueKey('note-second')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-discard')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'note-content-field'), 'Second content');
    expect(repository.saveCallCount, 0);

    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Changed second',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('note-first')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-save')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'note-content-field'), 'First content');
    expect(
      repository.notes.singleWhere((note) => note.id == second.id).content,
      'Changed second',
    );
    expect(repository.saveCallCount, 1);
  });

  testWidgets('guards New, Trash, and Delete without silent draft loss', (
    tester,
  ) async {
    final note = _note('guarded', title: 'Guarded', content: 'Persisted');
    final repository = _MemoryNoteRepository([note]);
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 11),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-guarded')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Unsaved',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('new-note-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-cancel')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'note-content-field'), 'Unsaved');

    await tester.tap(find.byKey(const Key('note-trash-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('Notes'), findsOneWidget);
    expect(_fieldText(tester, 'note-content-field'), 'Unsaved');

    await tester.tap(find.byKey(const Key('delete-note-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-discard')));
    await tester.pumpAndSettle();
    expect(find.text('Move Note to Trash?'), findsOneWidget);
    expect(repository.saveCallCount, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'note-content-field'), 'Persisted');

    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Discard for New',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('new-note-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-discard')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'note-content-field'), isEmpty);
  });

  testWidgets('New saves a dirty draft before opening an empty editor', (
    tester,
  ) async {
    final repository = _MemoryNoteRepository();
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 11),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Save before New',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('new-note-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-save')));
    await tester.pumpAndSettle();

    expect(repository.notes.single.content, 'Save before New');
    expect(repository.saveCallCount, 1);
    expect(_fieldText(tester, 'note-title-field'), isEmpty);
    expect(_fieldText(tester, 'note-content-field'), isEmpty);
    expect(find.byKey(const Key('note-unsaved-indicator')), findsNothing);
  });

  testWidgets('Delete can cancel or save a dirty draft before confirmation', (
    tester,
  ) async {
    final note = _note('delete-guard', title: 'Delete guard', content: 'Old');
    final repository = _MemoryNoteRepository([note]);
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 11),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-delete-guard')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Keep this draft',
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('delete-note-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-cancel')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'note-content-field'), 'Keep this draft');
    expect(repository.saveCallCount, 0);

    await tester.tap(find.byKey(const Key('delete-note-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-save')));
    await tester.pumpAndSettle();
    expect(find.text('Move Note to Trash?'), findsOneWidget);
    expect(repository.notes.single.content, 'Keep this draft');
    expect(repository.saveCallCount, 1);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.notes.single.lifecycle, LifeOsEntityLifecycle.active);
  });

  testWidgets('guard keeps invalid or failed save open and supports retry', (
    tester,
  ) async {
    final first = _note('first', title: 'First', content: 'Persisted');
    final second = _note('second', title: 'Second', content: 'Other');
    final repository = _MemoryNoteRepository([first, second]);
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 11),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('note-content-field')), '   ');
    await tester.pump();
    await tester.tap(find.byKey(const Key('new-note-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a title or content'), findsWidgets);
    expect(find.text('Save changes to this Note?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('unsaved-note-cancel')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-content-field')), '');
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('note-first')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Will retry',
    );
    await tester.pump();
    repository.failNextSave = true;
    await tester.tap(find.byKey(const ValueKey('note-second')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('unsaved-note-save-error')), findsOneWidget);
    expect(find.text('Save changes to this Note?'), findsOneWidget);
    expect(_fieldText(tester, 'note-content-field'), 'Will retry');

    await tester.tap(find.byKey(const Key('unsaved-note-save')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'note-content-field'), 'Other');
    expect(repository.saveCallCount, 2);
  });

  testWidgets(
    'delayed guard save disables duplicate actions and keeps target',
    (tester) async {
      final first = _note('first', title: 'First', content: 'Persisted');
      final second = _note('second', title: 'Second', content: 'Target');
      final repository = _MemoryNoteRepository([first, second]);
      final saveBarrier = Completer<void>();
      repository.saveBarrier = saveBarrier;
      await tester.pumpWidget(
        _testApp(
          repository,
          locale: const Locale('en'),
          utcClock: () => DateTime.utc(2026, 9, 12, 11),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('note-first')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('note-content-field')),
        'Delayed update',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('note-second')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('unsaved-note-save')));
      await tester.pump();

      expect(repository.saveCallCount, 1);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('unsaved-note-save')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const Key('unsaved-note-discard')))
            .onPressed,
        isNull,
      );

      saveBarrier.complete();
      await tester.pumpAndSettle();
      expect(_fieldText(tester, 'note-content-field'), 'Target');
      expect(repository.saveCallCount, 1);
    },
  );

  testWidgets('a delayed save never overwrites newer editor input', (
    tester,
  ) async {
    final repository = _MemoryNoteRepository();
    final saveBarrier = Completer<void>();
    repository.saveBarrier = saveBarrier;
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 11),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Submitted content',
    );
    await tester.pump();
    await _pressControlS(tester);
    await tester.pump();
    await _pressControlS(tester);
    await tester.pump();
    expect(repository.saveCallCount, 1);
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Newer draft',
    );
    await tester.pump();

    saveBarrier.complete();
    await tester.pumpAndSettle();
    expect(repository.notes.single.content, 'Submitted content');
    expect(_fieldText(tester, 'note-content-field'), 'Newer draft');
    expect(find.byKey(const Key('note-unsaved-indicator')), findsOneWidget);

    await _pressControlS(tester);
    await tester.pumpAndSettle();
    expect(repository.notes, hasLength(1));
    expect(repository.notes.single.content, 'Newer draft');
    expect(repository.saveCallCount, 2);
  });

  testWidgets('provider refresh does not overwrite a dirty editor', (
    tester,
  ) async {
    final original = _note('refresh', title: 'Original', content: 'Persisted');
    final repository = _MemoryNoteRepository([original]);
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 11),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-refresh')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Local draft',
    );
    await tester.pump();

    repository.notes[0] = original.edit(
      title: original.title,
      content: 'External refresh',
      updatedAt: DateTime.utc(2026, 9, 12, 11),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NotePage)),
    );
    container.invalidate(noteListControllerProvider);
    await tester.pumpAndSettle();

    expect(_fieldText(tester, 'note-content-field'), 'Local draft');
    expect(find.byKey(const Key('note-unsaved-indicator')), findsOneWidget);
  });

  testWidgets('successful confirmed Restore revision clears the local draft', (
    tester,
  ) async {
    final repository = _MemoryNoteRepository();
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 11),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Replaced dataset draft',
    );
    await tester.pump();
    expect(find.byKey(const Key('note-unsaved-indicator')), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(NotePage)),
    );
    container.read(backupRestoreRevisionProvider.notifier).advance();
    await tester.pumpAndSettle();

    expect(_fieldText(tester, 'note-content-field'), isEmpty);
    expect(find.byKey(const Key('note-unsaved-indicator')), findsNothing);
  });

  testWidgets('Ctrl+S saves locally and clean semantic saves are no-ops', (
    tester,
  ) async {
    final repository = _MemoryNoteRepository();
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 11),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('note-title-field')));
    await tester.pump();
    await _pressControlS(tester);
    await tester.pump();
    expect(find.text('Enter a title or content'), findsOneWidget);
    expect(repository.saveCallCount, 0);

    await tester.enterText(find.byKey(const Key('note-title-field')), 'Note');
    await tester.pump();
    await _pressControlS(tester);
    await tester.pumpAndSettle();
    expect(repository.saveCallCount, 1);
    expect(find.byKey(const Key('note-saved-status')), findsOneWidget);

    await _pressControlS(tester);
    await tester.pumpAndSettle();
    expect(repository.saveCallCount, 1);

    await tester.enterText(
      find.byKey(const Key('note-title-field')),
      '  Note  ',
    );
    await tester.pump();
    expect(find.byKey(const Key('note-unsaved-indicator')), findsNothing);
    await _pressControlS(tester);
    await tester.pumpAndSettle();
    expect(repository.saveCallCount, 1);
  });

  testWidgets('localizes the unsaved guard in Russian', (tester) async {
    final repository = _MemoryNoteRepository();
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('ru'),
        utcClock: () => DateTime.utc(2026, 9, 12),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Черновик',
    );
    await tester.pump();
    expect(find.text('Есть несохранённые изменения'), findsOneWidget);
    await tester.tap(find.byKey(const Key('new-note-button')));
    await tester.pumpAndSettle();
    expect(find.text('Сохранить изменения заметки?'), findsOneWidget);
    expect(find.text('Сохранить'), findsOneWidget);
    expect(find.text('Не сохранять'), findsOneWidget);
    expect(find.text('Отмена'), findsOneWidget);
  });

  testWidgets('deletes and restores a clean Note', (tester) async {
    final repository = _MemoryNoteRepository();
    final timestamps = [
      DateTime.utc(2026, 9, 12, 10),
      DateTime.utc(2026, 9, 12, 11),
      DateTime.utc(2026, 9, 12, 12),
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
    await tester.pump();
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

  testWidgets('Note context menu keeps its id target and dirty guard', (
    tester,
  ) async {
    final first = _note('note-a', title: 'First Note', content: 'First body');
    final second = _note(
      'note-b',
      title: 'Second Note',
      content: 'Second body',
    );
    final repository = _MemoryNoteRepository([first, second]);
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 12),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('First Note'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('note-content-field')),
      'Dirty first body',
    );
    await _secondaryTap(tester, find.text('Second Note'));

    expect(find.text('Edit Note'), findsOneWidget);
    expect(find.byKey(const Key('note-context-relationships')), findsOneWidget);
    expect(find.text('Move to Trash'), findsOneWidget);
    await tester.tap(find.text('Move to Trash'));
    await tester.pumpAndSettle();
    expect(find.text('Save changes to this Note?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unsaved-note-cancel')));
    await tester.pumpAndSettle();
    expect(repository.saveCallCount, 0);
    expect(
      repository.notes.every(
        (note) => note.lifecycle == LifeOsEntityLifecycle.active,
      ),
      isTrue,
    );

    await _secondaryTap(tester, find.text('Second Note'));
    await tester.tap(find.text('Move to Trash'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unsaved-note-discard')));
    await tester.pumpAndSettle();
    expect(find.text('Move Note to Trash?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-note-button')));
    await tester.pumpAndSettle();

    expect(
      repository.notes.singleWhere((note) => note.id == second.id).lifecycle,
      LifeOsEntityLifecycle.deleted,
    );
    expect(
      repository.notes.singleWhere((note) => note.id == first.id).lifecycle,
      LifeOsEntityLifecycle.active,
    );
  });

  testWidgets('Note context Relationships selects the right-clicked Note', (
    tester,
  ) async {
    final first = _note('note-a', title: 'First Note', content: 'First body');
    final second = _note(
      'note-b',
      title: 'Second Note',
      content: 'Second body',
    );
    final repository = _MemoryNoteRepository([first, second]);
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 12),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('First Note'));
    await tester.pumpAndSettle();
    await _secondaryTap(tester, find.text('Second Note'));
    await tester.tap(find.byKey(const Key('note-context-relationships')));
    await tester.pumpAndSettle();

    expect(_fieldText(tester, 'note-title-field'), 'Second Note');
    expect(
      tester
          .widget<ListTile>(find.byKey(const ValueKey('note-note-b')))
          .selected,
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('add-relationship-note-b')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('Note keyboard actions require safe feature focus', (
    tester,
  ) async {
    final note = _note('note-a', title: 'Keyboard Note', content: 'Body');
    final repository = _MemoryNoteRepository([note]);
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 12),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.text('Keyboard Note'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(find.text('Move Note to Trash?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('note-content-field')));
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);

    await _pressControlN(tester);
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'note-title-field'), '');
    expect(_fieldText(tester, 'note-content-field'), '');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('note-title-field')))
          .focusNode
          ?.hasFocus,
      isTrue,
    );
  });

  testWidgets('Note Trash context menu exposes Restore only in Russian', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final deleted = _note(
      'note-a',
      title: 'Удалённая заметка',
      content: 'Текст',
    ).delete(updatedAt: DateTime.utc(2026, 9, 12, 11));
    final repository = _MemoryNoteRepository([deleted]);
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('ru'),
        utcClock: () => DateTime.utc(2026, 9, 12, 12),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-trash-toggle')));
    await tester.pumpAndSettle();
    await _secondaryTap(tester, find.text('Удалённая заметка'));

    expect(find.byKey(const Key('note-context-restore')), findsOneWidget);
    expect(find.byKey(const Key('note-context-edit')), findsNothing);
    expect(find.byKey(const Key('note-context-move-to-trash')), findsNothing);
    expect(find.text('Восстановить заметку'), findsWidgets);
    await tester.tap(find.byKey(const Key('note-context-restore')));
    await tester.pumpAndSettle();
    expect(repository.notes.single.lifecycle, LifeOsEntityLifecycle.active);
  });

  testWidgets('Note list load failure exposes a working retry', (tester) async {
    final repository = _MemoryNoteRepository()..failNextRead = true;
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 12),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load Notes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry-note-list')));
    await tester.pumpAndSettle();
    expect(find.text('No Notes yet'), findsOneWidget);
    expect(repository.readCallCount, 2);
  });

  testWidgets('Note restore failure keeps the Trash item and allows retry', (
    tester,
  ) async {
    final deleted = _note(
      'note-a',
      title: 'Restore Note',
      content: 'Body',
    ).delete(updatedAt: DateTime.utc(2026, 9, 12, 11));
    final repository = _MemoryNoteRepository([deleted])..failNextSave = true;
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 12),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-trash-toggle')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('restore-note-note-a')));
    await tester.pumpAndSettle();
    expect(find.text('Unable to restore Note'), findsOneWidget);
    expect(find.byKey(const ValueKey('deleted-note-note-a')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('restore-note-note-a')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('deleted-note-note-a')), findsNothing);
    expect(repository.notes.single.lifecycle, LifeOsEntityLifecycle.active);
  });

  testWidgets('clean stale Note selection clears after provider refresh', (
    tester,
  ) async {
    final note = _note('note-a', title: 'Stale Note', content: 'Body');
    final repository = _MemoryNoteRepository([note]);
    await tester.pumpWidget(
      _testApp(
        repository,
        locale: const Locale('en'),
        utcClock: () => DateTime.utc(2026, 9, 12, 12),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-note-a')));
    await tester.pumpAndSettle();
    expect(_fieldText(tester, 'note-title-field'), 'Stale Note');

    repository.notes.clear();
    ProviderScope.containerOf(tester.element(find.byType(NotePage)))
        .invalidate(noteListControllerProvider);
    await tester.pumpAndSettle();

    expect(_fieldText(tester, 'note-title-field'), '');
    expect(_fieldText(tester, 'note-content-field'), '');
    expect(find.byKey(const Key('delete-note-button')), findsNothing);
  });
}

Future<void> _secondaryTap(WidgetTester tester, Finder finder) async {
  await tester.tapAt(tester.getCenter(finder), buttons: kSecondaryMouseButton);
  await tester.pumpAndSettle();
}

Future<void> _pressControlN(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

LifeOsNote _note(String id, {required String title, required String content}) =>
    LifeOsNote.createUserNote(
      id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.note),
      title: title,
      content: content,
      timestamp: DateTime.utc(2026, 9, 12, 10),
    );

String _fieldText(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(Key(key))).controller!.text;

Future<void> _pressControlS(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
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
  _MemoryNoteRepository([Iterable<LifeOsNote> initialNotes = const []])
    : notes = List.of(initialNotes);

  final List<LifeOsNote> notes;
  int saveCallCount = 0;
  bool failNextSave = false;
  bool failNextRead = false;
  int readCallCount = 0;
  Completer<void>? saveBarrier;

  @override
  Future<List<LifeOsNote>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async {
    readCallCount += 1;
    if (failNextRead) {
      failNextRead = false;
      throw StateError('Expected read failure.');
    }
    return notes.where((note) => note.lifecycle == lifecycle).toList();
  }

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
    saveCallCount += 1;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('Expected save failure.');
    }
    await saveBarrier?.future;
    notes.removeWhere((current) => current.id == note.id);
    notes.add(note);
  }
}
