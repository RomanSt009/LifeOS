import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/mappers/lifeos_relationship_mapper.dart';

void main() {
  final createdAt = DateTime.utc(2026, 9, 12, 10);

  EntityRecord entity({
    String id = 'relationship-a',
    String entityType = 'relationship',
    DateTime? created,
    DateTime? updated,
    String lifecycle = 'active',
    int version = 1,
    String source = 'user',
  }) => EntityRecord(
    id: id,
    entityType: entityType,
    createdAt: created ?? createdAt,
    updatedAt: updated ?? createdAt,
    lifecycle: lifecycle,
    version: version,
    source: source,
  );

  RelationshipRecord typed({
    String entityId = 'relationship-a',
    String first = 'note-a',
    String second = 'task-a',
    String kind = 'related',
  }) => RelationshipRecord(
    entityId: entityId,
    firstEntityId: first,
    secondEntityId: second,
    kind: kind,
  );

  EntityRecord endpoint(String id, String type) => EntityRecord(
    id: id,
    entityType: type,
    createdAt: createdAt,
    updatedAt: createdAt,
    lifecycle: 'active',
    version: 1,
    source: 'user',
  );

  test('maps a valid Relationship without changing persisted state', () {
    final result = LifeOsRelationshipMapper.toDomain(
      entity(),
      typed(),
      endpoint('note-a', 'note'),
      endpoint('task-a', 'task'),
    );

    expect(result.entityType, LifeOsEntityType.relationship);
    expect(result.firstEntityId.entityType, LifeOsEntityType.note);
    expect(result.secondEntityId.entityType, LifeOsEntityType.task);
    expect(result.createdAt, same(createdAt));
  });

  test('rejects every corrupt persistence shape with a typed error', () {
    final validEntity = entity();
    final validTyped = typed();
    final first = endpoint('note-a', 'note');
    final second = endpoint('task-a', 'task');
    final cases = <List<Object>>[
      [entity(entityType: 'task'), validTyped, first, second],
      [validEntity, typed(entityId: 'relationship-b'), first, second],
      [validEntity, validTyped, endpoint('other', 'note'), second],
      [validEntity, validTyped, endpoint('note-a', 'relationship'), second],
      [validEntity, validTyped, endpoint('note-a', 'unknown'), second],
      [validEntity, typed(second: 'note-a'), first, endpoint('note-a', 'note')],
      [
        validEntity,
        typed(first: 'task-a', second: 'note-a'),
        endpoint('task-a', 'task'),
        endpoint('note-a', 'note'),
      ],
      [validEntity, typed(kind: 'contains'), first, second],
      [entity(lifecycle: 'unknown'), validTyped, first, second],
      [entity(version: 0), validTyped, first, second],
      [
        entity(updated: createdAt.subtract(const Duration(seconds: 1))),
        validTyped,
        first,
        second,
      ],
      [entity(source: 'unknown'), validTyped, first, second],
    ];

    for (final values in cases) {
      expect(
        () => LifeOsRelationshipMapper.toDomain(
          values[0] as EntityRecord,
          values[1] as RelationshipRecord,
          values[2] as EntityRecord,
          values[3] as EntityRecord,
        ),
        throwsA(isA<LifeOsRelationshipMappingException>()),
      );
    }
  });
}
