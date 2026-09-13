import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';

void main() {
  const noteId = LifeOsEntityId(
    value: 'note-1',
    entityType: LifeOsEntityType.note,
  );
  final createdAt = DateTime.utc(2026, 9, 12, 10);

  test('creates a normalized user Note and preserves content exactly', () {
    final note = LifeOsNote.createUserNote(
      id: noteId,
      title: '  First Note  ',
      content: '  first line\r\nsecond line  ',
      timestamp: createdAt,
    );

    expect(note.id, noteId);
    expect(note.entityType, LifeOsEntityType.note);
    expect(note.title, 'First Note');
    expect(note.content, '  first line\r\nsecond line  ');
    expect(note.createdAt, createdAt);
    expect(note.updatedAt, same(createdAt));
    expect(note.lifecycle, LifeOsEntityLifecycle.active);
    expect(note.version, 1);
    expect(note.source, LifeOsEntitySource.user);
  });

  test(
    'requires meaningful title or content and valid creation boundaries',
    () {
      expect(
        () => LifeOsNote.createUserNote(
          id: noteId,
          title: '   ',
          content: '\n\t ',
          timestamp: createdAt,
        ),
        throwsArgumentError,
      );
      expect(
        () => LifeOsNote.createUserNote(
          id: const LifeOsEntityId(
            value: 'task-1',
            entityType: LifeOsEntityType.task,
          ),
          title: 'Note',
          content: '',
          timestamp: createdAt,
        ),
        throwsArgumentError,
      );
      expect(
        () => LifeOsNote.createUserNote(
          id: noteId,
          title: 'Note',
          content: '',
          timestamp: DateTime(2026, 9, 12, 10),
        ),
        throwsArgumentError,
      );
    },
  );

  test('edits atomically and advances metadata only for material changes', () {
    final note = LifeOsNote.createUserNote(
      id: noteId,
      title: 'Title',
      content: 'Body',
      timestamp: createdAt,
    );
    final noOp = note.edit(
      title: '  Title  ',
      content: 'Body',
      updatedAt: DateTime.utc(2026, 9, 12, 11),
    );
    final editedAt = DateTime.utc(2026, 9, 12, 12);
    final edited = note.edit(
      title: '  Edited  ',
      content: ' Body\n',
      updatedAt: editedAt,
    );

    expect(noOp, same(note));
    expect(edited.title, 'Edited');
    expect(edited.content, ' Body\n');
    expect(edited.updatedAt, editedAt);
    expect(edited.version, 2);
    expect(edited.id, note.id);
    expect(edited.createdAt, note.createdAt);
    expect(note.title, 'Title');
    expect(note.version, 1);
  });

  test('rejects invalid edits and timestamps moving backwards', () {
    final note = LifeOsNote.createUserNote(
      id: noteId,
      title: 'Title',
      content: '',
      timestamp: createdAt,
    );

    expect(
      () => note.edit(
        title: ' ',
        content: '\n',
        updatedAt: DateTime.utc(2026, 9, 12, 11),
      ),
      throwsArgumentError,
    );
    expect(
      () => note.edit(
        title: 'Title',
        content: '',
        updatedAt: DateTime.utc(2026, 9, 12, 9),
      ),
      throwsArgumentError,
    );
    expect(
      () => note.edit(
        title: 'Title',
        content: '',
        updatedAt: DateTime(2026, 9, 12, 11),
      ),
      throwsArgumentError,
    );
  });

  test('rejects hydrated state that violates Note invariants', () {
    expect(
      () => LifeOsNote(
        id: noteId,
        title: ' Not normalized ',
        content: '',
        createdAt: createdAt,
        updatedAt: createdAt,
        lifecycle: LifeOsEntityLifecycle.active,
        version: 1,
        source: LifeOsEntitySource.user,
      ),
      throwsArgumentError,
    );
    expect(
      () => LifeOsNote(
        id: noteId,
        title: 'Valid',
        content: '',
        createdAt: createdAt,
        updatedAt: createdAt,
        lifecycle: LifeOsEntityLifecycle.active,
        version: 0,
        source: LifeOsEntitySource.user,
      ),
      throwsArgumentError,
    );
  });

  test('applies the Note lifecycle transition matrix immutably', () {
    final note = LifeOsNote.createUserNote(
      id: noteId,
      title: 'Lifecycle Note',
      content: 'Body',
      timestamp: createdAt,
    );
    final archived = note.archive(updatedAt: DateTime.utc(2026, 9, 12, 11));
    final activeAgain = archived.unarchive(
      updatedAt: DateTime.utc(2026, 9, 12, 12),
    );
    final deleted = activeAgain.delete(
      updatedAt: DateTime.utc(2026, 9, 12, 13),
    );
    final restored = deleted.restore(updatedAt: DateTime.utc(2026, 9, 12, 14));

    expect(archived.lifecycle, LifeOsEntityLifecycle.archived);
    expect(activeAgain.lifecycle, LifeOsEntityLifecycle.active);
    expect(deleted.lifecycle, LifeOsEntityLifecycle.deleted);
    expect(restored.lifecycle, LifeOsEntityLifecycle.active);
    expect(restored.version, 5);
    expect(restored.updatedAt, DateTime.utc(2026, 9, 12, 14));
    expect(note.lifecycle, LifeOsEntityLifecycle.active);
    expect(
      archived.delete(updatedAt: DateTime.utc(2026, 9, 12, 12)).lifecycle,
      LifeOsEntityLifecycle.deleted,
    );
  });

  test('inactive Note guards edits and invalid lifecycle transitions', () {
    final note = LifeOsNote.createUserNote(
      id: noteId,
      title: 'Lifecycle Note',
      content: 'Body',
      timestamp: createdAt,
    );
    final deleted = note.delete(updatedAt: DateTime.utc(2026, 9, 12, 11));

    expect(note.restore(updatedAt: DateTime.utc(2026, 9, 12, 11)), same(note));
    expect(
      deleted.delete(updatedAt: DateTime.utc(2026, 9, 12, 12)),
      same(deleted),
    );
    expect(
      () => deleted.archive(updatedAt: DateTime.utc(2026, 9, 12, 12)),
      throwsStateError,
    );
    expect(
      () => deleted.edit(
        title: 'Changed',
        content: 'Body',
        updatedAt: DateTime.utc(2026, 9, 12, 12),
      ),
      throwsStateError,
    );
  });
}
