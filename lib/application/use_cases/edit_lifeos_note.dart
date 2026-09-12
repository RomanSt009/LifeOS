import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../domain/repositories/lifeos_note_repository.dart';
import 'create_lifeos_task.dart' show UtcClock;

class EditLifeOsNote {
  const EditLifeOsNote({required this.repository, required this.utcClock});

  final LifeOsNoteRepository repository;
  final UtcClock utcClock;

  Future<LifeOsNote?> call(
    LifeOsEntityId id, {
    required String title,
    required String content,
  }) async {
    final current = await repository.getById(id);
    if (current == null) {
      return null;
    }

    final edited = current.edit(
      title: title,
      content: content,
      updatedAt: utcClock(),
    );
    if (!identical(edited, current)) {
      await repository.save(edited);
    }
    return edited;
  }
}
