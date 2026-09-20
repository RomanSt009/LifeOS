import '../../domain/entities/lifeos_entity.dart';
import '../workspaces/lifeos_workspace_context_reader.dart';

final class GetLifeOsWorkspaceMembers {
  const GetLifeOsWorkspaceMembers(this._reader);
  final LifeOsWorkspaceContextReader _reader;

  Future<List<LifeOsWorkspaceMember>> call(LifeOsEntityId workspaceId) =>
      _reader.getDirectMembers(workspaceId);
}

final class GetUnassignedLifeOsWorkspaceMembers {
  const GetUnassignedLifeOsWorkspaceMembers(this._reader);
  final LifeOsWorkspaceContextReader _reader;

  Future<List<LifeOsWorkspaceMember>> call() => _reader.getUnassigned();
}
