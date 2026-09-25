import '../../domain/entities/lifeos_entity.dart';
import '../relationships/lifeos_related_entity_reader.dart';

final class GetDirectLifeOsRelatedNeighbors {
  const GetDirectLifeOsRelatedNeighbors(this._reader);

  final LifeOsRelatedEntityReader _reader;

  Future<List<LifeOsRelatedNeighbor>> call({
    required LifeOsEntityId sourceId,
    required int limit,
  }) {
    if (sourceId.entityType != LifeOsEntityType.task &&
        sourceId.entityType != LifeOsEntityType.note) {
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
    return _reader.getDirectNeighbors(sourceId: sourceId, limit: limit);
  }
}
