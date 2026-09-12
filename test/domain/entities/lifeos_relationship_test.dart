import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_relationship.dart';

void main() {
  LifeOsEntityId id(String value, LifeOsEntityType type) =>
      LifeOsEntityId(value: value, entityType: type);

  test('creates canonical active user Relationship metadata', () {
    final timestamp = DateTime.utc(2026, 9, 12);
    final relationship = LifeOsRelationship.createUserRelationship(
      id: id('rel-1', LifeOsEntityType.relationship),
      firstEndpoint: id('z-note', LifeOsEntityType.note),
      secondEndpoint: id('a-task', LifeOsEntityType.task),
      timestamp: timestamp,
    );
    expect(relationship.firstEntityId.value, 'a-task');
    expect(relationship.secondEntityId.value, 'z-note');
    expect(relationship.kind, LifeOsRelationshipKind.related);
    expect(relationship.createdAt, timestamp);
    expect(relationship.updatedAt, timestamp);
    expect(relationship.lifecycle, LifeOsEntityLifecycle.active);
    expect(relationship.version, 1);
    expect(relationship.source, LifeOsEntitySource.user);
  });

  test('rejects self-links, unsupported endpoints, and non-UTC creation', () {
    final relationshipId = id('rel', LifeOsEntityType.relationship);
    final task = id('task', LifeOsEntityType.task);
    expect(
      () => LifeOsRelationship.createUserRelationship(
        id: relationshipId,
        firstEndpoint: task,
        secondEndpoint: task,
        timestamp: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
    expect(
      () => LifeOsRelationship.createUserRelationship(
        id: relationshipId,
        firstEndpoint: task,
        secondEndpoint: id('rel-2', LifeOsEntityType.relationship),
        timestamp: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
    expect(
      () => LifeOsRelationship.createUserRelationship(
        id: relationshipId,
        firstEndpoint: task,
        secondEndpoint: id('note', LifeOsEntityType.note),
        timestamp: DateTime(2026),
      ),
      throwsArgumentError,
    );
  });

  test('unlinks once through deleted lifecycle and then becomes a no-op', () {
    final createdAt = DateTime.utc(2026, 9, 12, 10);
    final relationship = LifeOsRelationship.createUserRelationship(
      id: id('rel', LifeOsEntityType.relationship),
      firstEndpoint: id('task', LifeOsEntityType.task),
      secondEndpoint: id('note', LifeOsEntityType.note),
      timestamp: createdAt,
    );
    final deleted = relationship.unlink(
      updatedAt: DateTime.utc(2026, 9, 12, 11),
    );
    expect(deleted.lifecycle, LifeOsEntityLifecycle.deleted);
    expect(deleted.version, 2);
    expect(
      deleted.unlink(updatedAt: DateTime.utc(2026, 9, 12, 12)),
      same(deleted),
    );
  });

  test('rejects a backwards unlink timestamp', () {
    final relationship = LifeOsRelationship.createUserRelationship(
      id: id('rel', LifeOsEntityType.relationship),
      firstEndpoint: id('a', LifeOsEntityType.task),
      secondEndpoint: id('b', LifeOsEntityType.note),
      timestamp: DateTime.utc(2026, 9, 12, 10),
    );
    expect(
      () => relationship.unlink(updatedAt: DateTime.utc(2026, 9, 12, 9)),
      throwsArgumentError,
    );
  });

  test('rejects invalid hydrated Relationship state defensively', () {
    final baseId = id('rel', LifeOsEntityType.relationship);
    final firstEndpoint = id('a', LifeOsEntityType.task);
    final secondEndpoint = id('b', LifeOsEntityType.note);

    LifeOsRelationship hydrate({
      LifeOsEntityId? relationshipId,
      LifeOsEntityId? first,
      LifeOsEntityId? second,
      DateTime? createdAt,
      DateTime? updatedAt,
      int version = 1,
    }) => LifeOsRelationship(
      id: relationshipId ?? baseId,
      firstEntityId: first ?? firstEndpoint,
      secondEntityId: second ?? secondEndpoint,
      kind: LifeOsRelationshipKind.related,
      createdAt: createdAt ?? DateTime.utc(2026, 9, 12, 10),
      updatedAt: updatedAt ?? DateTime.utc(2026, 9, 12, 10),
      lifecycle: LifeOsEntityLifecycle.active,
      version: version,
      source: LifeOsEntitySource.user,
    );

    final invalid = <LifeOsRelationship Function()>[
      () => hydrate(relationshipId: id('rel', LifeOsEntityType.task)),
      () => hydrate(second: id('rel-2', LifeOsEntityType.relationship)),
      () => hydrate(second: id('a', LifeOsEntityType.note)),
      () => hydrate(
        first: id('z', LifeOsEntityType.task),
        second: id('a', LifeOsEntityType.note),
      ),
      () => hydrate(createdAt: DateTime(2026)),
      () => hydrate(updatedAt: DateTime.utc(2026, 9, 12, 9)),
      () => hydrate(version: 0),
    ];
    for (final createInvalid in invalid) {
      expect(createInvalid, throwsArgumentError);
    }
  });
}
