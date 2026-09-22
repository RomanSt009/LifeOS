import '../../domain/entities/lifeos_entity.dart';

enum LifeOsFeatureCommandType {
  newTask,
  newNote,
  newWorkspace,
  openWorkspace,
  openUnassigned,
}

final class LifeOsFeatureCommand {
  const LifeOsFeatureCommand({
    required this.id,
    required this.type,
    this.workspaceId,
  }) : assert(
         type == LifeOsFeatureCommandType.openWorkspace
             ? workspaceId != null
             : workspaceId == null,
       );

  final int id;
  final LifeOsFeatureCommandType type;
  final LifeOsEntityId? workspaceId;
}
