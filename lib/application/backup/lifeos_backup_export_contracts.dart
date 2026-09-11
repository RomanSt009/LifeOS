import '../../domain/entities/lifeos_task.dart';

class LifeOsDataSnapshot {
  LifeOsDataSnapshot({required Iterable<LifeOsTask> tasks})
    : tasks = _sortTasks(tasks);

  final List<LifeOsTask> tasks;

  static List<LifeOsTask> _sortTasks(Iterable<LifeOsTask> tasks) {
    final sortedTasks = tasks.toList(growable: false)
      ..sort((first, second) => first.id.value.compareTo(second.id.value));
    return List.unmodifiable(sortedTasks);
  }
}

class LifeOsBackupDraft {
  const LifeOsBackupDraft({
    required this.createdAt,
    required this.applicationVersion,
    required this.dataJson,
  });

  final DateTime createdAt;
  final String applicationVersion;
  final String dataJson;
}

abstract interface class LifeOsBackupExportEncoder {
  String encodeBackupData(LifeOsDataSnapshot snapshot);

  String encodeExport({
    required DateTime createdAt,
    required String applicationVersion,
    required LifeOsDataSnapshot snapshot,
  });
}
