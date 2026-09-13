import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/backup/lifeos_backup_operations.dart';
import 'lifeos_artifact_file_chooser.dart';

final lifeOsBackupOperationsProvider = Provider<LifeOsBackupOperations>((ref) {
  throw UnimplementedError(
    'lifeOsBackupOperationsProvider must be overridden by app composition.',
  );
});

final lifeOsArtifactFileChooserProvider = Provider<LifeOsArtifactFileChooser>(
  (ref) => const FileSelectorLifeOsArtifactFileChooser(),
);

final backupRestoreRevisionProvider =
    NotifierProvider<BackupRestoreRevisionController, int>(
      BackupRestoreRevisionController.new,
    );

class BackupRestoreRevisionController extends Notifier<int> {
  @override
  int build() => 0;

  void advance() => state += 1;
}
