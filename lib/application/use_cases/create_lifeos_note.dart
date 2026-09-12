import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../domain/repositories/lifeos_note_repository.dart';
import 'create_lifeos_task.dart' show EntityIdGenerator, UtcClock;

class CreateLifeOsNote {
  const CreateLifeOsNote({
    required this.repository,
    required this.entityIdGenerator,
    required this.utcClock,
  });

  final LifeOsNoteRepository repository;
  final EntityIdGenerator entityIdGenerator;
  final UtcClock utcClock;

  Future<LifeOsNote> call({
    required String title,
    required String content,
  }) async {
    final note = LifeOsNote.createUserNote(
      id: LifeOsEntityId(
        value: entityIdGenerator(),
        entityType: LifeOsEntityType.note,
      ),
      title: title,
      content: content,
      timestamp: utcClock(),
    );
    await repository.save(note);
    return note;
  }
}
