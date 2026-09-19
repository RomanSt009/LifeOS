import 'dart:convert';

import '../../../../domain/entities/lifeos_entity.dart';
import '../../../../domain/entities/lifeos_workspace.dart';
import '../lifeos_database.dart';

final class LifeOsWorkspaceMappingException implements Exception {
  const LifeOsWorkspaceMappingException(this.message);
  final String message;

  @override
  String toString() => 'LifeOsWorkspaceMappingException: $message';
}

abstract final class LifeOsWorkspaceMapper {
  static LifeOsWorkspace toDomain(
    EntityRecord entity,
    WorkspaceRecord workspace,
  ) {
    if (entity.id != workspace.entityId ||
        entity.entityType != LifeOsEntityType.workspace.name) {
      throw const LifeOsWorkspaceMappingException(
        'Workspace persistence records are inconsistent.',
      );
    }
    try {
      return LifeOsWorkspace(
        id: LifeOsEntityId(
          value: entity.id,
          entityType: LifeOsEntityType.workspace,
        ),
        title: workspace.title,
        description: workspace.description,
        createdAt: entity.createdAt.toUtc(),
        updatedAt: entity.updatedAt.toUtc(),
        lifecycle: LifeOsEntityLifecycle.values.byName(entity.lifecycle),
        version: entity.version,
        source: LifeOsEntitySource.values.byName(entity.source),
      );
    } on Object {
      throw const LifeOsWorkspaceMappingException(
        'The persisted Workspace violates the Domain contract.',
      );
    }
  }

  static String toJsonSnapshot(LifeOsWorkspace workspace) => jsonEncode({
    'id': workspace.id.value,
    'entityType': workspace.entityType.name,
    'title': workspace.title,
    'description': workspace.description,
    'createdAt': workspace.createdAt.toUtc().toIso8601String(),
    'updatedAt': workspace.updatedAt.toUtc().toIso8601String(),
    'lifecycle': workspace.lifecycle.name,
    'version': workspace.version,
    'source': workspace.source.name,
  });
}
