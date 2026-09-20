import '../../domain/entities/lifeos_note.dart';
import '../../domain/entities/lifeos_task.dart';
import '../../domain/entities/lifeos_workspace_membership.dart';

final class LifeOsTaskInWorkspaceCreation {
  const LifeOsTaskInWorkspaceCreation({
    required this.task,
    required this.membership,
  });

  final LifeOsTask task;
  final LifeOsWorkspaceMembership membership;
}

final class LifeOsNoteInWorkspaceCreation {
  const LifeOsNoteInWorkspaceCreation({
    required this.note,
    required this.membership,
  });

  final LifeOsNote note;
  final LifeOsWorkspaceMembership membership;
}

abstract interface class LifeOsWorkspaceMemberCreationStore {
  Future<void> createTaskInWorkspace(
    LifeOsTask task,
    LifeOsWorkspaceMembership membership,
  );

  Future<void> createNoteInWorkspace(
    LifeOsNote note,
    LifeOsWorkspaceMembership membership,
  );
}
