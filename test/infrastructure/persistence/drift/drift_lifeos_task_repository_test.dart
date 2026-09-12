import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/toggle_stored_task_completion.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_task_title.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/mappers/lifeos_task_mapper.dart';
import 'package:lifeos/infrastructure/persistence/drift/repositories/drift_lifeos_task_repository.dart';

void main() {
  late LifeOsDatabase database;
  late DriftLifeOsTaskRepository repository;
  late List<String> changeIds;

  const taskId = LifeOsEntityId(
    value: 'task-1',
    entityType: LifeOsEntityType.task,
  );
  final createdAt = DateTime.utc(2026, 9, 6, 10);
  final firstUpdatedAt = DateTime.utc(2026, 9, 6, 11);
  final secondUpdatedAt = DateTime.utc(2026, 9, 6, 12);

  LifeOsTask createTask({
    LifeOsEntityId id = taskId,
    required String title,
    required bool isCompleted,
    required DateTime updatedAt,
    required int version,
    LifeOsEntityLifecycle lifecycle = LifeOsEntityLifecycle.active,
  }) {
    return LifeOsTask(
      id: id,
      title: title,
      isCompleted: isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lifecycle: lifecycle,
      version: version,
      source: LifeOsEntitySource.user,
    );
  }

  setUp(() {
    database = LifeOsDatabase(NativeDatabase.memory());
    changeIds = List.generate(10, (index) => 'change-${index + 1}');
    repository = DriftLifeOsTaskRepository(
      database,
      () => changeIds.removeAt(0),
      'device-test',
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'saves and loads every Task field with an atomic outbox entry',
    () async {
      final task = createTask(
        title: 'Persist the first Task',
        isCompleted: false,
        updatedAt: firstUpdatedAt,
        version: 1,
      );

      await repository.save(task);
      final loaded = await repository.getById(taskId);
      final outbox = await database.select(database.outboxEntries).getSingle();
      final payload = jsonDecode(outbox.payload) as Map<String, dynamic>;

      expect(loaded, isNotNull);
      expect(loaded!.id, task.id);
      expect(loaded.entityType, task.entityType);
      expect(loaded.title, task.title);
      expect(loaded.isCompleted, task.isCompleted);
      expect(loaded.createdAt, task.createdAt);
      expect(loaded.updatedAt, task.updatedAt);
      expect(loaded.lifecycle, task.lifecycle);
      expect(loaded.version, task.version);
      expect(loaded.source, task.source);
      expect(outbox.changeId, 'change-1');
      expect(outbox.entityId, taskId.value);
      expect(outbox.deviceId, 'device-test');
      expect(outbox.operation, 'CREATE');
      expect(outbox.baseVersion, isNull);
      expect(outbox.newVersion, 1);
      expect(outbox.schemaVersion, 1);
      expect(outbox.status, 'PENDING');
      expect(outbox.attemptCount, 0);
      expect(outbox.createdAt.isAtSameMomentAs(firstUpdatedAt), isTrue);
      expect(outbox.lastAttemptAt, isNull);
      expect(payload, {
        'id': taskId.value,
        'entityType': 'task',
        'title': 'Persist the first Task',
        'isCompleted': false,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': firstUpdatedAt.toIso8601String(),
        'lifecycle': 'active',
        'version': 1,
        'source': 'user',
      });
    },
  );

  test('updates stored state and creates a versioned update change', () async {
    final original = createTask(
      title: 'Persist the first Task',
      isCompleted: false,
      updatedAt: firstUpdatedAt,
      version: 1,
    );
    final updated = original.editTitle(
      title: 'Edited Task title',
      updatedAt: secondUpdatedAt,
    );

    await repository.save(original);
    await repository.save(updated);

    final loaded = await repository.getById(taskId);
    final outbox = await (database.select(
      database.outboxEntries,
    )..where((entry) => entry.changeId.equals('change-2'))).getSingle();

    expect(loaded, isNotNull);
    expect(loaded!.id, updated.id);
    expect(loaded.title, updated.title);
    expect(loaded.isCompleted, updated.isCompleted);
    expect(loaded.createdAt, updated.createdAt);
    expect(loaded.updatedAt, updated.updatedAt);
    expect(loaded.lifecycle, updated.lifecycle);
    expect(loaded.version, updated.version);
    expect(loaded.source, updated.source);
    expect(outbox.operation, 'UPDATE');
    expect(outbox.baseVersion, 1);
    expect(outbox.newVersion, 2);
    expect(outbox.createdAt.isAtSameMomentAs(secondUpdatedAt), isTrue);
    expect(jsonDecode(outbox.payload), {
      'id': taskId.value,
      'entityType': 'task',
      'title': 'Edited Task title',
      'isCompleted': false,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': secondUpdatedAt.toIso8601String(),
      'lifecycle': 'active',
      'version': 2,
      'source': 'user',
    });
  });

  test(
    'does not create an Outbox change for a normalized no-op edit',
    () async {
      final original = createTask(
        title: 'No-op title',
        isCompleted: false,
        updatedAt: firstUpdatedAt,
        version: 1,
      );
      await repository.save(original);

      final result = await EditLifeOsTaskTitle(
        repository: repository,
        utcClock: () => secondUpdatedAt,
      )(taskId, title: '  No-op title  ');

      expect(result, original);
      expect(await repository.getById(taskId), original);
      expect(await database.select(database.outboxEntries).get(), hasLength(1));
    },
  );

  test(
    'reports persisted Task state that violates Domain invariants',
    () async {
      await database
          .into(database.entities)
          .insert(
            EntitiesCompanion.insert(
              id: taskId.value,
              entityType: LifeOsEntityType.task.name,
              createdAt: createdAt,
              updatedAt: createdAt,
              lifecycle: LifeOsEntityLifecycle.active.name,
              version: 0,
              source: LifeOsEntitySource.user.name,
            ),
          );
      await database
          .into(database.taskRecords)
          .insert(
            TaskRecordsCompanion.insert(
              entityId: taskId.value,
              title: 'Invalid version',
              isCompleted: false,
            ),
          );

      await expectLater(
        repository.getById(taskId),
        throwsA(isA<LifeOsTaskMappingException>()),
      );
    },
  );

  test('returns null for a missing typed id', () async {
    const missingId = LifeOsEntityId(
      value: 'missing-task',
      entityType: LifeOsEntityType.task,
    );

    expect(await repository.getById(missingId), isNull);
  });

  test(
    'reports persisted Task state that violates Domain invariants',
    () async {
      await database
          .into(database.entities)
          .insert(
            EntitiesCompanion.insert(
              id: taskId.value,
              entityType: LifeOsEntityType.task.name,
              createdAt: createdAt,
              updatedAt: createdAt,
              lifecycle: LifeOsEntityLifecycle.active.name,
              version: 0,
              source: LifeOsEntitySource.user.name,
            ),
          );
      await database
          .into(database.taskRecords)
          .insert(
            TaskRecordsCompanion.insert(
              entityId: taskId.value,
              title: 'Invalid version',
              isCompleted: false,
            ),
          );

      await expectLater(
        repository.getById(taskId),
        throwsA(isA<LifeOsTaskMappingException>()),
      );
    },
  );

  test('returns an empty Task collection for an empty database', () async {
    expect(await repository.getAll(), isEmpty);
  });

  test('loads the mapped Task collection', () async {
    final firstTask = createTask(
      title: 'First Task',
      isCompleted: false,
      updatedAt: firstUpdatedAt,
      version: 1,
    );
    final secondTask = createTask(
      id: const LifeOsEntityId(
        value: 'task-2',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Second Task',
      isCompleted: true,
      updatedAt: secondUpdatedAt,
      version: 2,
    );

    await repository.save(firstTask);
    await repository.save(secondTask);

    expect(await repository.getAll(), unorderedEquals([firstTask, secondTask]));
  });

  test('searches active title substrings case-insensitively in deterministic order', () async {
    final olderMatch = createTask(
      id: const LifeOsEntityId(
        value: 'task-c',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Plan Flutter desktop',
      isCompleted: false,
      updatedAt: DateTime.utc(2026, 9, 6, 12),
      version: 1,
    );
    final tiedMatchB = createTask(
      id: const LifeOsEntityId(
        value: 'task-b',
        entityType: LifeOsEntityType.task,
      ),
      title: 'FLUTTER persistence',
      isCompleted: true,
      updatedAt: DateTime.utc(2026, 9, 6, 13),
      version: 2,
    );
    final tiedMatchA = createTask(
      id: const LifeOsEntityId(
        value: 'task-a',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Test flutter search',
      isCompleted: false,
      updatedAt: DateTime.utc(2026, 9, 6, 13),
      version: 3,
    );
    final nonMatch = createTask(
      id: const LifeOsEntityId(
        value: 'task-d',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Write persistence tests',
      isCompleted: false,
      updatedAt: DateTime.utc(2026, 9, 6, 14),
      version: 1,
    );
    final archivedMatch = createTask(
      id: const LifeOsEntityId(
        value: 'task-archived',
        entityType: LifeOsEntityType.task,
      ),
      title: 'Archived Flutter Task',
      isCompleted: false,
      updatedAt: DateTime.utc(2026, 9, 6, 15),
      version: 1,
      lifecycle: LifeOsEntityLifecycle.archived,
    );
    for (final task in [
      olderMatch,
      tiedMatchB,
      tiedMatchA,
      nonMatch,
      archivedMatch,
    ]) {
      await repository.save(task);
    }
    final outboxBeforeSearch = await database
        .select(database.outboxEntries)
        .get();

    final results = await repository.searchByTitle('fLuTtEr');
    final outboxAfterSearch = await database
        .select(database.outboxEntries)
        .get();

    expect(results, [tiedMatchA, tiedMatchB, olderMatch]);
    expect(results.map((task) => task.id).toSet(), hasLength(results.length));
    expect(results.first.id, tiedMatchA.id);
    expect(results.first.createdAt, tiedMatchA.createdAt);
    expect(results.first.updatedAt, tiedMatchA.updatedAt);
    expect(results.first.lifecycle, tiedMatchA.lifecycle);
    expect(results.first.version, tiedMatchA.version);
    expect(results.first.source, tiedMatchA.source);
    expect(outboxAfterSearch, outboxBeforeSearch);
  });

  test(
    'matches Cyrillic case variants and literal wildcard characters',
    () async {
      final cyrillicTask = createTask(
        title: r'Проверить 100% _ путь\поиска',
        isCompleted: false,
        updatedAt: firstUpdatedAt,
        version: 1,
      );
      final ordinaryTask = createTask(
        id: const LifeOsEntityId(
          value: 'task-ordinary',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Обычная задача без специальных символов',
        isCompleted: false,
        updatedAt: secondUpdatedAt,
        version: 1,
      );
      await repository.save(cyrillicTask);
      await repository.save(ordinaryTask);

      expect(await repository.searchByTitle('ПРОВЕРИТЬ'), [cyrillicTask]);
      expect(await repository.searchByTitle(r'100% _ путь\'), [cyrillicTask]);
      expect(await repository.searchByTitle('%'), [cyrillicTask]);
      expect(await repository.searchByTitle('_'), [cyrillicTask]);
      expect(await repository.searchByTitle(r'\'), [cyrillicTask]);
    },
  );

  test('returns updated Task data on a later read-only search', () async {
    final original = createTask(
      title: 'Before update',
      isCompleted: false,
      updatedAt: firstUpdatedAt,
      version: 1,
    );
    await repository.save(original);
    expect(await repository.searchByTitle('before'), [original]);

    final updated = createTask(
      title: 'After update',
      isCompleted: true,
      updatedAt: secondUpdatedAt,
      version: 2,
    );
    await repository.save(updated);
    final outboxBeforeSearch = await database
        .select(database.outboxEntries)
        .get();

    expect(await repository.searchByTitle('before'), isEmpty);
    expect(await repository.searchByTitle('after'), [updated]);
    expect(
      (await repository.searchByTitle('after')).single.isCompleted,
      isTrue,
    );
    expect(
      await database.select(database.outboxEntries).get(),
      outboxBeforeSearch,
    );
  });

  test(
    'keeps a completed Task searchable without adding an Outbox entry',
    () async {
      final original = createTask(
        title: 'Keep searchable after completion',
        isCompleted: false,
        updatedAt: firstUpdatedAt,
        version: 1,
      );
      await repository.save(original);
      final completed = await ToggleStoredTaskCompletion(
        repository: repository,
      )(taskId, updatedAt: secondUpdatedAt);
      expect(completed, isNotNull);
      final completedTask = completed!;
      final outboxCountBeforeSearch = await database
          .select(database.outboxEntries)
          .get()
          .then((entries) => entries.length);

      final results = await repository.searchByTitle('searchable');

      expect(results, [completedTask]);
      expect(results.single.isCompleted, isTrue);
      expect(await database.select(database.outboxEntries).get(), hasLength(2));
      expect(outboxCountBeforeSearch, 2);
    },
  );

  test('rolls back Domain State when the outbox write fails', () async {
    final original = createTask(
      title: 'Original title',
      isCompleted: false,
      updatedAt: firstUpdatedAt,
      version: 1,
    );
    final updated = createTask(
      title: 'Updated title',
      isCompleted: true,
      updatedAt: secondUpdatedAt,
      version: 2,
    );
    await repository.save(original);
    final duplicateChangeRepository = DriftLifeOsTaskRepository(
      database,
      () => 'change-1',
      'device-test',
    );

    await expectLater(
      duplicateChangeRepository.save(updated),
      throwsA(anything),
    );

    expect(await repository.getById(taskId), original);
    expect(await database.select(database.outboxEntries).get(), hasLength(1));
  });
}
