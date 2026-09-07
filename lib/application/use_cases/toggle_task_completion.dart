import '../../domain/entities/lifeos_task.dart';

class ToggleTaskCompletion {
  const ToggleTaskCompletion();

  LifeOsTask call(LifeOsTask task, {required DateTime updatedAt}) {
    return LifeOsTask(
      id: task.id,
      title: task.title,
      isCompleted: !task.isCompleted,
      createdAt: task.createdAt,
      updatedAt: updatedAt,
      lifecycle: task.lifecycle,
      version: task.version + 1,
      source: task.source,
    );
  }
}
