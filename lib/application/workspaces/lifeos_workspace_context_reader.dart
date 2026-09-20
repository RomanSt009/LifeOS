import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../domain/entities/lifeos_task.dart';

sealed class LifeOsWorkspaceMember {
  const LifeOsWorkspaceMember({required this.membershipId});

  final LifeOsEntityId? membershipId;
  LifeOsEntityId get entityId;
  DateTime get updatedAt;
}

final class LifeOsWorkspaceTaskMember extends LifeOsWorkspaceMember {
  const LifeOsWorkspaceTaskMember({
    required super.membershipId,
    required this.task,
  });

  final LifeOsTask task;

  @override
  LifeOsEntityId get entityId => task.id;

  @override
  DateTime get updatedAt => task.updatedAt;
}

final class LifeOsWorkspaceNoteMember extends LifeOsWorkspaceMember {
  const LifeOsWorkspaceNoteMember({
    required super.membershipId,
    required this.note,
  });

  final LifeOsNote note;

  @override
  LifeOsEntityId get entityId => note.id;

  @override
  DateTime get updatedAt => note.updatedAt;
}

abstract interface class LifeOsWorkspaceContextReader {
  Future<List<LifeOsWorkspaceMember>> getDirectMembers(
    LifeOsEntityId workspaceId,
  );

  Future<List<LifeOsWorkspaceMember>> getUnassigned();
}
