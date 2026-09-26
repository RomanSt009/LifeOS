import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/search/lifeos_search_result.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_workspace.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_note_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_task_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_workspace_repository.dart';
import 'package:lifeos/infrastructure/persistence/drift/search/drift_lifeos_unified_search_reader.dart';

void main() {
  late LifeOsDatabase database;
  late DriftLifeOsUnifiedSearchReader reader;
  late _SelectCounter selectCounter;
  late int changeSequence;

  String nextChangeId() => 'change-${++changeSequence}';

  setUp(() {
    selectCounter = _SelectCounter();
    database = LifeOsDatabase(
      NativeDatabase.memory().interceptWith(selectCounter),
    );
    reader = DriftLifeOsUnifiedSearchReader(database);
    changeSequence = 0;
  });

  tearDown(() => database.close());

  test(
    'returns one globally ordered bounded mixed read without mutations',
    () async {
      final taskRepository = DriftLifeOsTaskRepository(
        database,
        nextChangeId,
        'device-test',
      );
      final noteRepository = DriftLifeOsNoteRepository(
        database,
        nextChangeId,
        'device-test',
      );
      final workspaceRepository = DriftLifeOsWorkspaceRepository(
        database,
        nextChangeId,
        'device-test',
      );
      final createdAt = DateTime.utc(2026, 9, 26, 10);
      final task = LifeOsTask(
        id: const LifeOsEntityId(
          value: 'task-result',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Shared completed Task',
        isCompleted: true,
        createdAt: createdAt,
        updatedAt: DateTime.utc(2026, 9, 26, 11),
        lifecycle: LifeOsEntityLifecycle.active,
        version: 2,
        source: LifeOsEntitySource.user,
      );
      final note = LifeOsNote(
        id: const LifeOsEntityId(
          value: 'note-result',
          entityType: LifeOsEntityType.note,
        ),
        title: 'Reference',
        content: r'SHARED content with 100% _ path\',
        createdAt: createdAt,
        updatedAt: DateTime.utc(2026, 9, 26, 13),
        lifecycle: LifeOsEntityLifecycle.active,
        version: 1,
        source: LifeOsEntitySource.user,
      );
      final workspace = LifeOsWorkspace(
        id: const LifeOsEntityId(
          value: 'workspace-result',
          entityType: LifeOsEntityType.workspace,
        ),
        title: 'Planning',
        description: 'Shared workspace description',
        createdAt: DateTime.utc(2026, 9, 26, 12),
        updatedAt: DateTime.utc(2026, 9, 26, 12),
        lifecycle: LifeOsEntityLifecycle.active,
        version: 1,
        source: LifeOsEntitySource.user,
      );
      final archivedNote = LifeOsNote(
        id: const LifeOsEntityId(
          value: 'note-archived',
          entityType: LifeOsEntityType.note,
        ),
        title: 'Shared archived Note',
        content: '',
        createdAt: createdAt,
        updatedAt: DateTime.utc(2026, 9, 26, 14),
        lifecycle: LifeOsEntityLifecycle.archived,
        version: 2,
        source: LifeOsEntitySource.user,
      );
      final deletedTask = LifeOsTask(
        id: const LifeOsEntityId(
          value: 'task-deleted',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Shared deleted Task',
        isCompleted: false,
        createdAt: createdAt,
        updatedAt: DateTime.utc(2026, 9, 26, 15),
        lifecycle: LifeOsEntityLifecycle.deleted,
        version: 2,
        source: LifeOsEntitySource.user,
      );

      await taskRepository.save(task);
      await taskRepository.save(deletedTask);
      await noteRepository.save(note);
      await noteRepository.save(archivedNote);
      await workspaceRepository.save(workspace);
      final outboxBeforeSearch = await database
          .select(database.outboxEntries)
          .get();
      selectCounter.reset();

      final results = await reader.search(query: 'sHaReD', limit: 50);

      expect(results, hasLength(3));
      expect(results[0], isA<LifeOsNoteSearchResult>());
      expect(results[0].entityId, note.id);
      expect(results[1], isA<LifeOsWorkspaceSearchResult>());
      expect(results[1].entityId, workspace.id);
      expect(results[2], isA<LifeOsTaskSearchResult>());
      expect(results[2].entityId, task.id);
      expect((results[2] as LifeOsTaskSearchResult).task.isCompleted, isTrue);
      expect(selectCounter.count, 1);
      final searchSql = selectCounter.statements.single;
      final searchArguments = selectCounter.arguments.single;
      expect(
        searchSql.toLowerCase(),
        allOf(
          contains('glob('),
          contains('left outer join'),
          contains('order by'),
          contains('limit 50'),
        ),
      );
      final queryPlan = await database
          .customSelect(
            'EXPLAIN QUERY PLAN $searchSql',
            variables: searchArguments
                .map((argument) => Variable(argument))
                .toList(),
          )
          .get();
      final queryPlanDetails = queryPlan
          .map((row) => row.read<String>('detail').toLowerCase())
          .join('\n');
      expect(queryPlanDetails, contains('tasks'));
      expect(queryPlanDetails, contains('notes'));
      expect(queryPlanDetails, contains('workspaces'));
      expect(
        await database.select(database.outboxEntries).get(),
        outboxBeforeSearch,
      );
      expect(database.schemaVersion, 4);

      final limited = await reader.search(query: 'shared', limit: 2);
      expect(limited.map((result) => result.entityId), [note.id, workspace.id]);
      expect(
        (await reader.search(query: 'completed', limit: 50)).single.entityId,
        task.id,
      );
      expect(
        (await reader.search(query: 'reference', limit: 50)).single.entityId,
        note.id,
      );
      expect(
        (await reader.search(query: 'content', limit: 50)).single.entityId,
        note.id,
      );
      expect(
        (await reader.search(query: 'planning', limit: 50)).single.entityId,
        workspace.id,
      );
      expect(
        (await reader.search(query: 'description', limit: 50)).single.entityId,
        workspace.id,
      );
      expect(await reader.search(query: 'deleted', limit: 50), isEmpty);
    },
  );

  test(
    'orders equal timestamps by ID across types before global limit',
    () async {
      final taskRepository = DriftLifeOsTaskRepository(
        database,
        nextChangeId,
        'device-test',
      );
      final noteRepository = DriftLifeOsNoteRepository(
        database,
        nextChangeId,
        'device-test',
      );
      final workspaceRepository = DriftLifeOsWorkspaceRepository(
        database,
        nextChangeId,
        'device-test',
      );
      final timestamp = DateTime.utc(2026, 9, 26, 12);
      final task = LifeOsTask.createUserTask(
        id: const LifeOsEntityId(
          value: 'a-task',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Tie match',
        timestamp: timestamp,
      );
      final note = LifeOsNote.createUserNote(
        id: const LifeOsEntityId(
          value: 'b-note',
          entityType: LifeOsEntityType.note,
        ),
        title: 'Tie match',
        content: '',
        timestamp: timestamp,
      );
      final workspace = LifeOsWorkspace.createUserWorkspace(
        id: const LifeOsEntityId(
          value: 'c-workspace',
          entityType: LifeOsEntityType.workspace,
        ),
        title: 'Tie match',
        description: null,
        timestamp: timestamp,
      );
      await taskRepository.save(task);
      await noteRepository.save(note);
      await workspaceRepository.save(workspace);

      final results = await reader.search(query: 'tie', limit: 2);

      expect(results.map((result) => result.entityId), [task.id, note.id]);
      expect(results, hasLength(2));
    },
  );

  test('matches Cyrillic case and SQL wildcard characters literally', () async {
    final noteRepository = DriftLifeOsNoteRepository(
      database,
      nextChangeId,
      'device-test',
    );
    final note = LifeOsNote(
      id: const LifeOsEntityId(
        value: 'note-literal',
        entityType: LifeOsEntityType.note,
      ),
      title: 'Проверить поиск',
      content: r'Сохранить 100% _ путь\буквально',
      createdAt: DateTime.utc(2026, 9, 26, 10),
      updatedAt: DateTime.utc(2026, 9, 26, 10),
      lifecycle: LifeOsEntityLifecycle.active,
      version: 1,
      source: LifeOsEntitySource.user,
    );
    await noteRepository.save(note);

    expect(
      (await reader.search(query: 'ПРОВЕРИТЬ', limit: 50)).single.entityId,
      note.id,
    );
    expect(
      (await reader.search(query: '%', limit: 50)).single.entityId,
      note.id,
    );
    expect(
      (await reader.search(query: '_', limit: 50)).single.entityId,
      note.id,
    );
    expect(
      (await reader.search(query: r'\', limit: 50)).single.entityId,
      note.id,
    );
    expect(await reader.search(query: '%%', limit: 50), isEmpty);
  });

  test(
    'rejects a searchable Entity without its typed persistence row',
    () async {
      await database
          .into(database.entities)
          .insert(
            EntitiesCompanion.insert(
              id: 'corrupt-task',
              entityType: LifeOsEntityType.task.name,
              createdAt: DateTime.utc(2026, 9, 26),
              updatedAt: DateTime.utc(2026, 9, 26),
              lifecycle: LifeOsEntityLifecycle.active.name,
              version: 1,
              source: LifeOsEntitySource.user.name,
            ),
          );

      await expectLater(
        reader.search(query: 'anything', limit: 50),
        throwsA(isA<LifeOsUnifiedSearchPersistenceException>()),
      );
    },
  );
}

final class _SelectCounter extends QueryInterceptor {
  int count = 0;
  final List<String> statements = [];
  final List<List<Object?>> arguments = [];

  void reset() {
    count = 0;
    statements.clear();
    arguments.clear();
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    count += 1;
    statements.add(statement);
    arguments.add(List.unmodifiable(args));
    return executor.runSelect(statement, args);
  }
}
