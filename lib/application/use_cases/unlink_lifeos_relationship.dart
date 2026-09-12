import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_relationship.dart';
import '../../domain/repositories/lifeos_relationship_repository.dart';
import 'create_lifeos_task.dart' show UtcClock;

class UnlinkLifeOsRelationship {
  const UnlinkLifeOsRelationship({
    required this.repository,
    required this.utcClock,
  });

  final LifeOsRelationshipRepository repository;
  final UtcClock utcClock;

  Future<LifeOsRelationship?> call(LifeOsEntityId id) async {
    final current = await repository.getById(id);
    if (current == null) return null;
    final unlinked = current.unlink(updatedAt: utcClock());
    if (!identical(unlinked, current)) {
      await repository.save(unlinked);
    }
    return unlinked;
  }
}
