import '../entities/lifeos_entity.dart';
import '../entities/lifeos_relationship.dart';

abstract interface class LifeOsRelationshipRepository {
  Future<List<LifeOsRelationship>> getAll();
  Future<LifeOsRelationship?> getById(LifeOsEntityId id);
  Future<List<LifeOsRelationship>> getForEntity(LifeOsEntityId entityId);
  Future<void> save(LifeOsRelationship relationship);
}
