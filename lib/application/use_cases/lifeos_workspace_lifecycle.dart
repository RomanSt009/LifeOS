import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_workspace.dart';
import '../../domain/repositories/lifeos_workspace_repository.dart';
import 'create_lifeos_task.dart' show UtcClock;

final class DeleteLifeOsWorkspace {
  const DeleteLifeOsWorkspace({
    required this.repository,
    required this.utcClock,
  });
  final LifeOsWorkspaceRepository repository;
  final UtcClock utcClock;

  Future<LifeOsWorkspace?> call(LifeOsEntityId id) =>
      _mutateWorkspace(repository, id, utcClock, (value, timestamp) {
        return value.delete(updatedAt: timestamp);
      });
}

final class RestoreLifeOsWorkspace {
  const RestoreLifeOsWorkspace({
    required this.repository,
    required this.utcClock,
  });
  final LifeOsWorkspaceRepository repository;
  final UtcClock utcClock;

  Future<LifeOsWorkspace?> call(LifeOsEntityId id) =>
      _mutateWorkspace(repository, id, utcClock, (value, timestamp) {
        return value.restore(updatedAt: timestamp);
      });
}

Future<LifeOsWorkspace?> _mutateWorkspace(
  LifeOsWorkspaceRepository repository,
  LifeOsEntityId id,
  UtcClock utcClock,
  LifeOsWorkspace Function(LifeOsWorkspace, DateTime) mutation,
) async {
  final current = await repository.getById(id);
  if (current == null) return null;
  final result = mutation(current, utcClock());
  if (!identical(result, current)) await repository.save(result);
  return result;
}
