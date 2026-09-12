import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/mappers/lifeos_task_mapper.dart';

void main() {
  final createdAt = DateTime.utc(2026, 9, 13, 10);

  EntityRecord entity({
    String id = 'task-a',
    String entityType = 'task',
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

  TaskRecord typed({String entityId = 'task-a', String title = 'Task title'}) =>
      TaskRecord(entityId: entityId, title: title, isCompleted: false);

  test('maps a valid persisted Task to the typed Domain entity', () {
    final result = LifeOsTaskMapper.toDomain(entity(), typed());

    expect(result.id.entityType, LifeOsEntityType.task);
    expect(result.title, 'Task title');
    expect(result.createdAt, same(createdAt));
  });

  test('rejects corrupt persisted Task shapes with a typed error', () {
    final cases = <(EntityRecord, TaskRecord)>[
      (entity(entityType: 'note'), typed()),
      (entity(), typed(entityId: 'task-b')),
      (entity(), typed(title: ' padded ')),
      (entity(), typed(title: '')),
      (entity(version: 0), typed()),
      (
        entity(updated: createdAt.subtract(const Duration(seconds: 1))),
        typed(),
      ),
      (entity(lifecycle: 'unknown'), typed()),
      (entity(source: 'unknown'), typed()),
    ];

    for (final (entityRecord, taskRecord) in cases) {
      expect(
        () => LifeOsTaskMapper.toDomain(entityRecord, taskRecord),
        throwsA(isA<LifeOsTaskMappingException>()),
      );
    }
  });
}
