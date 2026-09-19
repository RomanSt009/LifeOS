import '../entities/lifeos_entity.dart';
import '../entities/lifeos_workspace.dart';

abstract interface class LifeOsWorkspaceRepository {
  Future<List<LifeOsWorkspace>> getAll();
  Future<LifeOsWorkspace?> getById(LifeOsEntityId id);
  Future<List<LifeOsWorkspace>> getByLifecycle(LifeOsEntityLifecycle lifecycle);
  Future<void> save(LifeOsWorkspace workspace);
}
