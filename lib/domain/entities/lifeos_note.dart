import 'lifeos_entity.dart';

class LifeOsNote implements LifeOsEntity {
  LifeOsNote({
    required this.id,
    required this.title,
    required this.content,
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
        'A Note update timestamp cannot precede its creation timestamp.',
      );
    }
    if (version < 1) {
      throw ArgumentError.value(
        version,
        'version',
        'A Note version must be positive.',
      );
    }
    if (title != title.trim()) {
      throw ArgumentError.value(
        title,
        'title',
        'A hydrated Note title must already be normalized.',
      );
    }
    _validateContent(title, content);
  }

  factory LifeOsNote.createUserNote({
    required LifeOsEntityId id,
    required String title,
    required String content,
    required DateTime timestamp,
  }) {
    final normalizedTitle = title.trim();
    _validateIdentity(id);
    _validateUtc(timestamp, 'timestamp');
    _validateContent(normalizedTitle, content);

    return LifeOsNote(
      id: id,
      title: normalizedTitle,
      content: content,
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
  final String content;

  @override
  LifeOsEntityType get entityType => LifeOsEntityType.note;

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

  LifeOsNote edit({
    required String title,
    required String content,
    required DateTime updatedAt,
  }) {
    final normalizedTitle = title.trim();
    _validateUtc(updatedAt, 'updatedAt');
    if (updatedAt.isBefore(this.updatedAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'A Note update timestamp cannot move backwards.',
      );
    }
    _validateContent(normalizedTitle, content);
    if (lifecycle != LifeOsEntityLifecycle.active) {
      throw StateError('Only an active Note can be edited.');
    }

    if (normalizedTitle == this.title && content == this.content) {
      return this;
    }

    return LifeOsNote(
      id: id,
      title: normalizedTitle,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lifecycle: lifecycle,
      version: version + 1,
      source: source,
    );
  }

  LifeOsNote archive({required DateTime updatedAt}) => _changeLifecycle(
    target: LifeOsEntityLifecycle.archived,
    updatedAt: updatedAt,
    allowedFrom: LifeOsEntityLifecycle.active,
  );

  LifeOsNote unarchive({required DateTime updatedAt}) => _changeLifecycle(
    target: LifeOsEntityLifecycle.active,
    updatedAt: updatedAt,
    allowedFrom: LifeOsEntityLifecycle.archived,
  );

  LifeOsNote delete({required DateTime updatedAt}) => _changeLifecycle(
    target: LifeOsEntityLifecycle.deleted,
    updatedAt: updatedAt,
    allowedFrom: lifecycle == LifeOsEntityLifecycle.archived
        ? LifeOsEntityLifecycle.archived
        : LifeOsEntityLifecycle.active,
  );

  LifeOsNote restore({required DateTime updatedAt}) => _changeLifecycle(
    target: LifeOsEntityLifecycle.active,
    updatedAt: updatedAt,
    allowedFrom: LifeOsEntityLifecycle.deleted,
  );

  LifeOsNote _changeLifecycle({
    required LifeOsEntityLifecycle target,
    required DateTime updatedAt,
    required LifeOsEntityLifecycle allowedFrom,
  }) {
    _validateMutationTimestamp(updatedAt);
    if (lifecycle == target) return this;
    if (lifecycle != allowedFrom) {
      throw StateError('The requested Note lifecycle transition is invalid.');
    }
    return LifeOsNote(
      id: id,
      title: title,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lifecycle: target,
      version: version + 1,
      source: source,
    );
  }

  void _validateMutationTimestamp(DateTime value) {
    _validateUtc(value, 'updatedAt');
    if (value.isBefore(updatedAt)) {
      throw ArgumentError.value(
        value,
        'updatedAt',
        'A Note update timestamp cannot move backwards.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LifeOsNote &&
            id == other.id &&
            title == other.title &&
            content == other.content &&
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
    content,
    createdAt,
    updatedAt,
    lifecycle,
    version,
    source,
  );
}

void _validateIdentity(LifeOsEntityId id) {
  if (id.entityType != LifeOsEntityType.note) {
    throw ArgumentError.value(id, 'id', 'A Note requires a Note entity ID.');
  }
  if (id.value.trim().isEmpty) {
    throw ArgumentError.value(id, 'id', 'A Note entity ID cannot be empty.');
  }
}

void _validateUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'A Note timestamp must be UTC.');
  }
}

void _validateContent(String normalizedTitle, String content) {
  if (normalizedTitle.isEmpty && content.trim().isEmpty) {
    throw ArgumentError.value(
      content,
      'content',
      'A Note title and content cannot both be empty.',
    );
  }
}
