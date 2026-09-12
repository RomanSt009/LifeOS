import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/create_lifeos_relationship.dart';
import 'package:lifeos/application/use_cases/get_lifeos_relationships.dart';
import 'package:lifeos/application/use_cases/unlink_lifeos_relationship.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_relationship.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_note_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_relationship_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';

void main() {
  final timestamp = DateTime.utc(2026, 9, 12, 12);

  test('creates Task-Task, Task-Note, and Note-Note relationships', () async {
    final tasks = _TaskRepository([_task('task-a'), _task('task-b')]);
    final notes = _NoteRepository([_note('note-a'), _note('note-b')]);
    final relationships = _RelationshipRepository();
    var sequence = 0;
    final create = CreateLifeOsRelationship(
      relationshipRepository: relationships,
      taskRepository: tasks,
      noteRepository: notes,
      entityIdGenerator: () => 'relationship-${++sequence}',
      utcClock: () => timestamp,
    );

    await create(tasks.items[0].id, tasks.items[1].id);
    await create(tasks.items[0].id, notes.items[0].id);
    await create(notes.items[0].id, notes.items[1].id);

    expect(relationships.saved, hasLength(3));
    expect(relationships.saved.every((item) => item.version == 1), isTrue);
  });

  test('rejects missing and unsupported endpoints before save', () async {
    final relationships = _RelationshipRepository();
    final create = CreateLifeOsRelationship(
      relationshipRepository: relationships,
      taskRepository: _TaskRepository([_task('task-a')]),
      noteRepository: _NoteRepository([]),
      entityIdGenerator: () => 'relationship-a',
      utcClock: () => timestamp,
    );

    await expectLater(
      create(_taskId('task-a'), _noteId('missing')),
      throwsA(isA<LifeOsRelationshipEndpointException>()),
    );
    await expectLater(
      create(
        _taskId('task-a'),
        const LifeOsEntityId(
          value: 'relationship-x',
          entityType: LifeOsEntityType.relationship,
        ),
      ),
      throwsA(isA<LifeOsRelationshipEndpointException>()),
    );
    expect(relationships.saved, isEmpty);
  });

  test(
    'duplicate create returns existing relationship without saving',
    () async {
      final existing = _relationship(
        'relationship-a',
        _taskId('task-a'),
        _noteId('note-a'),
      );
      final relationships = _RelationshipRepository([existing]);
      final create = CreateLifeOsRelationship(
        relationshipRepository: relationships,
        taskRepository: _TaskRepository([_task('task-a')]),
        noteRepository: _NoteRepository([_note('note-a')]),
        entityIdGenerator: () => throw StateError('must not generate'),
        utcClock: () => timestamp,
      );

      expect(
        await create(_noteId('note-a'), _taskId('task-a')),
        same(existing),
      );
      expect(relationships.saved, isEmpty);
    },
  );

  test('gets relationships and persists one material unlink only', () async {
    final existing = _relationship(
      'relationship-a',
      _taskId('task-a'),
      _noteId('note-a'),
    );
    final relationships = _RelationshipRepository([existing]);

    expect(await GetLifeOsRelationships(relationships)(_taskId('task-a')), [
      existing,
    ]);
    final unlink = UnlinkLifeOsRelationship(
      repository: relationships,
      utcClock: () => timestamp.add(const Duration(hours: 1)),
    );
    final deleted = await unlink(existing.id);
    expect(deleted?.lifecycle, LifeOsEntityLifecycle.deleted);
    expect(relationships.saved, hasLength(1));

    await unlink(existing.id);
    expect(relationships.saved, hasLength(1));
  });
}

LifeOsTask _task(String id) => LifeOsTask(
  id: _taskId(id),
  title: id,
  isCompleted: false,
  createdAt: DateTime.utc(2026, 9, 12),
  updatedAt: DateTime.utc(2026, 9, 12),
  lifecycle: LifeOsEntityLifecycle.active,
  version: 1,
  source: LifeOsEntitySource.user,
);

LifeOsNote _note(String id) => LifeOsNote(
  id: _noteId(id),
  title: id,
  content: '',
  createdAt: DateTime.utc(2026, 9, 12),
  updatedAt: DateTime.utc(2026, 9, 12),
  lifecycle: LifeOsEntityLifecycle.active,
  version: 1,
  source: LifeOsEntitySource.user,
);

LifeOsRelationship _relationship(
  String id,
  LifeOsEntityId first,
  LifeOsEntityId second,
) => LifeOsRelationship.createUserRelationship(
  id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.relationship),
  firstEndpoint: first,
  secondEndpoint: second,
  timestamp: DateTime.utc(2026, 9, 12),
);

LifeOsEntityId _taskId(String value) =>
    LifeOsEntityId(value: value, entityType: LifeOsEntityType.task);
LifeOsEntityId _noteId(String value) =>
    LifeOsEntityId(value: value, entityType: LifeOsEntityType.note);

class _TaskRepository implements LifeOsTaskRepository {
  _TaskRepository(this.items);
  final List<LifeOsTask> items;
  @override
  Future<List<LifeOsTask>> getAll() async => List.of(items);
  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async =>
      items.where((item) => item.id == id).firstOrNull;
  @override
  Future<void> save(LifeOsTask task) async {}
  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async => [];
}

class _NoteRepository implements LifeOsNoteRepository {
  _NoteRepository(this.items);
  final List<LifeOsNote> items;
  @override
  Future<List<LifeOsNote>> getAll() async => List.of(items);
  @override
  Future<LifeOsNote?> getById(LifeOsEntityId id) async =>
      items.where((item) => item.id == id).firstOrNull;
  @override
  Future<void> save(LifeOsNote note) async {}
}

class _RelationshipRepository implements LifeOsRelationshipRepository {
  _RelationshipRepository([List<LifeOsRelationship>? items])
    : items = items ?? [];
  final List<LifeOsRelationship> items;
  final List<LifeOsRelationship> saved = [];
  @override
  Future<List<LifeOsRelationship>> getAll() async => List.of(items);
  @override
  Future<LifeOsRelationship?> getById(LifeOsEntityId id) async =>
      items.where((item) => item.id == id).firstOrNull;
  @override
  Future<List<LifeOsRelationship>> getForEntity(
    LifeOsEntityId entityId,
  ) async => items
      .where(
        (item) =>
            item.lifecycle == LifeOsEntityLifecycle.active &&
            (item.firstEntityId == entityId || item.secondEntityId == entityId),
      )
      .toList();
  @override
  Future<void> save(LifeOsRelationship relationship) async {
    saved.add(relationship);
    items.removeWhere((item) => item.id == relationship.id);
    items.add(relationship);
  }
}
