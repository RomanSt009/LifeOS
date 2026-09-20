import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_workspace_membership.dart';
import '../../domain/repositories/lifeos_workspace_membership_repository.dart';
import 'create_lifeos_task.dart' show EntityIdGenerator, UtcClock;

final class AttachLifeOsWorkspaceMember {
  const AttachLifeOsWorkspaceMember({
    required this.repository,
    required this.entityIdGenerator,
    required this.utcClock,
  });

  final LifeOsWorkspaceMembershipRepository repository;
  final EntityIdGenerator entityIdGenerator;
  final UtcClock utcClock;

  Future<LifeOsWorkspaceMembership> call({
    required LifeOsEntityId workspaceId,
    required LifeOsEntityId memberEntityId,
  }) => repository.attach(
    workspaceId: workspaceId,
    memberEntityId: memberEntityId,
    newMembershipId: LifeOsEntityId(
      value: entityIdGenerator(),
      entityType: LifeOsEntityType.workspaceMembership,
    ),
    timestamp: utcClock(),
  );
}

final class DetachLifeOsWorkspaceMember {
  const DetachLifeOsWorkspaceMember({
    required this.repository,
    required this.utcClock,
  });

  final LifeOsWorkspaceMembershipRepository repository;
  final UtcClock utcClock;

  Future<LifeOsWorkspaceMembership?> call(LifeOsEntityId membershipId) =>
      repository.remove(membershipId: membershipId, timestamp: utcClock());
}
