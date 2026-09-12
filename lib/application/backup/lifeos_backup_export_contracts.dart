import '../../domain/entities/lifeos_task.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../domain/entities/lifeos_relationship.dart';

class LifeOsDataSnapshot {
  LifeOsDataSnapshot({
    required Iterable<LifeOsTask> tasks,
    Iterable<LifeOsNote> notes = const [],
    Iterable<LifeOsRelationship> relationships = const [],
  }) : tasks = _sortTasks(tasks),
       notes = _sortNotes(notes),
       relationships = _sortRelationships(relationships);

  final List<LifeOsTask> tasks;
  final List<LifeOsNote> notes;
  final List<LifeOsRelationship> relationships;

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

  static List<LifeOsRelationship> _sortRelationships(
    Iterable<LifeOsRelationship> relationships,
  ) {
    final sorted = relationships.toList(growable: false)
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
