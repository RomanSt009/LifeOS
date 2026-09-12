import '../../domain/entities/lifeos_note.dart';
import '../../domain/repositories/lifeos_note_repository.dart';

class GetLifeOsNotes {
  const GetLifeOsNotes(this._repository);

  final LifeOsNoteRepository _repository;

  Future<List<LifeOsNote>> call() => _repository.getAll();
}
