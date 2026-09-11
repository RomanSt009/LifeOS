import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/backup/lifeos_backup_export_contracts.dart';
import 'package:lifeos/application/backup/lifeos_backup_restore_contracts.dart';
import 'package:lifeos/application/use_cases/restore_lifeos_backup.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';

void main() {
  test(
    'validates before checking confirmation or mutating persistence',
    () async {
      final reader = _FakeReader(error: _invalidDataError);
      final store = _FakeRestoreStore(hasData: true);
      final restore = RestoreLifeOsBackup(reader: reader, restoreStore: store);

      await expectLater(
        restore(sourcePath: 'invalid.zip', destructiveReplaceConfirmed: true),
        throwsA(same(_invalidDataError)),
      );

      expect(store.inspectionCount, 0);
      expect(store.replaceCount, 0);
    },
  );

  test(
    'requires explicit confirmation when local state is not empty',
    () async {
      final snapshot = LifeOsDataSnapshot(tasks: [_task]);
      final store = _FakeRestoreStore(hasData: true);
      final restore = RestoreLifeOsBackup(
        reader: _FakeReader(snapshot: snapshot),
        restoreStore: store,
      );

      await expectLater(
        restore(sourcePath: 'backup.zip', destructiveReplaceConfirmed: false),
        throwsA(
          isA<LifeOsBackupRestoreException>().having(
            (error) => error.code,
            'code',
            LifeOsBackupRestoreErrorCode.confirmationRequired,
          ),
        ),
      );

      expect(store.inspectionCount, 1);
      expect(store.replaceCount, 0);
    },
  );

  test('replaces non-empty state after explicit confirmation', () async {
    final snapshot = LifeOsDataSnapshot(tasks: [_task]);
    final store = _FakeRestoreStore(hasData: true);
    final restore = RestoreLifeOsBackup(
      reader: _FakeReader(snapshot: snapshot),
      restoreStore: store,
    );

    await restore(sourcePath: 'backup.zip', destructiveReplaceConfirmed: true);

    expect(store.replacedSnapshot, same(snapshot));
  });

  test('does not require destructive confirmation for empty state', () async {
    final snapshot = LifeOsDataSnapshot(tasks: [_task]);
    final store = _FakeRestoreStore(hasData: false);
    final restore = RestoreLifeOsBackup(
      reader: _FakeReader(snapshot: snapshot),
      restoreStore: store,
    );

    await restore(sourcePath: 'backup.zip', destructiveReplaceConfirmed: false);

    expect(store.replacedSnapshot, same(snapshot));
  });
}

final _invalidDataError = LifeOsBackupRestoreException(
  code: LifeOsBackupRestoreErrorCode.invalidData,
  message: 'Invalid test Backup.',
);

final _task = LifeOsTask(
  id: const LifeOsEntityId(
    value: '00000000-0000-4000-8000-000000000001',
    entityType: LifeOsEntityType.task,
  ),
  title: 'Restored Task',
  isCompleted: false,
  createdAt: DateTime.utc(2026, 9, 1),
  updatedAt: DateTime.utc(2026, 9, 2),
  lifecycle: LifeOsEntityLifecycle.active,
  version: 2,
  source: LifeOsEntitySource.import,
);

class _FakeReader implements LifeOsBackupReader {
  _FakeReader({this.snapshot, this.error});

  final LifeOsDataSnapshot? snapshot;
  final Object? error;

  @override
  Future<LifeOsDataSnapshot> read(String sourcePath) async {
    if (error case final error?) {
      throw error;
    }
    return snapshot!;
  }
}

class _FakeRestoreStore implements LifeOsBackupRestoreStore {
  _FakeRestoreStore({required this.hasData});

  final bool hasData;
  int inspectionCount = 0;
  int replaceCount = 0;
  LifeOsDataSnapshot? replacedSnapshot;

  @override
  Future<bool> hasRestorableData() async {
    inspectionCount += 1;
    return hasData;
  }

  @override
  Future<void> replaceAll(LifeOsDataSnapshot snapshot) async {
    replaceCount += 1;
    replacedSnapshot = snapshot;
  }
}
