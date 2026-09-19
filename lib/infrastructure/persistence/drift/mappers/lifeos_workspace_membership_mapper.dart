import 'dart:convert';

import '../../../../domain/entities/lifeos_entity.dart';
import '../../../../domain/entities/lifeos_workspace_membership.dart';
import '../lifeos_database.dart';

final class LifeOsWorkspaceMembershipMappingException implements Exception {
  const LifeOsWorkspaceMembershipMappingException(this.message);
  final String message;

  @override
  String toString() => 'LifeOsWorkspaceMembershipMappingException: $message';
}

abstract final class LifeOsWorkspaceMembershipMapper {
  static LifeOsWorkspaceMembership toDomain(
    EntityRecord entity,
    WorkspaceMembershipRecord membership,
    EntityRecord workspace,
    EntityRecord member,
  ) {
    if (entity.id != membership.entityId ||
        entity.entityType != LifeOsEntityType.workspaceMembership.name ||
        workspace.id != membership.workspaceId ||
        workspace.entityType != LifeOsEntityType.workspace.name ||
        member.id != membership.memberEntityId) {
      throw const LifeOsWorkspaceMembershipMappingException(
        'Workspace membership persistence records are inconsistent.',
      );
    }
    try {
      return LifeOsWorkspaceMembership(
        id: LifeOsEntityId(
          value: entity.id,
          entityType: LifeOsEntityType.workspaceMembership,
        ),
        workspaceId: LifeOsEntityId(
          value: workspace.id,
          entityType: LifeOsEntityType.workspace,
        ),
        memberEntityId: LifeOsEntityId(
          value: member.id,
          entityType: LifeOsEntityType.values.byName(member.entityType),
        ),
        createdAt: entity.createdAt.toUtc(),
        updatedAt: entity.updatedAt.toUtc(),
        lifecycle: LifeOsEntityLifecycle.values.byName(entity.lifecycle),
        version: entity.version,
        source: LifeOsEntitySource.values.byName(entity.source),
      );
    } on Object {
      throw const LifeOsWorkspaceMembershipMappingException(
        'The persisted Workspace membership violates the Domain contract.',
      );
    }
  }

  static String toJsonSnapshot(LifeOsWorkspaceMembership membership) =>
      jsonEncode({
        'id': membership.id.value,
        'entityType': membership.entityType.name,
        'workspaceId': membership.workspaceId.value,
        'memberEntityId': membership.memberEntityId.value,
        'createdAt': membership.createdAt.toUtc().toIso8601String(),
        'updatedAt': membership.updatedAt.toUtc().toIso8601String(),
        'lifecycle': membership.lifecycle.name,
        'version': membership.version,
        'source': membership.source.name,
      });
}
