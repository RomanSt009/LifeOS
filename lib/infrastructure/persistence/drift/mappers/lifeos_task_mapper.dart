import 'dart:convert';

import '../../../../domain/entities/lifeos_entity.dart';
import '../../../../domain/entities/lifeos_task.dart';
import '../lifeos_database.dart';

abstract final class LifeOsTaskMapper {
  static LifeOsTask toDomain(EntityRecord entity, TaskRecord task) {
    final entityType = LifeOsEntityType.values.byName(entity.entityType);

    return LifeOsTask(
      id: LifeOsEntityId(value: entity.id, entityType: entityType),
      title: task.title,
      isCompleted: task.isCompleted,
      createdAt: entity.createdAt.toUtc(),
      updatedAt: entity.updatedAt.toUtc(),
      lifecycle: LifeOsEntityLifecycle.values.byName(entity.lifecycle),
      version: entity.version,
      source: LifeOsEntitySource.values.byName(entity.source),
    );
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
