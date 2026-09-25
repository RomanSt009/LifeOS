import 'package:drift/drift.dart';

import '../../../../application/relationships/lifeos_related_entity_reader.dart';
import '../../../../domain/entities/lifeos_entity.dart';
import '../lifeos_database.dart';
import '../mappers/lifeos_note_mapper.dart';
import '../mappers/lifeos_relationship_mapper.dart';
import '../mappers/lifeos_task_mapper.dart';

final class LifeOsRelatedEntityPersistenceException implements Exception {
  const LifeOsRelatedEntityPersistenceException(this.message);

  final String message;

  @override
  String toString() => 'LifeOsRelatedEntityPersistenceException: $message';
}

final class DriftLifeOsRelatedEntityReader
    implements LifeOsRelatedEntityReader {
  const DriftLifeOsRelatedEntityReader(this._database);

  final LifeOsDatabase _database;

  @override
  Future<List<LifeOsRelatedNeighbor>> getDirectNeighbors({
    required LifeOsEntityId sourceId,
    required int limit,
  }) async {
    if (!_isSupportedType(sourceId.entityType)) {
      throw LifeOsRelatedEntityQueryException(
        error: LifeOsRelatedEntityQueryError.unsupportedSourceType,
        sourceId: sourceId,
      );
    }
    if (limit <= 0) {
      throw LifeOsRelatedEntityQueryException(
        error: LifeOsRelatedEntityQueryError.invalidLimit,
        sourceId: sourceId,
      );
    }

    await _requireActiveSource(sourceId);

    final relationshipEntities = _database.alias(
      _database.entities,
      'related_relationship_entities',
    );
    final firstEntities = _database.alias(
      _database.entities,
      'related_first_entities',
    );
    final secondEntities = _database.alias(
      _database.entities,
      'related_second_entities',
    );
    final firstTasks = _database.alias(
      _database.taskRecords,
      'related_first_tasks',
    );
    final secondTasks = _database.alias(
      _database.taskRecords,
      'related_second_tasks',
    );
    final firstNotes = _database.alias(
      _database.noteRecords,
      'related_first_notes',
    );
    final secondNotes = _database.alias(
      _database.noteRecords,
      'related_second_notes',
    );

    final query =
        _database.select(_database.relationshipRecords).join([
            innerJoin(
              relationshipEntities,
              relationshipEntities.id.equalsExp(
                _database.relationshipRecords.entityId,
              ),
            ),
            innerJoin(
              firstEntities,
              firstEntities.id.equalsExp(
                _database.relationshipRecords.firstEntityId,
              ),
            ),
            innerJoin(
              secondEntities,
              secondEntities.id.equalsExp(
                _database.relationshipRecords.secondEntityId,
              ),
            ),
            leftOuterJoin(
              firstTasks,
              firstTasks.entityId.equalsExp(firstEntities.id),
            ),
            leftOuterJoin(
              secondTasks,
              secondTasks.entityId.equalsExp(secondEntities.id),
            ),
            leftOuterJoin(
              firstNotes,
              firstNotes.entityId.equalsExp(firstEntities.id),
            ),
            leftOuterJoin(
              secondNotes,
              secondNotes.entityId.equalsExp(secondEntities.id),
            ),
          ])
          ..where(
            (_database.relationshipRecords.firstEntityId.equals(
                      sourceId.value,
                    ) |
                    _database.relationshipRecords.secondEntityId.equals(
                      sourceId.value,
                    )) &
                relationshipEntities.entityType.equals(
                  LifeOsEntityType.relationship.name,
                ) &
                relationshipEntities.lifecycle.equals(
                  LifeOsEntityLifecycle.active.name,
                ) &
                _database.relationshipRecords.kind.equals('related') &
                firstEntities.lifecycle.equals(
                  LifeOsEntityLifecycle.active.name,
                ) &
                secondEntities.lifecycle.equals(
                  LifeOsEntityLifecycle.active.name,
                ),
          )
          ..orderBy([
            OrderingTerm.desc(relationshipEntities.updatedAt),
            OrderingTerm.asc(relationshipEntities.id),
          ])
          ..limit(limit);

    final values = <LifeOsRelatedNeighbor>[];
    for (final row in await query.get()) {
      final typedRelationship = row.readTable(_database.relationshipRecords);
      final firstEntity = row.readTable(firstEntities);
      final secondEntity = row.readTable(secondEntities);
      final relationship = LifeOsRelationshipMapper.toDomain(
        row.readTable(relationshipEntities),
        typedRelationship,
        firstEntity,
        secondEntity,
      );
      final neighborIsFirst =
          typedRelationship.secondEntityId == sourceId.value;
      final neighborEntity = neighborIsFirst ? firstEntity : secondEntity;

      switch (LifeOsEntityType.values.byName(neighborEntity.entityType)) {
        case LifeOsEntityType.task:
          final task = row.readTableOrNull(
            neighborIsFirst ? firstTasks : secondTasks,
          );
          if (task == null) throw _corruptNeighbor();
          values.add(
            LifeOsRelatedTaskNeighbor(
              sourceId: sourceId,
              relationship: relationship,
              task: LifeOsTaskMapper.toDomain(neighborEntity, task),
            ),
          );
        case LifeOsEntityType.note:
          final note = row.readTableOrNull(
            neighborIsFirst ? firstNotes : secondNotes,
          );
          if (note == null) throw _corruptNeighbor();
          values.add(
            LifeOsRelatedNoteNeighbor(
              sourceId: sourceId,
              relationship: relationship,
              note: LifeOsNoteMapper.toDomain(neighborEntity, note),
            ),
          );
        case LifeOsEntityType.relationship:
        case LifeOsEntityType.workspace:
        case LifeOsEntityType.workspaceMembership:
          throw _corruptNeighbor();
      }
    }
    return List.unmodifiable(values);
  }

  Future<void> _requireActiveSource(LifeOsEntityId sourceId) async {
    final sourceTask = _database.alias(
      _database.taskRecords,
      'related_source_task',
    );
    final sourceNote = _database.alias(
      _database.noteRecords,
      'related_source_note',
    );
    final query = _database.select(_database.entities).join([
      leftOuterJoin(
        sourceTask,
        sourceTask.entityId.equalsExp(_database.entities.id),
      ),
      leftOuterJoin(
        sourceNote,
        sourceNote.entityId.equalsExp(_database.entities.id),
      ),
    ])..where(_database.entities.id.equals(sourceId.value));
    final row = await query.getSingleOrNull();
    if (row == null) {
      throw LifeOsRelatedEntityQueryException(
        error: LifeOsRelatedEntityQueryError.sourceNotFound,
        sourceId: sourceId,
      );
    }

    final entity = row.readTable(_database.entities);
    if (entity.entityType != sourceId.entityType.name) {
      throw const LifeOsRelatedEntityPersistenceException(
        'The source Entity type is inconsistent with its typed identity.',
      );
    }
    if (entity.lifecycle != LifeOsEntityLifecycle.active.name) {
      throw LifeOsRelatedEntityQueryException(
        error: LifeOsRelatedEntityQueryError.sourceInactive,
        sourceId: sourceId,
      );
    }

    switch (sourceId.entityType) {
      case LifeOsEntityType.task:
        final task = row.readTableOrNull(sourceTask);
        if (task == null) throw _corruptSource();
        LifeOsTaskMapper.toDomain(entity, task);
      case LifeOsEntityType.note:
        final note = row.readTableOrNull(sourceNote);
        if (note == null) throw _corruptSource();
        LifeOsNoteMapper.toDomain(entity, note);
      case LifeOsEntityType.relationship:
      case LifeOsEntityType.workspace:
      case LifeOsEntityType.workspaceMembership:
        throw LifeOsRelatedEntityQueryException(
          error: LifeOsRelatedEntityQueryError.unsupportedSourceType,
          sourceId: sourceId,
        );
    }
  }
}

bool _isSupportedType(LifeOsEntityType type) =>
    type == LifeOsEntityType.task || type == LifeOsEntityType.note;

Never _corruptSource() => throw const LifeOsRelatedEntityPersistenceException(
  'The source Entity has no matching typed persistence record.',
);

Never _corruptNeighbor() => throw const LifeOsRelatedEntityPersistenceException(
  'A related neighbor violates the Task/Note persistence contract.',
);
