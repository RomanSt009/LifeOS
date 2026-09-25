import '../../domain/entities/lifeos_entity.dart';

enum LifeOsFeatureCommandType {
  newTask,
  newNote,
  openTask,
  openNote,
  newWorkspace,
  openWorkspace,
  openUnassigned,
}

final class LifeOsFeatureCommand {
  LifeOsFeatureCommand({required this.id, required this.type, this.workspaceId})
    : entityId = null {
    if (type == LifeOsFeatureCommandType.openTask ||
        type == LifeOsFeatureCommandType.openNote) {
      throw ArgumentError.value(
        type,
        'type',
        'Use the typed openTask/openNote command constructor.',
      );
    }
    if ((type == LifeOsFeatureCommandType.openWorkspace) !=
        (workspaceId != null)) {
      throw ArgumentError.value(
        workspaceId,
        'workspaceId',
        'Only openWorkspace accepts and requires a Workspace ID.',
      );
    }
  }

  LifeOsFeatureCommand.openTask({
    required this.id,
    required LifeOsEntityId taskId,
  }) : type = LifeOsFeatureCommandType.openTask,
       workspaceId = null,
       entityId = _requireType(taskId, LifeOsEntityType.task, 'taskId');

  LifeOsFeatureCommand.openNote({
    required this.id,
    required LifeOsEntityId noteId,
  }) : type = LifeOsFeatureCommandType.openNote,
       workspaceId = null,
       entityId = _requireType(noteId, LifeOsEntityType.note, 'noteId');

  final int id;
  final LifeOsFeatureCommandType type;
  final LifeOsEntityId? workspaceId;
  final LifeOsEntityId? entityId;
}

LifeOsEntityId _requireType(
  LifeOsEntityId id,
  LifeOsEntityType expected,
  String name,
) {
  if (id.entityType != expected) {
    throw ArgumentError.value(id, name, 'The command requires a typed ID.');
  }
  return id;
}
