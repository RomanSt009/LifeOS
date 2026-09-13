import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/delete_lifeos_note.dart';
import 'package:lifeos/application/use_cases/delete_lifeos_task.dart';
import 'package:lifeos/application/use_cases/restore_lifeos_note.dart';
import 'package:lifeos/application/use_cases/restore_lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_note_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';

void main() {
  final createdAt = DateTime.utc(2026, 9, 13, 10);
  final changedAt = DateTime.utc(2026, 9, 13, 11);

  test(
    'Task delete and restore coordinate Domain and repository once',
    () async {
      final original = LifeOsTask.createUserTask(
        id: const LifeOsEntityId(
          value: 'task-1',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Lifecycle Task',
        timestamp: createdAt,
      );
      final repository = _TaskRepository(original);

      final deleted = await DeleteLifeOsTask(
        repository: repository,
        utcClock: () => changedAt,
      )(original.id);
      final restored = await RestoreLifeOsTask(
        repository: repository,
        utcClock: () => changedAt.add(const Duration(hours: 1)),
      )(original.id);

      expect(deleted!.lifecycle, LifeOsEntityLifecycle.deleted);
      expect(restored!.lifecycle, LifeOsEntityLifecycle.active);
      expect(repository.saveCount, 2);
      expect(repository.value, restored);
    },
  );

  test(
    'Note delete and restore coordinate Domain and repository once',
    () async {
      final original = LifeOsNote.createUserNote(
        id: const LifeOsEntityId(
          value: 'note-1',
          entityType: LifeOsEntityType.note,
        ),
        title: 'Lifecycle Note',
        content: 'Body',
        timestamp: createdAt,
      );
      final repository = _NoteRepository(original);

      final deleted = await DeleteLifeOsNote(
        repository: repository,
        utcClock: () => changedAt,
      )(original.id);
      final restored = await RestoreLifeOsNote(
        repository: repository,
        utcClock: () => changedAt.add(const Duration(hours: 1)),
      )(original.id);

      expect(deleted!.lifecycle, LifeOsEntityLifecycle.deleted);
      expect(restored!.lifecycle, LifeOsEntityLifecycle.active);
      expect(repository.saveCount, 2);
      expect(repository.value, restored);
    },
  );

  test('missing and lifecycle no-op results never save', () async {
    final activeTask = LifeOsTask.createUserTask(
      id: const LifeOsEntityId(
        value: 'task-1',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Active Task',
      timestamp: createdAt,
    );
    final taskRepository = _TaskRepository(activeTask);
    final activeNote = LifeOsNote.createUserNote(
      id: const LifeOsEntityId(
        value: 'note-1',
        entityType: LifeOsEntityType.note,
      ),
      title: 'Active Note',
      content: '',
      timestamp: createdAt,
    );
    final noteRepository = _NoteRepository(activeNote);

    expect(
      await RestoreLifeOsTask(
        repository: taskRepository,
        utcClock: () => changedAt,
      )(activeTask.id),
      same(activeTask),
    );
    expect(taskRepository.saveCount, 0);
    taskRepository.value = activeTask.delete(updatedAt: changedAt);
    expect(
      await DeleteLifeOsTask(
        repository: taskRepository,
        utcClock: () => changedAt.add(const Duration(hours: 1)),
      )(activeTask.id),
      same(taskRepository.value),
    );
    expect(taskRepository.saveCount, 0);
    expect(
      await RestoreLifeOsNote(
        repository: noteRepository,
        utcClock: () => changedAt,
      )(activeNote.id),
      same(activeNote),
    );
    expect(noteRepository.saveCount, 0);
    noteRepository.value = null;
    expect(
      await DeleteLifeOsNote(
        repository: noteRepository,
        utcClock: () => changedAt,
      )(
        const LifeOsEntityId(
          value: 'missing',
          entityType: LifeOsEntityType.note,
        ),
      ),
      isNull,
    );
    expect(noteRepository.saveCount, 0);
  });

  test('invalid Domain transitions propagate without saving', () async {
    final archived = LifeOsTask.createUserTask(
      id: const LifeOsEntityId(
        value: 'task-archived',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Archived Task',
      timestamp: createdAt,
    ).archive(updatedAt: changedAt);
    final repository = _TaskRepository(archived);

    await expectLater(
      RestoreLifeOsTask(
        repository: repository,
        utcClock: () => changedAt.add(const Duration(hours: 1)),
      )(archived.id),
      throwsStateError,
    );
    expect(repository.saveCount, 0);
  });
}

class _TaskRepository implements LifeOsTaskRepository {
  _TaskRepository(this.value);

  LifeOsTask? value;
  int saveCount = 0;

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async => value;

  @override
  Future<List<LifeOsTask>> getAll() async => [?value];

  @override
  Future<List<LifeOsTask>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async => [if (value?.lifecycle == lifecycle) value!];

  @override
  Future<List<LifeOsTask>> searchByTitle(String normalizedQuery) async => [];

  @override
  Future<void> save(LifeOsTask task) async {
    saveCount += 1;
    value = task;
  }
}

class _NoteRepository implements LifeOsNoteRepository {
  _NoteRepository(this.value);

  LifeOsNote? value;
  int saveCount = 0;

  @override
  Future<LifeOsNote?> getById(LifeOsEntityId id) async => value;

  @override
  Future<List<LifeOsNote>> getAll() async => [?value];

  @override
  Future<List<LifeOsNote>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async => [if (value?.lifecycle == lifecycle) value!];

  @override
  Future<void> save(LifeOsNote note) async {
    saveCount += 1;
    value = note;
  }
}
