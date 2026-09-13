import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_task.dart';
import '../../domain/repositories/lifeos_task_repository.dart';
import 'create_lifeos_task.dart' show UtcClock;

class RestoreLifeOsTask {
  const RestoreLifeOsTask({required this.repository, required this.utcClock});

  final LifeOsTaskRepository repository;
  final UtcClock utcClock;

  Future<LifeOsTask?> call(LifeOsEntityId id) async {
    final current = await repository.getById(id);
    if (current == null) return null;
    final restored = current.restore(updatedAt: utcClock());
    if (!identical(restored, current)) await repository.save(restored);
    return restored;
  }
}
