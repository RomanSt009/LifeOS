import '../entities/lifeos_entity.dart';
import '../entities/lifeos_task.dart';

abstract interface class LifeOsTaskRepository {
  Future<LifeOsTask?> getById(LifeOsEntityId id);

  Future<List<LifeOsTask>> getAll();

  Future<void> save(LifeOsTask task);
}
