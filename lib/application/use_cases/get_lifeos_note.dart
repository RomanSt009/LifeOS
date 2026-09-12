import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../domain/repositories/lifeos_note_repository.dart';

class GetLifeOsNote {
  const GetLifeOsNote(this._repository);

  final LifeOsNoteRepository _repository;

  Future<LifeOsNote?> call(LifeOsEntityId id) => _repository.getById(id);
}
