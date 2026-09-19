import 'lifeos_entity.dart';

final class LifeOsWorkspaceMembership implements LifeOsEntity {
  LifeOsWorkspaceMembership({
    required this.id,
    required this.workspaceId,
    required this.memberEntityId,
    required this.createdAt,
    required this.updatedAt,
    required this.lifecycle,
    required this.version,
    required this.source,
  }) {
    _validateTypedId(id, LifeOsEntityType.workspaceMembership, 'id');
    _validateTypedId(workspaceId, LifeOsEntityType.workspace, 'workspaceId');
    _validateMemberId(memberEntityId);
    if (workspaceId.value == memberEntityId.value) {
      throw ArgumentError('A Workspace membership cannot reference itself.');
    }
    _validateUtc(createdAt, 'createdAt');
    _validateUtc(updatedAt, 'updatedAt');
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError.value(
        updatedAt,
        'updatedAt',
        'A Workspace membership update cannot precede its creation.',
      );
    }
    if (version < 1) {
      throw ArgumentError.value(
        version,
        'version',
        'Version must be positive.',
      );
    }
    if (lifecycle == LifeOsEntityLifecycle.archived) {
      throw ArgumentError.value(
        lifecycle,
        'lifecycle',
        'Workspace membership does not support archived lifecycle.',
      );
    }
  }

  factory LifeOsWorkspaceMembership.createUserMembership({
    required LifeOsEntityId id,
    required LifeOsEntityId workspaceId,
    required LifeOsEntityId memberEntityId,
    required DateTime timestamp,
  }) {
    _validateUtc(timestamp, 'timestamp');
    return LifeOsWorkspaceMembership(
      id: id,
      workspaceId: workspaceId,
      memberEntityId: memberEntityId,
      createdAt: timestamp,
      updatedAt: timestamp,
      lifecycle: LifeOsEntityLifecycle.active,
      version: 1,
      source: LifeOsEntitySource.user,
    );
  }

  @override
  final LifeOsEntityId id;
  final LifeOsEntityId workspaceId;
  final LifeOsEntityId memberEntityId;
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
  LifeOsEntityType get entityType => LifeOsEntityType.workspaceMembership;

  LifeOsWorkspaceMembership remove({required DateTime updatedAt}) {
    _validateMutationTimestamp(updatedAt);
    if (lifecycle == LifeOsEntityLifecycle.deleted) return this;
    return _withLifecycle(LifeOsEntityLifecycle.deleted, updatedAt);
  }

  LifeOsWorkspaceMembership reattach({required DateTime updatedAt}) {
    _validateMutationTimestamp(updatedAt);
    if (lifecycle == LifeOsEntityLifecycle.active) return this;
    return _withLifecycle(LifeOsEntityLifecycle.active, updatedAt);
  }

  LifeOsWorkspaceMembership _withLifecycle(
    LifeOsEntityLifecycle value,
    DateTime timestamp,
  ) => LifeOsWorkspaceMembership(
    id: id,
    workspaceId: workspaceId,
    memberEntityId: memberEntityId,
    createdAt: createdAt,
    updatedAt: timestamp,
    lifecycle: value,
    version: version + 1,
    source: source,
  );

  void _validateMutationTimestamp(DateTime value) {
    _validateUtc(value, 'updatedAt');
    if (value.isBefore(updatedAt)) {
      throw ArgumentError.value(
        value,
        'updatedAt',
        'A Workspace membership update timestamp cannot move backwards.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LifeOsWorkspaceMembership &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          memberEntityId == other.memberEntityId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          lifecycle == other.lifecycle &&
          version == other.version &&
          source == other.source;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    memberEntityId,
    createdAt,
    updatedAt,
    lifecycle,
    version,
    source,
  );
}

void _validateTypedId(LifeOsEntityId id, LifeOsEntityType type, String name) {
  if (id.entityType != type || id.value.trim().isEmpty) {
    throw ArgumentError.value(id, name, 'Invalid typed Entity identity.');
  }
}

void _validateMemberId(LifeOsEntityId id) {
  if (id.value.trim().isEmpty ||
      (id.entityType != LifeOsEntityType.task &&
          id.entityType != LifeOsEntityType.note)) {
    throw ArgumentError.value(id, 'memberEntityId', 'Unsupported member type.');
  }
}

void _validateUtc(DateTime value, String name) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, name, 'Timestamp must be UTC.');
  }
}
