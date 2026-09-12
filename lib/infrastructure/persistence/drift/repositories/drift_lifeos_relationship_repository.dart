import 'package:drift/drift.dart';

import '../../../../domain/entities/lifeos_entity.dart';
import '../../../../domain/entities/lifeos_relationship.dart';
import '../../../../domain/repositories/lifeos_relationship_repository.dart';
import '../lifeos_database.dart';
import '../mappers/lifeos_relationship_mapper.dart';
import 'drift_lifeos_task_repository.dart' show ChangeIdGenerator;

final class LifeOsRelationshipPersistenceException implements Exception {
  const LifeOsRelationshipPersistenceException(this.message);
  final String message;

  @override
  String toString() => 'LifeOsRelationshipPersistenceException: $message';
}

final class DriftLifeOsRelationshipRepository
    implements LifeOsRelationshipRepository {
  DriftLifeOsRelationshipRepository(
    this._database,
    this._changeIdGenerator,
    this._deviceId,
  );

  static const _changeSchemaVersion = 1;
  static const _pendingStatus = 'PENDING';

  final LifeOsDatabase _database;
  final ChangeIdGenerator _changeIdGenerator;
  final String _deviceId;

  @override
  Future<List<LifeOsRelationship>> getAll() async {
    final query =
        _database.select(_database.relationshipRecords).join([
          innerJoin(
            _database.entities,
            _database.entities.id.equalsExp(
              _database.relationshipRecords.entityId,
            ),
          ),
        ])..where(
          _database.entities.entityType.equals(
            LifeOsEntityType.relationship.name,
          ),
        );
    final values = <LifeOsRelationship>[];
    for (final row in await query.get()) {
      values.add(
        await _map(
          row.readTable(_database.entities),
          row.readTable(_database.relationshipRecords),
        ),
      );
    }
    values.sort((a, b) => a.id.value.compareTo(b.id.value));
    return List.unmodifiable(values);
  }

  @override
  Future<LifeOsRelationship?> getById(LifeOsEntityId id) async {
    if (id.entityType != LifeOsEntityType.relationship) return null;
    final entity = await _entity(id.value);
    if (entity == null ||
        entity.entityType != LifeOsEntityType.relationship.name) {
      return null;
    }
    final typed = await (_database.select(
      _database.relationshipRecords,
    )..where((row) => row.entityId.equals(id.value))).getSingleOrNull();
    if (typed == null) {
      throw const LifeOsRelationshipPersistenceException(
        'The Relationship Entity has no matching typed record.',
      );
    }
    return _map(entity, typed);
  }

  @override
  Future<List<LifeOsRelationship>> getForEntity(LifeOsEntityId entityId) async {
    if (!_isSupportedEndpointType(entityId.entityType)) return const [];
    final query =
        _database.select(_database.relationshipRecords).join([
          innerJoin(
            _database.entities,
            _database.entities.id.equalsExp(
              _database.relationshipRecords.entityId,
            ),
          ),
        ])..where(
          (_database.relationshipRecords.firstEntityId.equals(entityId.value) |
                  _database.relationshipRecords.secondEntityId.equals(
                    entityId.value,
                  )) &
              _database.entities.entityType.equals(
                LifeOsEntityType.relationship.name,
              ) &
              _database.entities.lifecycle.equals(
                LifeOsEntityLifecycle.active.name,
              ),
        );
    final values = <LifeOsRelationship>[];
    for (final row in await query.get()) {
      values.add(
        await _map(
          row.readTable(_database.entities),
          row.readTable(_database.relationshipRecords),
        ),
      );
    }
    values.sort((a, b) {
      final updated = b.updatedAt.compareTo(a.updatedAt);
      return updated != 0 ? updated : a.id.value.compareTo(b.id.value);
    });
    return List.unmodifiable(values);
  }

  @override
  Future<void> save(LifeOsRelationship relationship) async {
    try {
      await _database.transaction(() async {
        final first = await _verifiedEndpoint(relationship.firstEntityId);
        final second = await _verifiedEndpoint(relationship.secondEntityId);
        final existing = await _entity(relationship.id.value);
        if (existing != null &&
            existing.entityType != LifeOsEntityType.relationship.name) {
          throw const LifeOsRelationshipPersistenceException(
            'An Entity with this ID already has another type.',
          );
        }
        if (existing != null) {
          final typed =
              await (_database.select(
                    _database.relationshipRecords,
                  )..where((row) => row.entityId.equals(relationship.id.value)))
                  .getSingleOrNull();
          if (typed == null) {
            throw const LifeOsRelationshipPersistenceException(
              'The Relationship Entity has no matching typed record.',
            );
          }
          final persisted = await _map(existing, typed);
          if (persisted == relationship) return;
          _validateUpdate(persisted, relationship);
        } else {
          _validateCreation(relationship);
        }
        final duplicate =
            await (_database.select(_database.relationshipRecords)..where(
                  (row) =>
                      row.firstEntityId.equals(
                        relationship.firstEntityId.value,
                      ) &
                      row.secondEntityId.equals(
                        relationship.secondEntityId.value,
                      ) &
                      row.kind.equals(relationship.kind.name) &
                      row.entityId.equals(relationship.id.value).not(),
                ))
                .getSingleOrNull();
        if (duplicate != null) {
          throw const LifeOsRelationshipPersistenceException(
            'A Relationship for this endpoint pair and kind already exists.',
          );
        }

        await _database
            .into(_database.entities)
            .insertOnConflictUpdate(
              EntitiesCompanion.insert(
                id: relationship.id.value,
                entityType: relationship.entityType.name,
                createdAt: relationship.createdAt,
                updatedAt: relationship.updatedAt,
                lifecycle: relationship.lifecycle.name,
                version: relationship.version,
                source: relationship.source.name,
              ),
            );
        await _database
            .into(_database.relationshipRecords)
            .insertOnConflictUpdate(
              RelationshipRecordsCompanion.insert(
                entityId: relationship.id.value,
                firstEntityId: first.id,
                secondEntityId: second.id,
                kind: relationship.kind.name,
              ),
            );
        await _database
            .into(_database.outboxEntries)
            .insert(
              OutboxEntriesCompanion.insert(
                changeId: _changeIdGenerator(),
                entityId: relationship.id.value,
                deviceId: _deviceId,
                operation: existing == null ? 'CREATE' : 'UPDATE',
                baseVersion: Value(existing?.version),
                newVersion: relationship.version,
                payload: LifeOsRelationshipMapper.toJsonSnapshot(relationship),
                schemaVersion: _changeSchemaVersion,
                status: _pendingStatus,
                attemptCount: 0,
                createdAt: relationship.updatedAt,
                lastAttemptAt: const Value.absent(),
              ),
            );
      });
    } on LifeOsRelationshipPersistenceException {
      rethrow;
    } on Object {
      throw const LifeOsRelationshipPersistenceException(
        'The Relationship could not be persisted atomically.',
      );
    }
  }

  Future<LifeOsRelationship> _map(
    EntityRecord entity,
    RelationshipRecord typed,
  ) async {
    final first = await _entity(typed.firstEntityId);
    final second = await _entity(typed.secondEntityId);
    if (first == null || second == null) {
      throw const LifeOsRelationshipPersistenceException(
        'A Relationship endpoint Entity is missing.',
      );
    }
    return LifeOsRelationshipMapper.toDomain(entity, typed, first, second);
  }

  Future<EntityRecord?> _entity(String id) => (_database.select(
    _database.entities,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<EntityRecord> _verifiedEndpoint(LifeOsEntityId id) async {
    if (!_isSupportedEndpointType(id.entityType)) {
      throw const LifeOsRelationshipPersistenceException(
        'Relationship endpoint type is not supported.',
      );
    }
    final entity = await _entity(id.value);
    if (entity == null) {
      throw const LifeOsRelationshipPersistenceException(
        'Relationship endpoint does not exist.',
      );
    }
    if (entity.entityType != id.entityType.name ||
        !_isSupportedStoredEndpointType(entity.entityType)) {
      throw const LifeOsRelationshipPersistenceException(
        'Relationship endpoint type is inconsistent.',
      );
    }
    return entity;
  }
}

void _validateCreation(LifeOsRelationship relationship) {
  if (relationship.lifecycle != LifeOsEntityLifecycle.active ||
      relationship.version != 1 ||
      relationship.source != LifeOsEntitySource.user ||
      relationship.createdAt != relationship.updatedAt) {
    throw const LifeOsRelationshipPersistenceException(
      'A new Relationship must satisfy the local creation contract.',
    );
  }
}

void _validateUpdate(
  LifeOsRelationship persisted,
  LifeOsRelationship replacement,
) {
  final isMaterialUnlink =
      persisted.lifecycle == LifeOsEntityLifecycle.active &&
      replacement.lifecycle == LifeOsEntityLifecycle.deleted &&
      replacement.version == persisted.version + 1 &&
      !replacement.updatedAt.isBefore(persisted.updatedAt) &&
      replacement.createdAt == persisted.createdAt &&
      replacement.source == persisted.source &&
      replacement.firstEntityId == persisted.firstEntityId &&
      replacement.secondEntityId == persisted.secondEntityId &&
      replacement.kind == persisted.kind;
  if (!isMaterialUnlink) {
    throw const LifeOsRelationshipPersistenceException(
      'Relationship v1 only supports a material lifecycle unlink update.',
    );
  }
}

bool _isSupportedEndpointType(LifeOsEntityType type) =>
    type == LifeOsEntityType.task || type == LifeOsEntityType.note;

bool _isSupportedStoredEndpointType(String type) =>
    type == LifeOsEntityType.task.name || type == LifeOsEntityType.note.name;
