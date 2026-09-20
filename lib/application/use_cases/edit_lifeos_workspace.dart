import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_workspace.dart';
import '../../domain/repositories/lifeos_workspace_repository.dart';
import 'create_lifeos_task.dart' show UtcClock;

final class EditLifeOsWorkspace {
  const EditLifeOsWorkspace({required this.repository, required this.utcClock});

  final LifeOsWorkspaceRepository repository;
  final UtcClock utcClock;

  Future<LifeOsWorkspace?> call(
    LifeOsEntityId id, {
    required String title,
    required String? description,
  }) async {
    final current = await repository.getById(id);
    if (current == null) return null;
    final edited = current.edit(
      title: title,
      description: description,
      updatedAt: utcClock(),
    );
    if (!identical(edited, current)) await repository.save(edited);
    return edited;
  }
}
