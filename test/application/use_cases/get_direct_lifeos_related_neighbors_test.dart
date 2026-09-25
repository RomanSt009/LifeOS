import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/relationships/lifeos_related_entity_reader.dart';
import 'package:lifeos/application/use_cases/get_direct_lifeos_related_neighbors.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_relationship.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';

void main() {
  final timestamp = DateTime.utc(2026, 9, 25, 10);
  const taskId = LifeOsEntityId(
    value: 'task-a',
    entityType: LifeOsEntityType.task,
  );
  const noteId = LifeOsEntityId(
    value: 'note-a',
    entityType: LifeOsEntityType.note,
  );

  test('typed variants expose neighbor identity and Relationship provenance', () {
    final relationship = _relationship(taskId, noteId, timestamp);
    final taskNeighbor = LifeOsRelatedTaskNeighbor(
      sourceId: noteId,
      relationship: relationship,
      task: _task(taskId, timestamp),
    );
    final noteNeighbor = LifeOsRelatedNoteNeighbor(
      sourceId: taskId,
      relationship: relationship,
      note: _note(noteId, timestamp),
    );

    expect(taskNeighbor.entityId, taskId);
    expect(taskNeighbor.task.title, 'Task');
    expect(noteNeighbor.entityId, noteId);
    expect(noteNeighbor.note.title, 'Note');
    expect(taskNeighbor.relationship, same(relationship));
    expect(noteNeighbor.relationship.id, relationship.id);
  });

  test('projection rejects unsupported, inactive, and unrelated state', () {
    final relationship = _relationship(taskId, noteId, timestamp);
    expect(
      () => LifeOsRelatedTaskNeighbor(
        sourceId: const LifeOsEntityId(
          value: 'workspace-a',
          entityType: LifeOsEntityType.workspace,
        ),
        relationship: relationship,
        task: _task(taskId, timestamp),
      ),
      throwsArgumentError,
    );
    expect(
      () => LifeOsRelatedNoteNeighbor(
        sourceId: taskId,
        relationship: relationship,
        note: _note(
          noteId,
          timestamp,
          lifecycle: LifeOsEntityLifecycle.deleted,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => LifeOsRelatedNoteNeighbor(
        sourceId: const LifeOsEntityId(
          value: 'task-b',
          entityType: LifeOsEntityType.task,
        ),
        relationship: relationship,
        note: _note(noteId, timestamp),
      ),
      throwsArgumentError,
    );
  });

  test('valid Task and Note sources delegate the required positive limit', () async {
    final relationship = _relationship(taskId, noteId, timestamp);
    final values = [
      LifeOsRelatedNoteNeighbor(
        sourceId: taskId,
        relationship: relationship,
        note: _note(noteId, timestamp),
      ),
    ];
    final reader = _Reader(values);
    final getNeighbors = GetDirectLifeOsRelatedNeighbors(reader);

    expect(await getNeighbors(sourceId: taskId, limit: 7), same(values));
    expect(reader.sourceId, taskId);
    expect(reader.limit, 7);

    reader.values = [
      LifeOsRelatedTaskNeighbor(
        sourceId: noteId,
        relationship: relationship,
        task: _task(taskId, timestamp),
      ),
    ];
    expect(await getNeighbors(sourceId: noteId, limit: 3), same(reader.values));
    expect(reader.sourceId, noteId);
    expect(reader.limit, 3);
  });

  test('zero and negative limits are rejected before the reader', () {
    final reader = _Reader(const []);
    final getNeighbors = GetDirectLifeOsRelatedNeighbors(reader);

    for (final limit in [0, -1]) {
      expect(
        () => getNeighbors(sourceId: taskId, limit: limit),
        throwsA(
          isA<LifeOsRelatedEntityQueryException>().having(
            (error) => error.error,
            'error',
            LifeOsRelatedEntityQueryError.invalidLimit,
          ),
        ),
      );
    }
    expect(reader.calls, 0);
  });

  test('unsupported source types are rejected before the reader', () {
    final reader = _Reader(const []);
    final getNeighbors = GetDirectLifeOsRelatedNeighbors(reader);
    const relationshipId = LifeOsEntityId(
      value: 'relationship-source',
      entityType: LifeOsEntityType.relationship,
    );

    expect(
      () => getNeighbors(sourceId: relationshipId, limit: 1),
      throwsA(
        isA<LifeOsRelatedEntityQueryException>().having(
          (error) => error.error,
          'error',
          LifeOsRelatedEntityQueryError.unsupportedSourceType,
        ),
      ),
    );
    expect(reader.calls, 0);
  });

  test('port order is preserved and the use case has no mutation behavior', () async {
    final newer = _relationship(
      taskId,
      noteId,
      timestamp.add(const Duration(hours: 1)),
      id: 'relationship-newer',
    );
    const olderNoteId = LifeOsEntityId(
      value: 'note-b',
      entityType: LifeOsEntityType.note,
    );
    final older = _relationship(
      taskId,
      olderNoteId,
      timestamp,
      id: 'relationship-older',
    );
    final values = [
      LifeOsRelatedNoteNeighbor(
        sourceId: taskId,
        relationship: newer,
        note: _note(noteId, timestamp),
      ),
      LifeOsRelatedNoteNeighbor(
        sourceId: taskId,
        relationship: older,
        note: _note(olderNoteId, timestamp),
      ),
    ];
    final reader = _Reader(values);

    final result = await GetDirectLifeOsRelatedNeighbors(
      reader,
    )(sourceId: taskId, limit: 2);

    expect(result, same(values));
    expect(result.map((item) => item.relationship.id.value), [
      'relationship-newer',
      'relationship-older',
    ]);
    expect(reader.calls, 1);
  });

  test('typed missing and inactive source failures pass through unchanged', () async {
    for (final error in [
      LifeOsRelatedEntityQueryError.sourceNotFound,
      LifeOsRelatedEntityQueryError.sourceInactive,
    ]) {
      final reader = _Reader(
        const [],
        failure: LifeOsRelatedEntityQueryException(
          error: error,
          sourceId: taskId,
        ),
      );
      await expectLater(
        GetDirectLifeOsRelatedNeighbors(
          reader,
        )(sourceId: taskId, limit: 1),
        throwsA(
          isA<LifeOsRelatedEntityQueryException>().having(
            (value) => value.error,
            'error',
            error,
          ),
        ),
      );
    }
  });
}

final class _Reader implements LifeOsRelatedEntityReader {
  _Reader(this.values, {this.failure});

  List<LifeOsRelatedNeighbor> values;
  final LifeOsRelatedEntityQueryException? failure;
  LifeOsEntityId? sourceId;
  int? limit;
  int calls = 0;

  @override
  Future<List<LifeOsRelatedNeighbor>> getDirectNeighbors({
    required LifeOsEntityId sourceId,
    required int limit,
  }) async {
    calls++;
    this.sourceId = sourceId;
    this.limit = limit;
    final failure = this.failure;
    if (failure != null) throw failure;
    return values;
  }
}

LifeOsTask _task(
  LifeOsEntityId id,
  DateTime timestamp, {
  LifeOsEntityLifecycle lifecycle = LifeOsEntityLifecycle.active,
}) => LifeOsTask(
  id: id,
  title: 'Task',
  isCompleted: false,
  createdAt: timestamp,
  updatedAt: timestamp,
  lifecycle: lifecycle,
  version: 1,
  source: LifeOsEntitySource.user,
);

LifeOsNote _note(
  LifeOsEntityId id,
  DateTime timestamp, {
  LifeOsEntityLifecycle lifecycle = LifeOsEntityLifecycle.active,
}) => LifeOsNote(
  id: id,
  title: 'Note',
  content: '',
  createdAt: timestamp,
  updatedAt: timestamp,
  lifecycle: lifecycle,
  version: 1,
  source: LifeOsEntitySource.user,
);

LifeOsRelationship _relationship(
  LifeOsEntityId first,
  LifeOsEntityId second,
  DateTime timestamp, {
  String id = 'relationship-a',
}) => LifeOsRelationship.createUserRelationship(
  id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.relationship),
  firstEndpoint: first,
  secondEndpoint: second,
  timestamp: timestamp,
);
