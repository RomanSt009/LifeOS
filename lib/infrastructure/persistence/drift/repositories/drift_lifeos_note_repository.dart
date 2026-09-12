import 'package:drift/drift.dart';

import '../../../../domain/entities/lifeos_entity.dart';
import '../../../../domain/entities/lifeos_note.dart';
import '../../../../domain/repositories/lifeos_note_repository.dart';
import '../lifeos_database.dart';
import '../mappers/lifeos_note_mapper.dart';
import 'drift_lifeos_task_repository.dart' show ChangeIdGenerator;

final class LifeOsNotePersistenceException implements Exception {
  const LifeOsNotePersistenceException(this.message);

  final String message;

  @override
  String toString() => 'LifeOsNotePersistenceException: $message';
}

class DriftLifeOsNoteRepository implements LifeOsNoteRepository {
  DriftLifeOsNoteRepository(
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
  Future<List<LifeOsNote>> getAll() async {
    final query =
        _database.select(_database.entities).join([
            innerJoin(
              _database.noteRecords,
              _database.noteRecords.entityId.equalsExp(_database.entities.id),
            ),
          ])
          ..where(
            _database.entities.entityType.equals(LifeOsEntityType.note.name),
          )
          ..orderBy([
            OrderingTerm.desc(_database.entities.updatedAt),
            OrderingTerm.asc(_database.entities.id),
          ]);

    return (await query.get()).map(_mapNote).toList(growable: false);
  }

  @override
  Future<LifeOsNote?> getById(LifeOsEntityId id) async {
    if (id.entityType != LifeOsEntityType.note) {
      return null;
    }

    final entity = await (_database.select(
      _database.entities,
    )..where((record) => record.id.equals(id.value))).getSingleOrNull();
    if (entity == null || entity.entityType != LifeOsEntityType.note.name) {
      return null;
    }

    final note = await (_database.select(
      _database.noteRecords,
    )..where((record) => record.entityId.equals(id.value))).getSingleOrNull();
    if (note == null) {
      throw const LifeOsNotePersistenceException(
        'The Note Entity has no matching typed persistence record.',
      );
    }

    return LifeOsNoteMapper.toDomain(entity, note);
  }

  @override
  Future<void> save(LifeOsNote note) async {
    if (note.id.entityType != LifeOsEntityType.note) {
      throw const LifeOsNotePersistenceException(
        'A Note requires a typed Note Entity ID.',
      );
    }

    await _database.transaction(() async {
      final existing = await (_database.select(
        _database.entities,
      )..where((entity) => entity.id.equals(note.id.value))).getSingleOrNull();

      if (existing != null &&
          existing.entityType != LifeOsEntityType.note.name) {
        throw const LifeOsNotePersistenceException(
          'An Entity with this ID already exists with another type.',
        );
      }
      if (existing != null) {
        final typedRecord =
            await (_database.select(_database.noteRecords)
                  ..where((record) => record.entityId.equals(note.id.value)))
                .getSingleOrNull();
        if (typedRecord == null) {
          throw const LifeOsNotePersistenceException(
            'The Note Entity has no matching typed persistence record.',
          );
        }
      }

      await _database
          .into(_database.entities)
          .insertOnConflictUpdate(
            EntitiesCompanion.insert(
              id: note.id.value,
              entityType: note.entityType.name,
              createdAt: note.createdAt,
              updatedAt: note.updatedAt,
              lifecycle: note.lifecycle.name,
              version: note.version,
              source: note.source.name,
            ),
          );
      await _database
          .into(_database.noteRecords)
          .insertOnConflictUpdate(
            NoteRecordsCompanion.insert(
              entityId: note.id.value,
              title: note.title,
              content: note.content,
            ),
          );
      await _database
          .into(_database.outboxEntries)
          .insert(
            OutboxEntriesCompanion.insert(
              changeId: _changeIdGenerator(),
              entityId: note.id.value,
              deviceId: _deviceId,
              operation: existing == null ? 'CREATE' : 'UPDATE',
              baseVersion: Value(existing?.version),
              newVersion: note.version,
              payload: LifeOsNoteMapper.toJsonSnapshot(note),
              schemaVersion: _changeSchemaVersion,
              status: _pendingStatus,
              attemptCount: 0,
              createdAt: note.updatedAt,
              lastAttemptAt: const Value.absent(),
            ),
          );
    });
  }

  LifeOsNote _mapNote(TypedResult row) => LifeOsNoteMapper.toDomain(
    row.readTable(_database.entities),
    row.readTable(_database.noteRecords),
  );
}
