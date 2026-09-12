import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_relationship.dart';
import '../../domain/repositories/lifeos_note_repository.dart';
import '../../domain/repositories/lifeos_relationship_repository.dart';
import '../../domain/repositories/lifeos_task_repository.dart';
import 'create_lifeos_task.dart' show EntityIdGenerator, UtcClock;

class CreateLifeOsRelationship {
  const CreateLifeOsRelationship({
    required this.relationshipRepository,
    required this.taskRepository,
    required this.noteRepository,
    required this.entityIdGenerator,
    required this.utcClock,
  });

  final LifeOsRelationshipRepository relationshipRepository;
  final LifeOsTaskRepository taskRepository;
  final LifeOsNoteRepository noteRepository;
  final EntityIdGenerator entityIdGenerator;
  final UtcClock utcClock;

  Future<LifeOsRelationship> call(
    LifeOsEntityId firstEndpoint,
    LifeOsEntityId secondEndpoint,
  ) async {
    await _requireEndpoint(firstEndpoint);
    await _requireEndpoint(secondEndpoint);

    final existing = await relationshipRepository.getForEntity(firstEndpoint);
    for (final relationship in existing) {
      final samePair =
          (relationship.firstEntityId == firstEndpoint &&
              relationship.secondEntityId == secondEndpoint) ||
          (relationship.firstEntityId == secondEndpoint &&
              relationship.secondEntityId == firstEndpoint);
      if (samePair && relationship.kind == LifeOsRelationshipKind.related) {
        return relationship;
      }
    }

    final relationship = LifeOsRelationship.createUserRelationship(
      id: LifeOsEntityId(
        value: entityIdGenerator(),
        entityType: LifeOsEntityType.relationship,
      ),
      firstEndpoint: firstEndpoint,
      secondEndpoint: secondEndpoint,
      timestamp: utcClock(),
    );
    await relationshipRepository.save(relationship);
    return relationship;
  }

  Future<void> _requireEndpoint(LifeOsEntityId id) async {
    final exists = switch (id.entityType) {
      LifeOsEntityType.task => await taskRepository.getById(id) != null,
      LifeOsEntityType.note => await noteRepository.getById(id) != null,
      LifeOsEntityType.relationship => false,
    };
    if (!exists) {
      throw LifeOsRelationshipEndpointException(id);
    }
  }
}

final class LifeOsRelationshipEndpointException implements Exception {
  const LifeOsRelationshipEndpointException(this.endpointId);

  final LifeOsEntityId endpointId;
}
