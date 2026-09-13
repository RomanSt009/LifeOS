import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../domain/repositories/lifeos_note_repository.dart';
import 'create_lifeos_task.dart' show UtcClock;

class RestoreLifeOsNote {
  const RestoreLifeOsNote({required this.repository, required this.utcClock});

  final LifeOsNoteRepository repository;
  final UtcClock utcClock;

  Future<LifeOsNote?> call(LifeOsEntityId id) async {
    final current = await repository.getById(id);
    if (current == null) return null;
    final restored = current.restore(updatedAt: utcClock());
    if (!identical(restored, current)) await repository.save(restored);
    return restored;
  }
}
