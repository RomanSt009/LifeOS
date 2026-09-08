import '../../domain/entities/lifeos_task.dart';

class ToggleTaskCompletion {
  const ToggleTaskCompletion();

  LifeOsTask call(LifeOsTask task, {required DateTime updatedAt}) {
    return task.toggleCompletion(updatedAt: updatedAt);
  }
}
