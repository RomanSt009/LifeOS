import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_workspace.dart';
import '../../domain/repositories/lifeos_workspace_repository.dart';

final class GetLifeOsWorkspace {
  const GetLifeOsWorkspace(this._repository);
  final LifeOsWorkspaceRepository _repository;

  Future<LifeOsWorkspace?> call(LifeOsEntityId id) => _repository.getById(id);
}

final class GetLifeOsWorkspaces {
  const GetLifeOsWorkspaces(this._repository);
  final LifeOsWorkspaceRepository _repository;

  Future<List<LifeOsWorkspace>> call() =>
      _repository.getByLifecycle(LifeOsEntityLifecycle.active);
}

final class GetDeletedLifeOsWorkspaces {
  const GetDeletedLifeOsWorkspaces(this._repository);
  final LifeOsWorkspaceRepository _repository;

  Future<List<LifeOsWorkspace>> call() =>
      _repository.getByLifecycle(LifeOsEntityLifecycle.deleted);
}
