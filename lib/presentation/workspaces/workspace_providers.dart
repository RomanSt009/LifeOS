import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/create_lifeos_entity_in_workspace.dart';
import '../../application/use_cases/create_lifeos_workspace.dart';
import '../../application/use_cases/edit_lifeos_workspace.dart';
import '../../application/use_cases/get_lifeos_workspace_context.dart';
import '../../application/use_cases/get_lifeos_workspaces.dart';
import '../../application/use_cases/lifeos_workspace_lifecycle.dart';
import '../../application/use_cases/lifeos_workspace_membership.dart';
import '../../application/workspaces/lifeos_workspace_context_reader.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_workspace.dart';
import 'workspace_member_refresh.dart';

final createLifeOsWorkspaceProvider = Provider<CreateLifeOsWorkspace>((ref) {
  throw UnimplementedError(
    'createLifeOsWorkspaceProvider must be overridden by app composition.',
  );
});

final editLifeOsWorkspaceProvider = Provider<EditLifeOsWorkspace>((ref) {
  throw UnimplementedError(
    'editLifeOsWorkspaceProvider must be overridden by app composition.',
  );
});

final getLifeOsWorkspacesProvider = Provider<GetLifeOsWorkspaces>((ref) {
  throw UnimplementedError(
    'getLifeOsWorkspacesProvider must be overridden by app composition.',
  );
});

final getDeletedLifeOsWorkspacesProvider = Provider<GetDeletedLifeOsWorkspaces>((
  ref,
) {
  throw UnimplementedError(
    'getDeletedLifeOsWorkspacesProvider must be overridden by app composition.',
  );
});

final deleteLifeOsWorkspaceProvider = Provider<DeleteLifeOsWorkspace>((ref) {
  throw UnimplementedError(
    'deleteLifeOsWorkspaceProvider must be overridden by app composition.',
  );
});

final restoreLifeOsWorkspaceProvider = Provider<RestoreLifeOsWorkspace>((ref) {
  throw UnimplementedError(
    'restoreLifeOsWorkspaceProvider must be overridden by app composition.',
  );
});

final getLifeOsWorkspaceMembersProvider = Provider<GetLifeOsWorkspaceMembers>((
  ref,
) {
  throw UnimplementedError(
    'getLifeOsWorkspaceMembersProvider must be overridden by app composition.',
  );
});

final getUnassignedLifeOsWorkspaceMembersProvider =
    Provider<GetUnassignedLifeOsWorkspaceMembers>((ref) {
      throw UnimplementedError(
        'getUnassignedLifeOsWorkspaceMembersProvider must be overridden by app composition.',
      );
    });

final attachLifeOsWorkspaceMemberProvider =
    Provider<AttachLifeOsWorkspaceMember>((ref) {
      throw UnimplementedError(
        'attachLifeOsWorkspaceMemberProvider must be overridden by app composition.',
      );
    });

final detachLifeOsWorkspaceMemberProvider =
    Provider<DetachLifeOsWorkspaceMember>((ref) {
      throw UnimplementedError(
        'detachLifeOsWorkspaceMemberProvider must be overridden by app composition.',
      );
    });

final createLifeOsTaskInWorkspaceProvider =
    Provider<CreateLifeOsTaskInWorkspace>((ref) {
      throw UnimplementedError(
        'createLifeOsTaskInWorkspaceProvider must be overridden by app composition.',
      );
    });

final createLifeOsNoteInWorkspaceProvider =
    Provider<CreateLifeOsNoteInWorkspace>((ref) {
      throw UnimplementedError(
        'createLifeOsNoteInWorkspaceProvider must be overridden by app composition.',
      );
    });

final workspaceListControllerProvider =
    AsyncNotifierProvider<WorkspaceListController, List<LifeOsWorkspace>>(
      WorkspaceListController.new,
    );

class WorkspaceListController extends AsyncNotifier<List<LifeOsWorkspace>> {
  @override
  Future<List<LifeOsWorkspace>> build() =>
      ref.watch(getLifeOsWorkspacesProvider)();

  Future<LifeOsWorkspace> create({
    required String title,
    required String? description,
  }) async {
    final workspace = await ref.read(createLifeOsWorkspaceProvider)(
      title: title,
      description: description,
    );
    await _reload();
    return workspace;
  }

  Future<LifeOsWorkspace> edit(
    LifeOsEntityId id, {
    required String title,
    required String? description,
  }) async {
    final workspace = await ref.read(editLifeOsWorkspaceProvider)(
      id,
      title: title,
      description: description,
    );
    if (workspace == null) {
      throw StateError('The selected Workspace no longer exists.');
    }
    await _reload();
    return workspace;
  }

  Future<void> delete(LifeOsEntityId id) async {
    final workspace = await ref.read(deleteLifeOsWorkspaceProvider)(id);
    if (workspace == null) {
      throw StateError('The selected Workspace no longer exists.');
    }
    await _reload();
    ref.invalidate(workspaceTrashControllerProvider);
    ref.read(workspaceMemberRevisionProvider.notifier).advance();
  }

  Future<void> _reload() async {
    state = AsyncData(await ref.read(getLifeOsWorkspacesProvider)());
  }
}

final workspaceTrashControllerProvider =
    AsyncNotifierProvider<WorkspaceTrashController, List<LifeOsWorkspace>>(
      WorkspaceTrashController.new,
    );

class WorkspaceTrashController extends AsyncNotifier<List<LifeOsWorkspace>> {
  @override
  Future<List<LifeOsWorkspace>> build() =>
      ref.watch(getDeletedLifeOsWorkspacesProvider)();

  Future<LifeOsWorkspace> restore(LifeOsEntityId id) async {
    final workspace = await ref.read(restoreLifeOsWorkspaceProvider)(id);
    if (workspace == null) {
      throw StateError('The selected Workspace no longer exists.');
    }
    state = AsyncData(await ref.read(getDeletedLifeOsWorkspacesProvider)());
    ref.invalidate(workspaceListControllerProvider);
    ref.read(workspaceMemberRevisionProvider.notifier).advance();
    return workspace;
  }
}

final workspaceMembersProvider =
    FutureProvider.family<List<LifeOsWorkspaceMember>, LifeOsEntityId>((
      ref,
      workspaceId,
    ) {
      ref.watch(workspaceMemberRevisionProvider);
      return ref.watch(getLifeOsWorkspaceMembersProvider)(workspaceId);
    });

final unassignedWorkspaceMembersProvider =
    FutureProvider<List<LifeOsWorkspaceMember>>((ref) {
      ref.watch(workspaceMemberRevisionProvider);
      return ref.watch(getUnassignedLifeOsWorkspaceMembersProvider)();
    });
