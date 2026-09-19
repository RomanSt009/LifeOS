import '../entities/lifeos_entity.dart';
import '../entities/lifeos_workspace_membership.dart';

abstract interface class LifeOsWorkspaceMembershipRepository {
  Future<List<LifeOsWorkspaceMembership>> getAll();
  Future<LifeOsWorkspaceMembership?> getById(LifeOsEntityId id);
  Future<LifeOsWorkspaceMembership?> getByPair(
    LifeOsEntityId workspaceId,
    LifeOsEntityId memberEntityId,
  );
  Future<List<LifeOsWorkspaceMembership>> getActiveForWorkspace(
    LifeOsEntityId workspaceId,
  );
  Future<List<LifeOsWorkspaceMembership>> getActiveForMember(
    LifeOsEntityId memberEntityId,
  );
  Future<LifeOsWorkspaceMembership> attach({
    required LifeOsEntityId workspaceId,
    required LifeOsEntityId memberEntityId,
    required LifeOsEntityId newMembershipId,
    required DateTime timestamp,
  });
  Future<LifeOsWorkspaceMembership?> remove({
    required LifeOsEntityId membershipId,
    required DateTime timestamp,
  });
}
