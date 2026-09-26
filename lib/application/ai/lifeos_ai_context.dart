import '../../domain/entities/lifeos_entity.dart';

enum LifeOsAiContextProvenance { workspaceRoot, workspaceMember }

enum LifeOsAiContextBuildError {
  invalidBudget,
  workspaceNotFound,
  workspaceInactive,
}

final class LifeOsAiContextBuildException implements Exception {
  const LifeOsAiContextBuildException({required this.error, this.workspaceId});

  final LifeOsAiContextBuildError error;
  final LifeOsEntityId? workspaceId;

  @override
  String toString() => 'LifeOsAiContextBuildException($error)';
}

final class LifeOsAiContextBudget {
  LifeOsAiContextBudget({
    required this.maxItems,
    required this.maxCharacters,
    required this.maxCharactersPerItem,
  }) {
    if (maxItems <= 0 || maxCharacters <= 0 || maxCharactersPerItem <= 0) {
      throw const LifeOsAiContextBuildException(
        error: LifeOsAiContextBuildError.invalidBudget,
      );
    }
  }

  final int maxItems;
  final int maxCharacters;
  final int maxCharactersPerItem;
}

final class BuildLifeOsAiContextInput {
  const BuildLifeOsAiContextInput({
    required this.workspaceId,
    required this.budget,
  });

  final LifeOsEntityId workspaceId;
  final LifeOsAiContextBudget budget;
}

final class LifeOsAiWorkspaceContextRoot {
  const LifeOsAiWorkspaceContextRoot({
    required this.workspaceId,
    required this.title,
    required this.description,
    required this.descriptionTruncated,
    required this.originalDescriptionCharacterCount,
    required this.characterCount,
  });

  final LifeOsEntityId workspaceId;
  final String title;
  final String? description;
  final bool descriptionTruncated;
  final int originalDescriptionCharacterCount;
  final int characterCount;

  LifeOsAiContextProvenance get provenance =>
      LifeOsAiContextProvenance.workspaceRoot;
}

sealed class LifeOsAiContextItem {
  const LifeOsAiContextItem({
    required this.entityId,
    required this.characterCount,
    required this.originalCharacterCount,
    required this.truncated,
  });

  final LifeOsEntityId entityId;
  final int characterCount;
  final int originalCharacterCount;
  final bool truncated;

  LifeOsAiContextProvenance get provenance =>
      LifeOsAiContextProvenance.workspaceMember;
}

final class LifeOsAiTaskContextItem extends LifeOsAiContextItem {
  const LifeOsAiTaskContextItem({
    required super.entityId,
    required this.title,
    required this.isCompleted,
    required super.characterCount,
  }) : super(originalCharacterCount: characterCount, truncated: false);

  final String title;
  final bool isCompleted;
}

final class LifeOsAiNoteContextItem extends LifeOsAiContextItem {
  const LifeOsAiNoteContextItem({
    required super.entityId,
    required this.title,
    required this.content,
    required this.originalContentCharacterCount,
    required super.characterCount,
    required super.originalCharacterCount,
    required super.truncated,
  });

  final String title;
  final String content;
  final int originalContentCharacterCount;
}

final class LifeOsAiContextBudgetUsage {
  const LifeOsAiContextBudgetUsage({
    required this.itemCount,
    required this.characterCount,
    required this.omittedItemCount,
    required this.deduplicatedItemCount,
    required this.truncatedProjectionCount,
  });

  final int itemCount;
  final int characterCount;
  final int omittedItemCount;
  final int deduplicatedItemCount;
  final int truncatedProjectionCount;

  bool get hasTruncation => truncatedProjectionCount > 0;
}

final class LifeOsAiContext {
  LifeOsAiContext({
    required this.rootWorkspace,
    required Iterable<LifeOsAiContextItem> items,
    required this.budget,
    required this.usage,
  }) : items = List.unmodifiable(items);

  final LifeOsAiWorkspaceContextRoot rootWorkspace;
  final List<LifeOsAiContextItem> items;
  final LifeOsAiContextBudget budget;
  final LifeOsAiContextBudgetUsage usage;
}
