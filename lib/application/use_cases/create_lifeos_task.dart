import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_task.dart';
import '../../domain/repositories/lifeos_task_repository.dart';

typedef EntityIdGenerator = String Function();
typedef UtcClock = DateTime Function();

class CreateLifeOsTask {
  const CreateLifeOsTask({
    required this.repository,
    required this.entityIdGenerator,
    required this.utcClock,
  });

  final LifeOsTaskRepository repository;
  final EntityIdGenerator entityIdGenerator;
  final UtcClock utcClock;

  Future<LifeOsTask> call(String title) async {
    final timestamp = utcClock();
    final task = LifeOsTask.createUserTask(
      id: LifeOsEntityId(
        value: entityIdGenerator(),
        entityType: LifeOsEntityType.task,
      ),
      title: title,
      timestamp: timestamp,
    );

    await repository.save(task);
    return task;
  }
}
