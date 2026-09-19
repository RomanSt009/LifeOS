import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_workspace.dart';

void main() {
  const id = LifeOsEntityId(
    value: 'workspace-1',
    entityType: LifeOsEntityType.workspace,
  );
  final createdAt = DateTime.utc(2026, 9, 19, 10);

  LifeOsWorkspace create({String title = ' Work ', String? description}) =>
      LifeOsWorkspace.createUserWorkspace(
        id: id,
        title: title,
        description: description,
        timestamp: createdAt,
      );

  test('creates a normalized user Workspace and preserves description', () {
    final workspace = create(description: '  exact\r\ntext  ');
    expect(workspace.title, 'Work');
    expect(workspace.description, '  exact\r\ntext  ');
    expect(workspace.createdAt, createdAt);
    expect(workspace.updatedAt, createdAt);
    expect(workspace.lifecycle, LifeOsEntityLifecycle.active);
    expect(workspace.version, 1);
    expect(workspace.source, LifeOsEntitySource.user);
  });

  test('preserves null and empty descriptions as distinct values', () {
    expect(create(description: null).description, isNull);
    expect(create(description: '').description, '');
  });

  test('rejects invalid identity, title, timestamps, and version', () {
    expect(
      () => LifeOsWorkspace.createUserWorkspace(
        id: const LifeOsEntityId(
          value: 'task-1',
          entityType: LifeOsEntityType.task,
        ),
        title: 'Workspace',
        description: null,
        timestamp: createdAt,
      ),
      throwsArgumentError,
    );
    expect(() => create(title: '   '), throwsArgumentError);
    expect(
      () => LifeOsWorkspace(
        id: id,
        title: ' Not normalized ',
        description: null,
        createdAt: createdAt,
        updatedAt: createdAt,
        lifecycle: LifeOsEntityLifecycle.active,
        version: 1,
        source: LifeOsEntitySource.user,
      ),
      throwsArgumentError,
    );
    expect(
      () => LifeOsWorkspace(
        id: id,
        title: 'Workspace',
        description: null,
        createdAt: DateTime(2026),
        updatedAt: createdAt,
        lifecycle: LifeOsEntityLifecycle.active,
        version: 1,
        source: LifeOsEntitySource.user,
      ),
      throwsArgumentError,
    );
    expect(
      () => LifeOsWorkspace(
        id: id,
        title: 'Workspace',
        description: null,
        createdAt: createdAt,
        updatedAt: createdAt.subtract(const Duration(seconds: 1)),
        lifecycle: LifeOsEntityLifecycle.active,
        version: 0,
        source: LifeOsEntitySource.user,
      ),
      throwsArgumentError,
    );
  });

  test('edit is immutable, normalized, versioned, and detects true no-op', () {
    final original = create(description: null);
    final noOp = original.edit(
      title: '  Work  ',
      description: null,
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );
    expect(identical(noOp, original), isTrue);
    final edited = original.edit(
      title: ' Home ',
      description: '',
      updatedAt: createdAt.add(const Duration(minutes: 2)),
    );
    expect(edited.title, 'Home');
    expect(edited.description, '');
    expect(edited.version, 2);
    expect(edited.updatedAt, createdAt.add(const Duration(minutes: 2)));
    expect(original.title, 'Work');
  });

  test('edit requires active lifecycle and monotonic UTC time', () {
    final original = create();
    final archived = original.archive(
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );
    expect(
      () => archived.edit(
        title: 'New',
        description: null,
        updatedAt: createdAt.add(const Duration(minutes: 2)),
      ),
      throwsStateError,
    );
    expect(
      () => original.edit(
        title: 'New',
        description: null,
        updatedAt: createdAt.subtract(const Duration(seconds: 1)),
      ),
      throwsArgumentError,
    );
  });

  test('supports accepted lifecycle transitions and no-ops', () {
    final active = create(description: 'kept');
    final archived = active.archive(
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );
    expect(archived.lifecycle, LifeOsEntityLifecycle.archived);
    expect(archived.version, 2);
    expect(
      identical(
        archived.archive(updatedAt: createdAt.add(const Duration(minutes: 2))),
        archived,
      ),
      isTrue,
    );
    final unarchived = archived.unarchive(
      updatedAt: createdAt.add(const Duration(minutes: 2)),
    );
    final deleted = unarchived.delete(
      updatedAt: createdAt.add(const Duration(minutes: 3)),
    );
    final restored = deleted.restore(
      updatedAt: createdAt.add(const Duration(minutes: 4)),
    );
    expect(restored.lifecycle, LifeOsEntityLifecycle.active);
    expect(restored.description, 'kept');
    expect(restored.version, 5);
    expect(
      () =>
          deleted.archive(updatedAt: createdAt.add(const Duration(minutes: 4))),
      throwsStateError,
    );
  });
}
