import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/delete_lifeos_note.dart';
import 'package:lifeos/application/use_cases/restore_lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/mappers/lifeos_note_mapper.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_note_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_task_repository.dart';

void main() {
  late LifeOsDatabase database;
  late DriftLifeOsNoteRepository repository;
  late List<String> changeIds;

  const noteId = LifeOsEntityId(
    value: 'note-1',
    entityType: LifeOsEntityType.note,
  );
  final createdAt = DateTime.utc(2026, 9, 12, 10);

  LifeOsNote createNote({
    LifeOsEntityId id = noteId,
    String title = 'Note title',
    String content = 'Note content',
    DateTime? timestamp,
  }) {
    return LifeOsNote.createUserNote(
      id: id,
      title: title,
      content: content,
      timestamp: timestamp ?? createdAt,
    );
  }

  setUp(() {
    database = LifeOsDatabase(NativeDatabase.memory());
    changeIds = List.generate(20, (index) => 'change-${index + 1}');
    repository = DriftLifeOsNoteRepository(
      database,
      () => changeIds.removeAt(0),
      'device-test',
    );
  });

  tearDown(() => database.close());

  test(
    'creates, reads, and updates a Note with full Outbox snapshots',
    () async {
      final original = createNote(content: '  exact\r\ncontent  ');
      final edited = original.edit(
        title: 'Edited title',
        content: 'edited content',
        updatedAt: DateTime.utc(2026, 9, 12, 11),
      );

      await repository.save(original);
      await repository.save(edited);

      expect(await repository.getById(noteId), edited);
      final outbox = await database.select(database.outboxEntries).get();
      expect(outbox, hasLength(2));
      expect(outbox.first.operation, 'CREATE');
      expect(outbox.first.baseVersion, isNull);
      expect(outbox.first.newVersion, 1);
      expect(outbox.last.operation, 'UPDATE');
      expect(outbox.last.baseVersion, 1);
      expect(outbox.last.newVersion, 2);
      expect(jsonDecode(outbox.first.payload), {
        'id': noteId.value,
        'entityType': 'note',
        'title': 'Note title',
        'content': '  exact\r\ncontent  ',
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': createdAt.toIso8601String(),
        'lifecycle': 'active',
        'version': 1,
        'source': 'user',
      });
      expect(
        jsonDecode(outbox.last.payload),
        containsPair('content', 'edited content'),
      );
    },
  );

  test('returns Notes in updatedAt DESC then id ASC order', () async {
    final older = createNote(
      id: const LifeOsEntityId(
        value: 'note-c',
        entityType: LifeOsEntityType.note,
      ),
      timestamp: DateTime.utc(2026, 9, 12, 9),
    );
    final tiedB = createNote(
      id: const LifeOsEntityId(
        value: 'note-b',
        entityType: LifeOsEntityType.note,
      ),
    );
    final tiedA = createNote(
      id: const LifeOsEntityId(
        value: 'note-a',
        entityType: LifeOsEntityType.note,
      ),
    );
    for (final note in [older, tiedB, tiedA]) {
      await repository.save(note);
    }

    expect(await repository.getAll(), [tiedA, tiedB, older]);
    expect(
      await repository.getById(
        const LifeOsEntityId(
          value: 'note-a',
          entityType: LifeOsEntityType.task,
        ),
      ),
      isNull,
    );
  });

  test('persists Note delete and restore with typed lifecycle reads', () async {
    final note = createNote();
    await repository.save(note);

    final deleted = await DeleteLifeOsNote(
      repository: repository,
      utcClock: () => DateTime.utc(2026, 9, 12, 11),
    )(noteId);

    expect(await repository.getAll(), [deleted]);
    expect(
      await repository.getByLifecycle(LifeOsEntityLifecycle.active),
      isEmpty,
    );
    expect(await repository.getByLifecycle(LifeOsEntityLifecycle.deleted), [
      deleted,
    ]);
    final deleteChange =
        (await database.select(database.outboxEntries).get()).last;
    expect(deleteChange.operation, 'UPDATE');
    expect(deleteChange.baseVersion, 1);
    expect(deleteChange.newVersion, 2);
    expect(
      jsonDecode(deleteChange.payload),
      containsPair('lifecycle', 'deleted'),
    );

    final restored = await RestoreLifeOsNote(
      repository: repository,
      utcClock: () => DateTime.utc(2026, 9, 12, 12),
    )(noteId);
    expect(await repository.getByLifecycle(LifeOsEntityLifecycle.active), [
      restored,
    ]);
    final changes = await database.select(database.outboxEntries).get();
    expect(changes, hasLength(3));
    expect(changes.last.operation, 'UPDATE');
    expect(changes.last.baseVersion, 2);
    expect(changes.last.newVersion, 3);
    expect(
      jsonDecode(changes.last.payload),
      containsPair('lifecycle', 'active'),
    );
  });

  test('rejects cross-type ID collisions without mutation', () async {
    final taskRepository = DriftLifeOsTaskRepository(
      database,
      () => 'task-change',
      'device-test',
    );
    const collidingValue = 'shared-id';
    final task = LifeOsTask.createUserTask(
      id: const LifeOsEntityId(
        value: collidingValue,
        entityType: LifeOsEntityType.task,
      ),
      title: 'Existing Task',
      timestamp: createdAt,
    );
    await taskRepository.save(task);
    final outboxBefore = await database.select(database.outboxEntries).get();
    final note = createNote(
      id: const LifeOsEntityId(
        value: collidingValue,
        entityType: LifeOsEntityType.note,
      ),
    );

    await expectLater(
      repository.save(note),
      throwsA(isA<LifeOsNotePersistenceException>()),
    );

    expect(await taskRepository.getById(task.id), task);
    expect(await database.select(database.noteRecords).get(), isEmpty);
    expect(await database.select(database.outboxEntries).get(), outboxBefore);
  });

  test('reports an Entity without its typed Note record', () async {
    await database
        .into(database.entities)
        .insert(
          EntitiesCompanion.insert(
            id: noteId.value,
            entityType: LifeOsEntityType.note.name,
            createdAt: createdAt,
            updatedAt: createdAt,
            lifecycle: LifeOsEntityLifecycle.active.name,
            version: 1,
            source: LifeOsEntitySource.user.name,
          ),
        );

    await expectLater(
      repository.getById(noteId),
      throwsA(isA<LifeOsNotePersistenceException>()),
    );
  });

  test(
    'reports persisted Note state that violates Domain invariants',
    () async {
      await database
          .into(database.entities)
          .insert(
            EntitiesCompanion.insert(
              id: noteId.value,
              entityType: LifeOsEntityType.note.name,
              createdAt: createdAt,
              updatedAt: createdAt,
              lifecycle: LifeOsEntityLifecycle.active.name,
              version: 0,
              source: LifeOsEntitySource.user.name,
            ),
          );
      await database
          .into(database.noteRecords)
          .insert(
            NoteRecordsCompanion.insert(
              entityId: noteId.value,
              title: 'Invalid version',
              content: '',
            ),
          );

      await expectLater(
        repository.getById(noteId),
        throwsA(isA<LifeOsNoteMappingException>()),
      );
    },
  );

  test('rolls back Note delete when the Outbox insert fails', () async {
    final original = createNote();
    await repository.save(original);
    final deleted = original.delete(updatedAt: DateTime.utc(2026, 9, 12, 11));
    final duplicateChangeRepository = DriftLifeOsNoteRepository(
      database,
      () => 'change-1',
      'device-test',
    );

    await expectLater(
      duplicateChangeRepository.save(deleted),
      throwsA(anything),
    );

    expect(await repository.getById(noteId), original);
    expect(await database.select(database.outboxEntries).get(), hasLength(1));
  });

  test('retains deleted Note state after closing and reopening', () async {
    final directory = await Directory.systemTemp.createTemp('lifeos-note-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}notes.db');
    await database.close();
    database = LifeOsDatabase(NativeDatabase(file));
    final fileChanges = ['file-create', 'file-delete'];
    final firstRepository = DriftLifeOsNoteRepository(
      database,
      () => fileChanges.removeAt(0),
      'device-test',
    );
    final note = createNote(content: 'persist exactly\n');
    await firstRepository.save(note);
    final deleted = await DeleteLifeOsNote(
      repository: firstRepository,
      utcClock: () => DateTime.utc(2026, 9, 12, 11),
    )(note.id);
    await database.close();

    database = LifeOsDatabase(NativeDatabase(file));
    final reopenedRepository = DriftLifeOsNoteRepository(
      database,
      () => 'unused',
      'device-test',
    );

    expect(await reopenedRepository.getById(note.id), deleted);
    expect(
      await reopenedRepository.getByLifecycle(LifeOsEntityLifecycle.active),
      isEmpty,
    );
    expect(
      await reopenedRepository.getByLifecycle(LifeOsEntityLifecycle.deleted),
      [deleted],
    );
    expect(await database.select(database.outboxEntries).get(), hasLength(2));
    await database.close();
  });
}
