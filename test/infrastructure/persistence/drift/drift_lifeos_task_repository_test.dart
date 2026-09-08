import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
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
  }) {
    return LifeOsTask(
      id: id,
      title: title,
      isCompleted: isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lifecycle: LifeOsEntityLifecycle.active,
      version: version,
      source: LifeOsEntitySource.user,
    );
  }

  setUp(() {
    database = LifeOsDatabase(NativeDatabase.memory());
    changeIds = ['change-1', 'change-2'];
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
    final updated = createTask(
      title: 'Persist the first Task',
      isCompleted: true,
      updatedAt: secondUpdatedAt,
      version: 2,
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
  });

  test('returns null for a missing typed id', () async {
    const missingId = LifeOsEntityId(
      value: 'missing-task',
      entityType: LifeOsEntityType.task,
    );

    expect(await repository.getById(missingId), isNull);
  });

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
