import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../domain/entities/lifeos_task.dart';
import '../../domain/entities/lifeos_workspace.dart';

sealed class LifeOsSearchResult {
  const LifeOsSearchResult();

  LifeOsEntityId get entityId;
  LifeOsEntityType get entityType;
  String get primaryDisplayTitle;
  DateTime get updatedAt;
}

final class LifeOsTaskSearchResult extends LifeOsSearchResult {
  LifeOsTaskSearchResult(this.task) {
    _requireActive(task);
  }

  final LifeOsTask task;

  @override
  LifeOsEntityId get entityId => task.id;

  @override
  LifeOsEntityType get entityType => task.entityType;

  @override
  String get primaryDisplayTitle => task.title;

  @override
  DateTime get updatedAt => task.updatedAt;
}

final class LifeOsNoteSearchResult extends LifeOsSearchResult {
  LifeOsNoteSearchResult(this.note) {
    _requireActive(note);
  }

  final LifeOsNote note;

  @override
  LifeOsEntityId get entityId => note.id;

  @override
  LifeOsEntityType get entityType => note.entityType;

  @override
  String get primaryDisplayTitle => note.title;

  @override
  DateTime get updatedAt => note.updatedAt;
}

final class LifeOsWorkspaceSearchResult extends LifeOsSearchResult {
  LifeOsWorkspaceSearchResult(this.workspace) {
    _requireActive(workspace);
  }

  final LifeOsWorkspace workspace;

  @override
  LifeOsEntityId get entityId => workspace.id;

  @override
  LifeOsEntityType get entityType => workspace.entityType;

  @override
  String get primaryDisplayTitle => workspace.title;

  @override
  DateTime get updatedAt => workspace.updatedAt;
}

void _requireActive(LifeOsEntity entity) {
  if (entity.lifecycle != LifeOsEntityLifecycle.active) {
    throw ArgumentError.value(
      entity,
      'entity',
      'An ordinary Search result must be active.',
    );
  }
}
