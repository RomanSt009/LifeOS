import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_task.dart';
import '../../domain/repositories/lifeos_task_repository.dart';
import 'create_lifeos_task.dart' show UtcClock;

class EditLifeOsTaskTitle {
  const EditLifeOsTaskTitle({required this.repository, required this.utcClock});

  final LifeOsTaskRepository repository;
  final UtcClock utcClock;

  Future<LifeOsTask?> call(LifeOsEntityId id, {required String title}) async {
    final current = await repository.getById(id);
    if (current == null) {
      return null;
    }

    final edited = current.editTitle(title: title, updatedAt: utcClock());
    if (!identical(edited, current)) {
      await repository.save(edited);
    }
    return edited;
  }
}
