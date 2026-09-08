import '../../domain/entities/lifeos_task.dart';
import '../../domain/repositories/lifeos_task_repository.dart';

class GetLifeOsTasks {
  const GetLifeOsTasks(this._repository);

  final LifeOsTaskRepository _repository;

  Future<List<LifeOsTask>> call() => _repository.getAll();
}
