import 'dart:convert';

import '../../../../domain/entities/lifeos_entity.dart';
import '../../../../domain/entities/lifeos_task.dart';
import '../lifeos_database.dart';

final class LifeOsTaskMappingException implements Exception {
  const LifeOsTaskMappingException(this.message);

  final String message;

  @override
  String toString() => 'LifeOsTaskMappingException: $message';
}

abstract final class LifeOsTaskMapper {
  static LifeOsTask toDomain(EntityRecord entity, TaskRecord task) {
    if (entity.id != task.entityId ||
        entity.entityType != LifeOsEntityType.task.name) {
      throw const LifeOsTaskMappingException(
        'The Entity and Task persistence records are inconsistent.',
      );
    }

    try {
      return LifeOsTask(
        id: LifeOsEntityId(value: entity.id, entityType: LifeOsEntityType.task),
        title: task.title,
        isCompleted: task.isCompleted,
        createdAt: entity.createdAt.toUtc(),
        updatedAt: entity.updatedAt.toUtc(),
        lifecycle: LifeOsEntityLifecycle.values.byName(entity.lifecycle),
        version: entity.version,
        source: LifeOsEntitySource.values.byName(entity.source),
      );
    } on Object {
      throw const LifeOsTaskMappingException(
        'The persisted Task violates the Domain contract.',
      );
    }
  }

  static String toJsonSnapshot(LifeOsTask task) {
    return jsonEncode({
      'id': task.id.value,
      'entityType': task.entityType.name,
      'title': task.title,
      'isCompleted': task.isCompleted,
      'createdAt': task.createdAt.toUtc().toIso8601String(),
      'updatedAt': task.updatedAt.toUtc().toIso8601String(),
      'lifecycle': task.lifecycle.name,
      'version': task.version,
      'source': task.source.name,
    });
  }
}
