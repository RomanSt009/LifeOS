import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/create_lifeos_relationship.dart';
import '../../application/use_cases/get_direct_lifeos_related_neighbors.dart';
import '../../application/use_cases/get_lifeos_relationships.dart';
import '../../application/use_cases/unlink_lifeos_relationship.dart';
import '../../application/relationships/lifeos_related_entity_reader.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_relationship.dart';
import '../../domain/repositories/lifeos_relationship_repository.dart';

final lifeOsRelationshipRepositoryProvider =
    Provider<LifeOsRelationshipRepository>((ref) {
      throw UnimplementedError(
        'lifeOsRelationshipRepositoryProvider must be overridden by app composition.',
      );
    });

final getLifeOsRelationshipsProvider = Provider<GetLifeOsRelationships>((ref) {
  return GetLifeOsRelationships(
    ref.watch(lifeOsRelationshipRepositoryProvider),
  );
});

final createLifeOsRelationshipProvider = Provider<CreateLifeOsRelationship>((
  ref,
) {
  throw UnimplementedError(
    'createLifeOsRelationshipProvider must be overridden by app composition.',
  );
});

final unlinkLifeOsRelationshipProvider = Provider<UnlinkLifeOsRelationship>((
  ref,
) {
  throw UnimplementedError(
    'unlinkLifeOsRelationshipProvider must be overridden by app composition.',
  );
});

final getDirectLifeOsRelatedNeighborsProvider =
    Provider<GetDirectLifeOsRelatedNeighbors>((ref) {
      throw UnimplementedError(
        'getDirectLifeOsRelatedNeighborsProvider must be overridden by app composition.',
      );
    });

const relatedEntitiesSectionLimit = 20;

final directLifeOsRelatedNeighborsProvider =
    FutureProvider.family<List<LifeOsRelatedNeighbor>, LifeOsEntityId>(
      (ref, entityId) => ref.watch(getDirectLifeOsRelatedNeighborsProvider)(
        sourceId: entityId,
        limit: relatedEntitiesSectionLimit,
      ),
    );

final relationshipsForEntityProvider =
    FutureProvider.family<List<LifeOsRelationship>, LifeOsEntityId>(
      (ref, entityId) => ref.watch(getLifeOsRelationshipsProvider)(entityId),
    );
