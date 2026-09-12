import '../../domain/entities/lifeos_task.dart';
import '../../domain/entities/lifeos_note.dart';

class LifeOsDataSnapshot {
  LifeOsDataSnapshot({
    required Iterable<LifeOsTask> tasks,
    Iterable<LifeOsNote> notes = const [],
  }) : tasks = _sortTasks(tasks),
       notes = _sortNotes(notes);

  final List<LifeOsTask> tasks;
  final List<LifeOsNote> notes;

  static List<LifeOsTask> _sortTasks(Iterable<LifeOsTask> tasks) {
    final sortedTasks = tasks.toList(growable: false)
      ..sort((first, second) => first.id.value.compareTo(second.id.value));
    return List.unmodifiable(sortedTasks);
  }

  static List<LifeOsNote> _sortNotes(Iterable<LifeOsNote> notes) {
    final sorted = notes.toList(growable: false)
      ..sort((a, b) => a.id.value.compareTo(b.id.value));
    return List.unmodifiable(sorted);
  }
}

class LifeOsBackupDraft {
  const LifeOsBackupDraft({
    required this.createdAt,
    required this.applicationVersion,
    required this.dataJson,
    this.formatVersion = 1,
  });

  final DateTime createdAt;
  final String applicationVersion;
  final String dataJson;
  final int formatVersion;
}

abstract interface class LifeOsBackupExportEncoder {
  String encodeBackupData(LifeOsDataSnapshot snapshot);

  String encodeExport({
    required DateTime createdAt,
    required String applicationVersion,
    required LifeOsDataSnapshot snapshot,
  });
}
