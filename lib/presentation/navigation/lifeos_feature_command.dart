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
  LifeOsFeatureCommand({required this.id, required this.type})
    : workspaceId = null,
      entityId = null {
    if (type == LifeOsFeatureCommandType.openTask ||
        type == LifeOsFeatureCommandType.openNote ||
        type == LifeOsFeatureCommandType.openWorkspace) {
      throw ArgumentError.value(
        type,
        'type',
        'Use the matching typed open command constructor.',
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

  LifeOsFeatureCommand.openWorkspace({
    required this.id,
    required LifeOsEntityId workspaceId,
  }) : type = LifeOsFeatureCommandType.openWorkspace,
       workspaceId = _requireType(
         workspaceId,
         LifeOsEntityType.workspace,
         'workspaceId',
       ),
       entityId = null;

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
