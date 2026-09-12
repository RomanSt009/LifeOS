import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/create_lifeos_note.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_note.dart';
import 'package:lifeos/application/use_cases/get_lifeos_note.dart';
import 'package:lifeos/application/use_cases/get_lifeos_notes.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/repositories/lifeos_note_repository.dart';

void main() {
  test(
    'creates, lists, and gets a Note through Application boundaries',
    () async {
      final repository = _FakeNoteRepository();
      final timestamp = DateTime.utc(2026, 9, 12, 14);
      final create = CreateLifeOsNote(
        repository: repository,
        entityIdGenerator: () => 'note-created',
        utcClock: () => timestamp,
      );

      final note = await create(title: '  Title  ', content: ' exact ');

      expect(note.title, 'Title');
      expect(note.content, ' exact ');
      expect(await GetLifeOsNotes(repository)(), [note]);
      expect(await GetLifeOsNote(repository)(note.id), note);
      expect(repository.saveCount, 1);
    },
  );

  test(
    'persists material edits and skips persistence for no-op edits',
    () async {
      final repository = _FakeNoteRepository();
      final original = LifeOsNote.createUserNote(
        id: const LifeOsEntityId(
          value: 'note-edit',
          entityType: LifeOsEntityType.note,
        ),
        title: 'Title',
        content: 'Body',
        timestamp: DateTime.utc(2026, 9, 12, 10),
      );
      await repository.save(original);
      var clock = DateTime.utc(2026, 9, 12, 11);
      final edit = EditLifeOsNote(
        repository: repository,
        utcClock: () => clock,
      );

      final noOp = await edit(original.id, title: ' Title ', content: 'Body');
      expect(noOp, same(original));
      expect(repository.saveCount, 1);

      clock = DateTime.utc(2026, 9, 12, 12);
      final changed = await edit(
        original.id,
        title: 'Edited',
        content: 'Body 2',
      );
      expect(changed?.version, 2);
      expect(repository.saveCount, 2);
      expect(await repository.getById(original.id), changed);
    },
  );
}

class _FakeNoteRepository implements LifeOsNoteRepository {
  final Map<LifeOsEntityId, LifeOsNote> notes = {};
  int saveCount = 0;

  @override
  Future<List<LifeOsNote>> getAll() async => notes.values.toList();

  @override
  Future<LifeOsNote?> getById(LifeOsEntityId id) async => notes[id];

  @override
  Future<void> save(LifeOsNote note) async {
    saveCount += 1;
    notes[note.id] = note;
  }
}
