enum LifeOsFeatureCommandType { newTask, newNote }

final class LifeOsFeatureCommand {
  const LifeOsFeatureCommand({required this.id, required this.type});

  final int id;
  final LifeOsFeatureCommandType type;
}
