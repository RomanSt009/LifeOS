import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../domain/entities/lifeos_relationship.dart';
import '../../domain/entities/lifeos_task.dart';

sealed class LifeOsRelatedNeighbor {
  LifeOsRelatedNeighbor({
    required this.sourceId,
    required this.relationship,
    required LifeOsEntityId neighborId,
    required LifeOsEntityLifecycle neighborLifecycle,
  }) {
    if (!_isSupportedNode(sourceId) || !_isSupportedNode(neighborId)) {
      throw ArgumentError('Related neighbors support only Task and Note.');
    }
    if (relationship.lifecycle != LifeOsEntityLifecycle.active ||
        relationship.kind != LifeOsRelationshipKind.related ||
        neighborLifecycle != LifeOsEntityLifecycle.active) {
      throw ArgumentError(
        'A related-neighbor projection requires active related state.',
      );
    }
    final endpoints = {
      relationship.firstEntityId,
      relationship.secondEntityId,
    };
    if (sourceId == neighborId ||
        !endpoints.contains(sourceId) ||
        !endpoints.contains(neighborId)) {
      throw ArgumentError(
        'The source and neighbor must be opposite Relationship endpoints.',
      );
    }
  }

  final LifeOsEntityId sourceId;
  final LifeOsRelationship relationship;

  LifeOsEntityId get entityId;
}

final class LifeOsRelatedTaskNeighbor extends LifeOsRelatedNeighbor {
  LifeOsRelatedTaskNeighbor({
    required super.sourceId,
    required super.relationship,
    required this.task,
  }) : super(neighborId: task.id, neighborLifecycle: task.lifecycle);

  final LifeOsTask task;

  @override
  LifeOsEntityId get entityId => task.id;
}

final class LifeOsRelatedNoteNeighbor extends LifeOsRelatedNeighbor {
  LifeOsRelatedNoteNeighbor({
    required super.sourceId,
    required super.relationship,
    required this.note,
  }) : super(neighborId: note.id, neighborLifecycle: note.lifecycle);

  final LifeOsNote note;

  @override
  LifeOsEntityId get entityId => note.id;
}

abstract interface class LifeOsRelatedEntityReader {
  /// Returns at most [limit] direct active neighbors ordered by Relationship
  /// updatedAt descending and then Relationship ID ascending.
  ///
  /// Implementations throw [LifeOsRelatedEntityQueryException] when [sourceId]
  /// does not identify an active persisted Task or Note.
  Future<List<LifeOsRelatedNeighbor>> getDirectNeighbors({
    required LifeOsEntityId sourceId,
    required int limit,
  });
}

enum LifeOsRelatedEntityQueryError {
  unsupportedSourceType,
  invalidLimit,
  sourceNotFound,
  sourceInactive,
}

final class LifeOsRelatedEntityQueryException implements Exception {
  const LifeOsRelatedEntityQueryException({
    required this.error,
    required this.sourceId,
  });

  final LifeOsRelatedEntityQueryError error;
  final LifeOsEntityId sourceId;
}

bool _isSupportedNode(LifeOsEntityId id) =>
    id.entityType == LifeOsEntityType.task ||
    id.entityType == LifeOsEntityType.note;
