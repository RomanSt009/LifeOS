import 'dart:convert';

import '../../../../domain/entities/lifeos_entity.dart';
import '../../../../domain/entities/lifeos_note.dart';
import '../lifeos_database.dart';

final class LifeOsNoteMappingException implements Exception {
  const LifeOsNoteMappingException(this.message);

  final String message;

  @override
  String toString() => 'LifeOsNoteMappingException: $message';
}

abstract final class LifeOsNoteMapper {
  static LifeOsNote toDomain(EntityRecord entity, NoteRecord note) {
    if (entity.id != note.entityId ||
        entity.entityType != LifeOsEntityType.note.name) {
      throw const LifeOsNoteMappingException(
        'The Entity and Note persistence records are inconsistent.',
      );
    }

    try {
      return LifeOsNote(
        id: LifeOsEntityId(value: entity.id, entityType: LifeOsEntityType.note),
        title: note.title,
        content: note.content,
        createdAt: entity.createdAt.toUtc(),
        updatedAt: entity.updatedAt.toUtc(),
        lifecycle: LifeOsEntityLifecycle.values.byName(entity.lifecycle),
        version: entity.version,
        source: LifeOsEntitySource.values.byName(entity.source),
      );
    } on Object {
      throw const LifeOsNoteMappingException(
        'The persisted Note violates the Domain contract.',
      );
    }
  }

  static String toJsonSnapshot(LifeOsNote note) {
    return jsonEncode({
      'id': note.id.value,
      'entityType': note.entityType.name,
      'title': note.title,
      'content': note.content,
      'createdAt': note.createdAt.toUtc().toIso8601String(),
      'updatedAt': note.updatedAt.toUtc().toIso8601String(),
      'lifecycle': note.lifecycle.name,
      'version': note.version,
      'source': note.source.name,
    });
  }
}
