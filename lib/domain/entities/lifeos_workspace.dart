import 'lifeos_entity.dart';

final class LifeOsWorkspace implements LifeOsEntity {
  LifeOsWorkspace({
    required this.id,
    required this.title,
    required this.description,
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
        'A Workspace update cannot precede its creation.',
      );
    }
    if (version < 1) {
      throw ArgumentError.value(
        version,
        'version',
        'Version must be positive.',
      );
    }
    if (title != title.trim()) {
      throw ArgumentError.value(
        title,
        'title',
        'A hydrated Workspace title must already be normalized.',
      );
    }
    _validateTitle(title);
  }

  factory LifeOsWorkspace.createUserWorkspace({
    required LifeOsEntityId id,
    required String title,
    required String? description,
    required DateTime timestamp,
  }) {
    final normalizedTitle = title.trim();
    _validateIdentity(id);
    _validateTitle(normalizedTitle);
    _validateUtc(timestamp, 'timestamp');
    return LifeOsWorkspace(
      id: id,
      title: normalizedTitle,
      description: description,
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
  final String? description;
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
  LifeOsEntityType get entityType => LifeOsEntityType.workspace;

  LifeOsWorkspace edit({
    required String title,
    required String? description,
    required DateTime updatedAt,
  }) {
    final normalizedTitle = title.trim();
    _validateMutationTimestamp(updatedAt);
    _validateTitle(normalizedTitle);
    if (lifecycle != LifeOsEntityLifecycle.active) {
      throw StateError('Only an active Workspace can be edited.');
    }
    if (normalizedTitle == this.title && description == this.description) {
      return this;
    }
    return _copy(
      title: normalizedTitle,
      description: description,
      updatedAt: updatedAt,
      lifecycle: lifecycle,
    );
  }

  LifeOsWorkspace archive({required DateTime updatedAt}) => _changeLifecycle(
    LifeOsEntityLifecycle.archived,
    LifeOsEntityLifecycle.active,
    updatedAt,
  );

  LifeOsWorkspace unarchive({required DateTime updatedAt}) => _changeLifecycle(
    LifeOsEntityLifecycle.active,
    LifeOsEntityLifecycle.archived,
    updatedAt,
  );

  LifeOsWorkspace delete({required DateTime updatedAt}) => _changeLifecycle(
    LifeOsEntityLifecycle.deleted,
    lifecycle == LifeOsEntityLifecycle.archived
        ? LifeOsEntityLifecycle.archived
        : LifeOsEntityLifecycle.active,
    updatedAt,
  );

  LifeOsWorkspace restore({required DateTime updatedAt}) => _changeLifecycle(
    LifeOsEntityLifecycle.active,
    LifeOsEntityLifecycle.deleted,
    updatedAt,
  );

  LifeOsWorkspace _changeLifecycle(
    LifeOsEntityLifecycle target,
    LifeOsEntityLifecycle allowedFrom,
    DateTime timestamp,
  ) {
    _validateMutationTimestamp(timestamp);
    if (lifecycle == target) return this;
    if (lifecycle != allowedFrom) {
      throw StateError(
        'The requested Workspace lifecycle transition is invalid.',
      );
    }
    return _copy(
      title: title,
      description: description,
      updatedAt: timestamp,
      lifecycle: target,
    );
  }

  LifeOsWorkspace _copy({
    required String title,
    required String? description,
    required DateTime updatedAt,
    required LifeOsEntityLifecycle lifecycle,
  }) => LifeOsWorkspace(
    id: id,
    title: title,
    description: description,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lifecycle: lifecycle,
    version: version + 1,
    source: source,
  );

  void _validateMutationTimestamp(DateTime value) {
    _validateUtc(value, 'updatedAt');
    if (value.isBefore(updatedAt)) {
      throw ArgumentError.value(
        value,
        'updatedAt',
        'A Workspace update timestamp cannot move backwards.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LifeOsWorkspace &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          lifecycle == other.lifecycle &&
          version == other.version &&
          source == other.source;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    createdAt,
    updatedAt,
    lifecycle,
    version,
    source,
  );
}

void _validateIdentity(LifeOsEntityId id) {
  if (id.entityType != LifeOsEntityType.workspace || id.value.trim().isEmpty) {
    throw ArgumentError.value(id, 'id', 'Invalid Workspace identity.');
  }
}

void _validateTitle(String title) {
  if (title.isEmpty) {
    throw ArgumentError.value(
      title,
      'title',
      'A Workspace title cannot be empty.',
    );
  }
}

void _validateUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(
      value,
      name,
      'A Workspace timestamp must be UTC.',
    );
  }
}
