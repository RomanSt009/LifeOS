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

  factory LifeOsTask.createUserTask({
    required LifeOsEntityId id,
    required String title,
    required DateTime timestamp,
  }) {
    final normalizedTitle = title.trim();
    if (id.entityType != LifeOsEntityType.task) {
      throw ArgumentError.value(id, 'id', 'A Task requires a Task entity ID.');
    }
    if (id.value.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'A Task entity ID cannot be empty.');
    }
    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'A Task title cannot be empty.',
      );
    }
    if (!timestamp.isUtc) {
      throw ArgumentError.value(
        timestamp,
        'timestamp',
        'A Task creation timestamp must be UTC.',
      );
    }

    return LifeOsTask(
      id: id,
      title: normalizedTitle,
      isCompleted: false,
      createdAt: timestamp,
      updatedAt: timestamp,
      lifecycle: LifeOsEntityLifecycle.active,
      version: 1,
      source: LifeOsEntitySource.user,
    );
  }

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

  LifeOsTask toggleCompletion({required DateTime updatedAt}) {
    return LifeOsTask(
      id: id,
      title: title,
      isCompleted: !isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lifecycle: lifecycle,
      version: version + 1,
      source: source,
    );
  }

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
