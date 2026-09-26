import '../../domain/entities/lifeos_entity.dart';
import '../../domain/repositories/lifeos_workspace_repository.dart';
import '../ai/lifeos_ai_context.dart';
import '../workspaces/lifeos_workspace_context_reader.dart';

final class BuildLifeOsAiContext {
  const BuildLifeOsAiContext({
    required this.workspaceRepository,
    required this.workspaceContextReader,
  });

  final LifeOsWorkspaceRepository workspaceRepository;
  final LifeOsWorkspaceContextReader workspaceContextReader;

  Future<LifeOsAiContext> call(BuildLifeOsAiContextInput input) async {
    final workspaceId = input.workspaceId;
    if (workspaceId.entityType != LifeOsEntityType.workspace) {
      throw LifeOsAiContextBuildException(
        error: LifeOsAiContextBuildError.workspaceNotFound,
        workspaceId: workspaceId,
      );
    }

    final workspace = await workspaceRepository.getById(workspaceId);
    if (workspace == null) {
      throw LifeOsAiContextBuildException(
        error: LifeOsAiContextBuildError.workspaceNotFound,
        workspaceId: workspaceId,
      );
    }
    if (workspace.lifecycle != LifeOsEntityLifecycle.active) {
      throw LifeOsAiContextBuildException(
        error: LifeOsAiContextBuildError.workspaceInactive,
        workspaceId: workspaceId,
      );
    }

    final budget = input.budget;
    final rootTitleCharacters = _characterCount(workspace.title);
    if (rootTitleCharacters > budget.maxCharacters ||
        rootTitleCharacters > budget.maxCharactersPerItem) {
      throw LifeOsAiContextBuildException(
        error: LifeOsAiContextBuildError.invalidBudget,
        workspaceId: workspaceId,
      );
    }

    final description = workspace.description;
    final originalDescriptionCharacters = _characterCount(description ?? '');
    final rootDescriptionCapacity = _minimum(
      budget.maxCharacters - rootTitleCharacters,
      budget.maxCharactersPerItem - rootTitleCharacters,
    );
    final projectedDescription = description == null
        ? null
        : _prefix(description, rootDescriptionCapacity);
    final projectedDescriptionCharacters = _characterCount(
      projectedDescription ?? '',
    );
    final rootTruncated =
        projectedDescriptionCharacters < originalDescriptionCharacters;
    final rootCharacterCount =
        rootTitleCharacters + projectedDescriptionCharacters;
    final root = LifeOsAiWorkspaceContextRoot(
      workspaceId: workspace.id,
      title: workspace.title,
      description: projectedDescription,
      descriptionTruncated: rootTruncated,
      originalDescriptionCharacterCount: originalDescriptionCharacters,
      characterCount: rootCharacterCount,
    );

    final members = await workspaceContextReader.getDirectMembers(workspaceId);
    final activeMembers = members.where(_isActive).toList(growable: false);
    final uniqueMembers = <LifeOsEntityId, LifeOsWorkspaceMember>{};
    for (final member in activeMembers) {
      uniqueMembers.putIfAbsent(member.entityId, () => member);
    }
    final orderedMembers = uniqueMembers.values.toList()..sort(_compareMembers);

    final items = <LifeOsAiContextItem>[];
    var usedCharacters = rootCharacterCount;
    var omittedItems = 0;
    var truncatedProjections = rootTruncated ? 1 : 0;

    for (var index = 0; index < orderedMembers.length; index++) {
      if (items.length == budget.maxItems) {
        omittedItems += orderedMembers.length - index;
        break;
      }

      final member = orderedMembers[index];
      final remainingCharacters = budget.maxCharacters - usedCharacters;
      final item = _projectMember(
        member,
        remainingCharacters: remainingCharacters,
        maxCharactersPerItem: budget.maxCharactersPerItem,
      );
      if (item == null) {
        omittedItems += orderedMembers.length - index;
        break;
      }

      items.add(item);
      usedCharacters += item.characterCount;
      if (item.truncated) truncatedProjections++;
    }

    return LifeOsAiContext(
      rootWorkspace: root,
      items: List.unmodifiable(items),
      budget: budget,
      usage: LifeOsAiContextBudgetUsage(
        itemCount: items.length,
        characterCount: usedCharacters,
        omittedItemCount: omittedItems,
        deduplicatedItemCount: activeMembers.length - uniqueMembers.length,
        truncatedProjectionCount: truncatedProjections,
      ),
    );
  }
}

LifeOsAiContextItem? _projectMember(
  LifeOsWorkspaceMember member, {
  required int remainingCharacters,
  required int maxCharactersPerItem,
}) {
  return switch (member) {
    LifeOsWorkspaceTaskMember(:final task) => _projectTask(
      task.id,
      task.title,
      task.isCompleted,
      remainingCharacters,
      maxCharactersPerItem,
    ),
    LifeOsWorkspaceNoteMember(:final note) => _projectNote(
      note.id,
      note.title,
      note.content,
      remainingCharacters,
      maxCharactersPerItem,
    ),
  };
}

LifeOsAiTaskContextItem? _projectTask(
  LifeOsEntityId id,
  String title,
  bool isCompleted,
  int remainingCharacters,
  int maxCharactersPerItem,
) {
  final titleCharacters = _characterCount(title);
  if (titleCharacters > remainingCharacters ||
      titleCharacters > maxCharactersPerItem) {
    return null;
  }
  return LifeOsAiTaskContextItem(
    entityId: id,
    title: title,
    isCompleted: isCompleted,
    characterCount: titleCharacters,
  );
}

LifeOsAiNoteContextItem? _projectNote(
  LifeOsEntityId id,
  String title,
  String content,
  int remainingCharacters,
  int maxCharactersPerItem,
) {
  final titleCharacters = _characterCount(title);
  if (titleCharacters > remainingCharacters ||
      titleCharacters > maxCharactersPerItem) {
    return null;
  }

  final originalContentCharacters = _characterCount(content);
  final contentCapacity = _minimum(
    remainingCharacters - titleCharacters,
    maxCharactersPerItem - titleCharacters,
  );
  final projectedContent = _prefix(content, contentCapacity);
  final projectedContentCharacters = _characterCount(projectedContent);
  return LifeOsAiNoteContextItem(
    entityId: id,
    title: title,
    content: projectedContent,
    originalContentCharacterCount: originalContentCharacters,
    characterCount: titleCharacters + projectedContentCharacters,
    originalCharacterCount: titleCharacters + originalContentCharacters,
    truncated: projectedContentCharacters < originalContentCharacters,
  );
}

bool _isActive(LifeOsWorkspaceMember member) => switch (member) {
  LifeOsWorkspaceTaskMember(:final task) =>
    task.lifecycle == LifeOsEntityLifecycle.active,
  LifeOsWorkspaceNoteMember(:final note) =>
    note.lifecycle == LifeOsEntityLifecycle.active,
};

int _compareMembers(LifeOsWorkspaceMember first, LifeOsWorkspaceMember second) {
  final updatedAt = second.updatedAt.compareTo(first.updatedAt);
  if (updatedAt != 0) return updatedAt;
  return first.entityId.value.compareTo(second.entityId.value);
}

int _characterCount(String value) => value.runes.length;

String _prefix(String value, int maximumCharacters) =>
    String.fromCharCodes(value.runes.take(maximumCharacters));

int _minimum(int first, int second) => first < second ? first : second;
