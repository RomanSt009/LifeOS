import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_workspace.dart';
import '../../domain/repositories/lifeos_workspace_repository.dart';
import 'create_lifeos_task.dart' show EntityIdGenerator, UtcClock;

final class CreateLifeOsWorkspace {
  const CreateLifeOsWorkspace({
    required this.repository,
    required this.entityIdGenerator,
    required this.utcClock,
  });

  final LifeOsWorkspaceRepository repository;
  final EntityIdGenerator entityIdGenerator;
  final UtcClock utcClock;

  Future<LifeOsWorkspace> call({
    required String title,
    required String? description,
  }) async {
    final workspace = LifeOsWorkspace.createUserWorkspace(
      id: LifeOsEntityId(
        value: entityIdGenerator(),
        entityType: LifeOsEntityType.workspace,
      ),
      title: title,
      description: description,
      timestamp: utcClock(),
    );
    await repository.save(workspace);
    return workspace;
  }
}
