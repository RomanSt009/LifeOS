import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_workspace_membership.dart';

void main() {
  const membershipId = LifeOsEntityId(
    value: 'membership-1',
    entityType: LifeOsEntityType.workspaceMembership,
  );
  const workspaceId = LifeOsEntityId(
    value: 'workspace-1',
    entityType: LifeOsEntityType.workspace,
  );
  const taskId = LifeOsEntityId(
    value: 'task-1',
    entityType: LifeOsEntityType.task,
  );
  const noteId = LifeOsEntityId(
    value: 'note-1',
    entityType: LifeOsEntityType.note,
  );
  final createdAt = DateTime.utc(2026, 9, 19, 10);

  LifeOsWorkspaceMembership create([LifeOsEntityId member = taskId]) =>
      LifeOsWorkspaceMembership.createUserMembership(
        id: membershipId,
        workspaceId: workspaceId,
        memberEntityId: member,
        timestamp: createdAt,
      );

  test('creates Task and Note memberships with user defaults', () {
    for (final member in [taskId, noteId]) {
      final membership = create(member);
      expect(membership.memberEntityId, member);
      expect(membership.lifecycle, LifeOsEntityLifecycle.active);
      expect(membership.version, 1);
      expect(membership.createdAt, membership.updatedAt);
      expect(membership.source, LifeOsEntitySource.user);
    }
  });

  test('rejects wrong identity and endpoint types', () {
    expect(
      () => LifeOsWorkspaceMembership.createUserMembership(
        id: const LifeOsEntityId(
          value: 'wrong',
          entityType: LifeOsEntityType.relationship,
        ),
        workspaceId: workspaceId,
        memberEntityId: taskId,
        timestamp: createdAt,
      ),
      throwsArgumentError,
    );
    expect(
      () => LifeOsWorkspaceMembership.createUserMembership(
        id: membershipId,
        workspaceId: taskId,
        memberEntityId: noteId,
        timestamp: createdAt,
      ),
      throwsArgumentError,
    );
    expect(
      () => LifeOsWorkspaceMembership.createUserMembership(
        id: membershipId,
        workspaceId: workspaceId,
        memberEntityId: const LifeOsEntityId(
          value: 'relationship-1',
          entityType: LifeOsEntityType.relationship,
        ),
        timestamp: createdAt,
      ),
      throwsArgumentError,
    );
  });

  test('rejects archived, invalid timestamps, and invalid version', () {
    expect(
      () => LifeOsWorkspaceMembership(
        id: membershipId,
        workspaceId: workspaceId,
        memberEntityId: taskId,
        createdAt: createdAt,
        updatedAt: createdAt,
        lifecycle: LifeOsEntityLifecycle.archived,
        version: 1,
        source: LifeOsEntitySource.user,
      ),
      throwsArgumentError,
    );
    expect(
      () => LifeOsWorkspaceMembership(
        id: membershipId,
        workspaceId: workspaceId,
        memberEntityId: taskId,
        createdAt: createdAt,
        updatedAt: createdAt.subtract(const Duration(seconds: 1)),
        lifecycle: LifeOsEntityLifecycle.active,
        version: 0,
        source: LifeOsEntitySource.user,
      ),
      throwsArgumentError,
    );
  });

  test('remove and reattach preserve identity and immutable endpoints', () {
    final active = create();
    final removed = active.remove(
      updatedAt: createdAt.add(const Duration(minutes: 1)),
    );
    expect(removed.lifecycle, LifeOsEntityLifecycle.deleted);
    expect(removed.version, 2);
    expect(removed.id, active.id);
    expect(removed.workspaceId, active.workspaceId);
    expect(removed.memberEntityId, active.memberEntityId);
    expect(
      identical(
        removed.remove(updatedAt: createdAt.add(const Duration(minutes: 2))),
        removed,
      ),
      isTrue,
    );
    final reattached = removed.reattach(
      updatedAt: createdAt.add(const Duration(minutes: 2)),
    );
    expect(reattached.lifecycle, LifeOsEntityLifecycle.active);
    expect(reattached.version, 3);
    expect(reattached.id, membershipId);
    expect(
      identical(
        reattached.reattach(
          updatedAt: createdAt.add(const Duration(minutes: 3)),
        ),
        reattached,
      ),
      isTrue,
    );
  });

  test('mutations require UTC non-decreasing timestamps', () {
    final membership = create();
    expect(
      () => membership.remove(
        updatedAt: createdAt.subtract(const Duration(seconds: 1)),
      ),
      throwsArgumentError,
    );
    expect(
      () => membership.remove(updatedAt: DateTime(2026, 9, 19, 11)),
      throwsArgumentError,
    );
    expect(
      () => membership.reattach(
        updatedAt: createdAt.subtract(const Duration(seconds: 1)),
      ),
      throwsArgumentError,
    );
  });
}
