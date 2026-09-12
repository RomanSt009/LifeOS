import 'lifeos_entity.dart';

enum LifeOsRelationshipKind { related }

final class LifeOsRelationship implements LifeOsEntity {
  LifeOsRelationship({
    required this.id,
    required this.firstEntityId,
    required this.secondEntityId,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
    required this.lifecycle,
    required this.version,
    required this.source,
  }) {
    _validateIdentity(id);
    _validateEndpoint(firstEntityId, 'firstEntityId');
    _validateEndpoint(secondEntityId, 'secondEntityId');
    if (firstEntityId.value.compareTo(secondEntityId.value) >= 0) {
      throw ArgumentError(
        'Relationship endpoints must be distinct and canonically ordered.',
      );
    }
    _validateTimestamp(createdAt, 'createdAt');
    _validateTimestamp(updatedAt, 'updatedAt');
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'A Relationship update cannot precede its creation.',
      );
    }
    if (version < 1) {
      throw ArgumentError.value(
        version,
        'version',
        'Version must be positive.',
      );
    }
  }

  factory LifeOsRelationship.createUserRelationship({
    required LifeOsEntityId id,
    required LifeOsEntityId firstEndpoint,
    required LifeOsEntityId secondEndpoint,
    required DateTime timestamp,
  }) {
    _validateIdentity(id);
    _validateEndpoint(firstEndpoint, 'firstEndpoint');
    _validateEndpoint(secondEndpoint, 'secondEndpoint');
    _validateTimestamp(timestamp, 'timestamp');
    if (firstEndpoint.value == secondEndpoint.value) {
      throw ArgumentError('A Relationship cannot link an Entity to itself.');
    }
    final isCanonical = firstEndpoint.value.compareTo(secondEndpoint.value) < 0;
    return LifeOsRelationship(
      id: id,
      firstEntityId: isCanonical ? firstEndpoint : secondEndpoint,
      secondEntityId: isCanonical ? secondEndpoint : firstEndpoint,
      kind: LifeOsRelationshipKind.related,
      createdAt: timestamp,
      updatedAt: timestamp,
      lifecycle: LifeOsEntityLifecycle.active,
      version: 1,
      source: LifeOsEntitySource.user,
    );
  }

  @override
  final LifeOsEntityId id;
  final LifeOsEntityId firstEntityId;
  final LifeOsEntityId secondEntityId;
  final LifeOsRelationshipKind kind;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final LifeOsEntityLifecycle lifecycle;
  @override
  final int version;
  @override
  final LifeOsEntitySource source;

  @override
  LifeOsEntityType get entityType => LifeOsEntityType.relationship;

  LifeOsRelationship unlink({required DateTime updatedAt}) {
    _validateTimestamp(updatedAt, 'updatedAt');
    if (updatedAt.isBefore(this.updatedAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'A Relationship update timestamp cannot move backwards.',
      );
    }
    if (lifecycle != LifeOsEntityLifecycle.active) return this;
    return LifeOsRelationship(
      id: id,
      firstEntityId: firstEntityId,
      secondEntityId: secondEntityId,
      kind: kind,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lifecycle: LifeOsEntityLifecycle.deleted,
      version: version + 1,
      source: source,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LifeOsRelationship &&
          id == other.id &&
          firstEntityId == other.firstEntityId &&
          secondEntityId == other.secondEntityId &&
          kind == other.kind &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          lifecycle == other.lifecycle &&
          version == other.version &&
          source == other.source;

  @override
  int get hashCode => Object.hash(
    id,
    firstEntityId,
    secondEntityId,
    kind,
    createdAt,
    updatedAt,
    lifecycle,
    version,
    source,
  );
}

void _validateIdentity(LifeOsEntityId id) {
  if (id.entityType != LifeOsEntityType.relationship ||
      id.value.trim().isEmpty) {
    throw ArgumentError.value(id, 'id', 'Invalid Relationship identity.');
  }
}

void _validateEndpoint(LifeOsEntityId id, String name) {
  if (id.value.trim().isEmpty ||
      (id.entityType != LifeOsEntityType.task &&
          id.entityType != LifeOsEntityType.note)) {
    throw ArgumentError.value(id, name, 'Unsupported Relationship endpoint.');
  }
}

void _validateTimestamp(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'Timestamp must be UTC.');
  }
}
