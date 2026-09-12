enum LifeOsEntityType { task, note, relationship }

enum LifeOsEntityLifecycle { active, archived, deleted }

enum LifeOsEntitySource { user, ai, import, sync, system }

class LifeOsEntityId {
  const LifeOsEntityId({required this.value, required this.entityType});

  final String value;
  final LifeOsEntityType entityType;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LifeOsEntityId &&
            value == other.value &&
            entityType == other.entityType;
  }

  @override
  int get hashCode => Object.hash(value, entityType);
}

abstract interface class LifeOsEntity {
  LifeOsEntityId get id;
  LifeOsEntityType get entityType;
  DateTime get createdAt;
  DateTime get updatedAt;
  LifeOsEntityLifecycle get lifecycle;
  int get version;
  LifeOsEntitySource get source;
}
