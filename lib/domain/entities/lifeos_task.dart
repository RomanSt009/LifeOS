import 'lifeos_entity.dart';

class LifeOsTask implements LifeOsEntity {
  const LifeOsTask({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.lifecycle,
    required this.version,
    required this.source,
  });

  @override
  final LifeOsEntityId id;

  final String title;
  final bool isCompleted;

  @override
  LifeOsEntityType get entityType => LifeOsEntityType.task;

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
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LifeOsTask &&
            id == other.id &&
            title == other.title &&
            isCompleted == other.isCompleted &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt &&
            lifecycle == other.lifecycle &&
            version == other.version &&
            source == other.source;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    isCompleted,
    createdAt,
    updatedAt,
    lifecycle,
    version,
    source,
  );
}
