import '../../domain/entities/lifeos_task.dart';
import '../../domain/repositories/lifeos_task_repository.dart';

class SearchLifeOsTasks {
  const SearchLifeOsTasks(this._repository);

  final LifeOsTaskRepository _repository;

  Future<List<LifeOsTask>> call(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return Future.value(const <LifeOsTask>[]);
    }

    return _repository.searchByTitle(normalizedQuery);
  }
}
