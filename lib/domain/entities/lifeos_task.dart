import 'lifeos_entity.dart';

class LifeOsTask implements LifeOsEntity {
  LifeOsTask({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.lifecycle,
    required this.version,
    required this.source,
  }) {
    _validateIdentity(id);
    _validateUtc(createdAt, 'createdAt');
    _validateUtc(updatedAt, 'updatedAt');
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'A Task update timestamp cannot precede its creation timestamp.',
      );
    }
    if (version < 1) {
      throw ArgumentError.value(
        version,
        'version',
        'A Task version must be positive.',
      );
    }
    if (title != title.trim()) {
      throw ArgumentError.value(
        title,
        'title',
        'A hydrated Task title must already be normalized.',
      );
    }
    _validateTitle(title);
  }

  factory LifeOsTask.createUserTask({
    required LifeOsEntityId id,
    required String title,
    required DateTime timestamp,
  }) {
    final normalizedTitle = title.trim();
    _validateIdentity(id);
    _validateTitle(normalizedTitle);
    _validateUtc(timestamp, 'timestamp');

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

  LifeOsTask editTitle({required String title, required DateTime updatedAt}) {
    final normalizedTitle = title.trim();
    _validateUtc(updatedAt, 'updatedAt');
    if (updatedAt.isBefore(this.updatedAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'A Task update timestamp cannot move backwards.',
      );
    }
    _validateTitle(normalizedTitle);
    if (lifecycle != LifeOsEntityLifecycle.active) {
      throw StateError('Only an active Task can be edited.');
    }
    if (normalizedTitle == this.title) {
      return this;
    }

    return LifeOsTask(
      id: id,
      title: normalizedTitle,
      isCompleted: isCompleted,
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

void _validateIdentity(LifeOsEntityId id) {
  if (id.entityType != LifeOsEntityType.task) {
    throw ArgumentError.value(id, 'id', 'A Task requires a Task entity ID.');
  }
  if (id.value.trim().isEmpty) {
    throw ArgumentError.value(id, 'id', 'A Task entity ID cannot be empty.');
  }
}

void _validateTitle(String title) {
  if (title.isEmpty) {
    throw ArgumentError.value(title, 'title', 'A Task title cannot be empty.');
  }
}

void _validateUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'A Task timestamp must be UTC.');
  }
}
