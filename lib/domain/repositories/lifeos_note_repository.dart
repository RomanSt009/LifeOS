import '../entities/lifeos_entity.dart';
import '../entities/lifeos_note.dart';

abstract interface class LifeOsNoteRepository {
  Future<List<LifeOsNote>> getAll();

  Future<LifeOsNote?> getById(LifeOsEntityId id);

  Future<List<LifeOsNote>> getByLifecycle(LifeOsEntityLifecycle lifecycle);

  Future<void> save(LifeOsNote note);
}
