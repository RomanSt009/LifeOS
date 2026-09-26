import 'package:drift/drift.dart';

import '../../../../application/search/lifeos_search_result.dart';
import '../../../../application/search/lifeos_unified_search_reader.dart';
import '../../../../domain/entities/lifeos_entity.dart';
import '../lifeos_database.dart';
import '../mappers/lifeos_note_mapper.dart';
import '../mappers/lifeos_task_mapper.dart';
import '../mappers/lifeos_workspace_mapper.dart';

final class LifeOsUnifiedSearchPersistenceException implements Exception {
  const LifeOsUnifiedSearchPersistenceException(this.message);

  final String message;

  @override
  String toString() => 'LifeOsUnifiedSearchPersistenceException: $message';
}

final class DriftLifeOsUnifiedSearchReader
    implements LifeOsUnifiedSearchReader {
  const DriftLifeOsUnifiedSearchReader(this._database);

  final LifeOsDatabase _database;

  @override
  Future<List<LifeOsSearchResult>> search({
    required String query,
    required int limit,
  }) async {
    if (query.isEmpty || query != query.trim()) {
      throw ArgumentError.value(
        query,
        'query',
        'The persistence query must be normalized and non-empty.',
      );
    }
    if (limit <= 0) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Search limit must be positive.',
      );
    }

    final globPattern = Variable.withString(_caseInsensitiveLiteralGlob(query));
    Expression<bool> matches(Expression<String> field) =>
        FunctionCallExpression<bool>('glob', [globPattern, field]);
    final taskType = _database.entities.entityType.equals(
      LifeOsEntityType.task.name,
    );
    final noteType = _database.entities.entityType.equals(
      LifeOsEntityType.note.name,
    );
    final workspaceType = _database.entities.entityType.equals(
      LifeOsEntityType.workspace.name,
    );
    final textMatch =
        (taskType & matches(_database.taskRecords.title)) |
        (noteType &
            (matches(_database.noteRecords.title) |
                matches(_database.noteRecords.content))) |
        (workspaceType &
            (matches(_database.workspaceRecords.title) |
                matches(_database.workspaceRecords.description)));
    final corruptTypedState =
        (taskType &
            (_database.taskRecords.entityId.isNull() |
                _database.noteRecords.entityId.isNotNull() |
                _database.workspaceRecords.entityId.isNotNull())) |
        (noteType &
            (_database.taskRecords.entityId.isNotNull() |
                _database.noteRecords.entityId.isNull() |
                _database.workspaceRecords.entityId.isNotNull())) |
        (workspaceType &
            (_database.taskRecords.entityId.isNotNull() |
                _database.noteRecords.entityId.isNotNull() |
                _database.workspaceRecords.entityId.isNull()));

    final mixedQuery =
        _database.select(_database.entities).join([
            leftOuterJoin(
              _database.taskRecords,
              _database.taskRecords.entityId.equalsExp(_database.entities.id),
            ),
            leftOuterJoin(
              _database.noteRecords,
              _database.noteRecords.entityId.equalsExp(_database.entities.id),
            ),
            leftOuterJoin(
              _database.workspaceRecords,
              _database.workspaceRecords.entityId.equalsExp(
                _database.entities.id,
              ),
            ),
          ])
          ..where(
            _database.entities.lifecycle.equals(
                  LifeOsEntityLifecycle.active.name,
                ) &
                (textMatch | corruptTypedState),
          )
          ..orderBy([
            OrderingTerm.desc(_database.entities.updatedAt),
            OrderingTerm.asc(_database.entities.id),
          ])
          ..limit(limit);

    final results = <LifeOsSearchResult>[];
    for (final row in await mixedQuery.get()) {
      results.add(_mapResult(row));
    }
    return List.unmodifiable(results);
  }

  LifeOsSearchResult _mapResult(TypedResult row) {
    final entity = row.readTable(_database.entities);
    final task = row.readTableOrNull(_database.taskRecords);
    final note = row.readTableOrNull(_database.noteRecords);
    final workspace = row.readTableOrNull(_database.workspaceRecords);

    switch (LifeOsEntityType.values.byName(entity.entityType)) {
      case LifeOsEntityType.task:
        if (task == null || note != null || workspace != null) {
          throw _corruptResult();
        }
        return LifeOsTaskSearchResult(LifeOsTaskMapper.toDomain(entity, task));
      case LifeOsEntityType.note:
        if (task != null || note == null || workspace != null) {
          throw _corruptResult();
        }
        return LifeOsNoteSearchResult(LifeOsNoteMapper.toDomain(entity, note));
      case LifeOsEntityType.workspace:
        if (task != null || note != null || workspace == null) {
          throw _corruptResult();
        }
        return LifeOsWorkspaceSearchResult(
          LifeOsWorkspaceMapper.toDomain(entity, workspace),
        );
      case LifeOsEntityType.relationship:
      case LifeOsEntityType.workspaceMembership:
        throw _corruptResult();
    }
  }
}

Never _corruptResult() => throw const LifeOsUnifiedSearchPersistenceException(
  'A searchable Entity has inconsistent typed persistence state.',
);

String _caseInsensitiveLiteralGlob(String query) {
  final pattern = StringBuffer('*');
  for (final rune in query.toLowerCase().runes) {
    final lower = String.fromCharCode(rune);
    final upper = lower.toUpperCase();
    if (upper != lower && upper.runes.length == 1) {
      pattern
        ..write('[')
        ..write(lower)
        ..write(upper)
        ..write(']');
    } else {
      pattern.write(switch (lower) {
        '*' => '[*]',
        '?' => '[?]',
        '[' => '[[]',
        ']' => '[]]',
        _ => lower,
      });
    }
  }
  pattern.write('*');
  return pattern.toString();
}
