import 'dart:convert';

import '../../../../domain/entities/lifeos_entity.dart';
import '../../../../domain/entities/lifeos_relationship.dart';
import '../lifeos_database.dart';

final class LifeOsRelationshipMappingException implements Exception {
  const LifeOsRelationshipMappingException(this.message);
  final String message;

  @override
  String toString() => 'LifeOsRelationshipMappingException: $message';
}

abstract final class LifeOsRelationshipMapper {
  static LifeOsRelationship toDomain(
    EntityRecord entity,
    RelationshipRecord relationship,
    EntityRecord firstEndpoint,
    EntityRecord secondEndpoint,
  ) {
    if (entity.id != relationship.entityId ||
        entity.entityType != LifeOsEntityType.relationship.name ||
        firstEndpoint.id != relationship.firstEntityId ||
        secondEndpoint.id != relationship.secondEntityId) {
      throw const LifeOsRelationshipMappingException(
        'Relationship persistence records are inconsistent.',
      );
    }
    try {
      return LifeOsRelationship(
        id: LifeOsEntityId(
          value: entity.id,
          entityType: LifeOsEntityType.relationship,
        ),
        firstEntityId: LifeOsEntityId(
          value: firstEndpoint.id,
          entityType: LifeOsEntityType.values.byName(firstEndpoint.entityType),
        ),
        secondEntityId: LifeOsEntityId(
          value: secondEndpoint.id,
          entityType: LifeOsEntityType.values.byName(secondEndpoint.entityType),
        ),
        kind: LifeOsRelationshipKind.values.byName(relationship.kind),
        createdAt: entity.createdAt.toUtc(),
        updatedAt: entity.updatedAt.toUtc(),
        lifecycle: LifeOsEntityLifecycle.values.byName(entity.lifecycle),
        version: entity.version,
        source: LifeOsEntitySource.values.byName(entity.source),
      );
    } on Object {
      throw const LifeOsRelationshipMappingException(
        'The persisted Relationship violates the Domain contract.',
      );
    }
  }

  static String toJsonSnapshot(LifeOsRelationship relationship) => jsonEncode({
    'id': relationship.id.value,
    'entityType': relationship.entityType.name,
    'firstEntityId': relationship.firstEntityId.value,
    'secondEntityId': relationship.secondEntityId.value,
    'kind': relationship.kind.name,
    'createdAt': relationship.createdAt.toUtc().toIso8601String(),
    'updatedAt': relationship.updatedAt.toUtc().toIso8601String(),
    'lifecycle': relationship.lifecycle.name,
    'version': relationship.version,
    'source': relationship.source.name,
  });
}
