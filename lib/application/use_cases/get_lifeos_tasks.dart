import '../../domain/entities/lifeos_task.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../domain/repositories/lifeos_task_repository.dart';

class GetLifeOsTasks {
  const GetLifeOsTasks(this._repository);

  final LifeOsTaskRepository _repository;

  Future<List<LifeOsTask>> call() =>
      _repository.getByLifecycle(LifeOsEntityLifecycle.active);
}

class GetDeletedLifeOsTasks {
  const GetDeletedLifeOsTasks(this._repository);

  final LifeOsTaskRepository _repository;

  Future<List<LifeOsTask>> call() =>
      _repository.getByLifecycle(LifeOsEntityLifecycle.deleted);
}
