import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/presentation/navigation/lifeos_feature_command.dart';

void main() {
  const taskId = LifeOsEntityId(
    value: 'task-1',
    entityType: LifeOsEntityType.task,
  );
  const noteId = LifeOsEntityId(
    value: 'note-1',
    entityType: LifeOsEntityType.note,
  );

  test('openTask carries only a typed Task ID', () {
    final command = LifeOsFeatureCommand.openTask(id: 1, taskId: taskId);

    expect(command.id, 1);
    expect(command.type, LifeOsFeatureCommandType.openTask);
    expect(command.entityId, taskId);
    expect(command.workspaceId, isNull);
  });

  test('openNote carries only a typed Note ID', () {
    final command = LifeOsFeatureCommand.openNote(id: 2, noteId: noteId);

    expect(command.id, 2);
    expect(command.type, LifeOsFeatureCommandType.openNote);
    expect(command.entityId, noteId);
    expect(command.workspaceId, isNull);
  });

  test('typed open commands reject the wrong Entity type', () {
    expect(
      () => LifeOsFeatureCommand.openTask(id: 1, taskId: noteId),
      throwsArgumentError,
    );
    expect(
      () => LifeOsFeatureCommand.openNote(id: 2, noteId: taskId),
      throwsArgumentError,
    );
    expect(
      () =>
          LifeOsFeatureCommand(id: 3, type: LifeOsFeatureCommandType.openTask),
      throwsArgumentError,
    );
  });
}
