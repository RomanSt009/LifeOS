import '../entities/lifeos_entity.dart';
import '../entities/lifeos_task.dart';

abstract interface class LifeOsTaskRepository {
  Future<LifeOsTask?> getById(LifeOsEntityId id);

  Future<List<LifeOsTask>> getAll();

  /// Searches active Tasks by title using a trimmed, non-empty query.
  Future<List<LifeOsTask>> searchByTitle(String query);

  Future<void> save(LifeOsTask task);
}
