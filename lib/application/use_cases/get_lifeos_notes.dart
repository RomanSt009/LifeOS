import '../../domain/entities/lifeos_note.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../domain/repositories/lifeos_note_repository.dart';

class GetLifeOsNotes {
  const GetLifeOsNotes(this._repository);

  final LifeOsNoteRepository _repository;

  Future<List<LifeOsNote>> call() =>
      _repository.getByLifecycle(LifeOsEntityLifecycle.active);
}

class GetDeletedLifeOsNotes {
  const GetDeletedLifeOsNotes(this._repository);

  final LifeOsNoteRepository _repository;

  Future<List<LifeOsNote>> call() =>
      _repository.getByLifecycle(LifeOsEntityLifecycle.deleted);
}
