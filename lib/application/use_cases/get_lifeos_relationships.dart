import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_relationship.dart';
import '../../domain/repositories/lifeos_relationship_repository.dart';

class GetLifeOsRelationships {
  const GetLifeOsRelationships(this._repository);

  final LifeOsRelationshipRepository _repository;

  Future<List<LifeOsRelationship>> call(LifeOsEntityId entityId) =>
      _repository.getForEntity(entityId);
}
