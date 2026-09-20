import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/app/dependencies.dart';
import 'package:lifeos/application/backup/lifeos_backup_export_contracts.dart';
import 'package:lifeos/application/backup/lifeos_backup_restore_contracts.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_relationship.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_workspace.dart';
import 'package:lifeos/domain/entities/lifeos_workspace_membership.dart';
import 'package:lifeos/infrastructure/backup/files/lifeos_backup_export_file_writers.dart';
import 'package:lifeos/infrastructure/backup/files/lifeos_backup_file_reader.dart';
import 'package:lifeos/infrastructure/backup/formats/backup_export_format_v1.dart';
import 'package:lifeos/infrastructure/backup/formats/backup_export_format_v4.dart';
import 'package:lifeos/infrastructure/backup/formats/v1_backup_export_encoder.dart';
import 'package:lifeos/infrastructure/backup/formats/v2_backup_export_encoder.dart';
import 'package:lifeos/infrastructure/backup/formats/v3_backup_export_encoder.dart';
import 'package:lifeos/infrastructure/backup/formats/v4_backup_export_encoder.dart';
import 'package:lifeos/infrastructure/persistence/drift/lifeos_database.dart';
import 'package:lifeos/infrastructure/persistence/drift/restore/drift_lifeos_backup_restore_store.dart';
import 'package:path/path.dart' as path;

void main() {
  final timestamp = DateTime.utc(2026, 9, 21, 10);
  final task = _task('00000000-0000-4000-8000-000000000001', timestamp);
  final note = _note('00000000-0000-4000-8000-000000000002', timestamp);
  final relationship = LifeOsRelationship.createUserRelationship(
    id: _id(
      '00000000-0000-4000-8000-000000000003',
      LifeOsEntityType.relationship,
    ),
    firstEndpoint: task.id,
    secondEndpoint: note.id,
    timestamp: timestamp,
  );
  final workspace = LifeOsWorkspace.createUserWorkspace(
    id: _id('00000000-0000-4000-8000-000000000004', LifeOsEntityType.workspace),
    title: 'Workspace',
    description: '  literal\r\ndescription  ',
    timestamp: timestamp,
  );
  final nullDescriptionWorkspace = LifeOsWorkspace.createUserWorkspace(
    id: _id('00000000-0000-4000-8000-000000000005', LifeOsEntityType.workspace),
    title: 'Null description',
    description: null,
    timestamp: timestamp,
  ).delete(updatedAt: timestamp.add(const Duration(hours: 1)));
  final taskMembership = _membership(
    '00000000-0000-4000-8000-000000000006',
    workspace.id,
    task.id,
    timestamp,
  );
  final deletedNoteMembership = _membership(
    '00000000-0000-4000-8000-000000000007',
    workspace.id,
    note.id,
    timestamp,
  ).remove(updatedAt: timestamp.add(const Duration(hours: 1)));

  LifeOsDataSnapshot snapshot() => LifeOsDataSnapshot(
    tasks: [task],
    notes: [note],
    relationships: [relationship],
    workspaces: [workspace, nullDescriptionWorkspace],
    workspaceMemberships: [taskMembership, deletedNoteMembership],
  );

  test('v4 codec preserves Workspace and Membership exact state', () {
    const encoder = V4BackupExportEncoder();
    final encoded = encoder.encodeBackupData(snapshot());
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    final decoded = LifeOsDataFormatV4.decodeBackupData(encoded);

    expect(json.keys, {
      'tasks',
      'notes',
      'relationships',
      'workspaces',
      'workspaceMemberships',
    });
    expect(decoded.workspaces.map((value) => value.toDomain()), [
      workspace,
      nullDescriptionWorkspace,
    ]);
    expect(decoded.workspaces.last.description, isNull);
    expect(decoded.workspaces.first.description, '  literal\r\ndescription  ');
    expect(
      decoded.workspaceMemberships.map(
        (value) => value.toDomain(
          memberType: decoded.entityTypesById[value.memberEntityId]!,
        ),
      ),
      [taskMembership, deletedNoteMembership],
    );
  });

  test('v4 rejects every invalid Workspace membership graph', () {
    final valid = jsonDecode(
      const V4BackupExportEncoder().encodeBackupData(snapshot()),
    ) as Map<String, dynamic>;

    Map<String, dynamic> changed(void Function(Map<String, dynamic>) mutate) {
      final copy = jsonDecode(jsonEncode(valid)) as Map<String, dynamic>;
      mutate(copy);
      return copy;
    }

    final invalid = <Map<String, dynamic>>[
      changed(
        (json) => json['workspaceMemberships'][0]['workspaceId'] = _uuid(90),
      ),
      changed(
        (json) => json['workspaceMemberships'][0]['memberEntityId'] = _uuid(91),
      ),
      changed(
        (json) => json['workspaceMemberships'][0]['memberEntityId'] =
            json['relationships'][0]['id'],
      ),
      changed(
        (json) => json['workspaceMemberships'][0]['memberEntityId'] =
            json['workspaces'][1]['id'],
      ),
      changed((json) {
        final duplicate = Map<String, dynamic>.from(
          json['workspaceMemberships'][0],
        );
        duplicate['id'] = _uuid(92);
        json['workspaceMemberships'].add(duplicate);
      }),
      changed(
        (json) => json['workspaceMemberships'].add(
          Map<String, dynamic>.from(json['workspaceMemberships'][0]),
        ),
      ),
      changed(
        (json) => json['workspaceMemberships'][0]['lifecycle'] = 'archived',
      ),
      changed((json) => json['workspaces'][0]['entityType'] = 'note'),
      changed(
        (json) =>
            json['workspaceMemberships'][0]['entityType'] = 'relationship',
      ),
      changed((json) => json['workspaces'][0]['title'] = '  '),
      changed((json) => json['workspaces'][0]['version'] = 0),
      changed((json) => json.remove('workspaceMemberships')),
    ];

    for (final document in invalid) {
      expect(
        () => LifeOsDataFormatV4.decodeBackupData(jsonEncode(document)),
        throwsA(isA<LifeOsDataFormatException>()),
      );
    }
  });

  test('invalid v4 is rejected before current database mutation', () async {
    final directory = await Directory.systemTemp.createTemp(
      'lifeos-v4-invalid-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final database = LifeOsDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DriftLifeOsBackupRestoreStore(database);
    await store.replaceAll(LifeOsDataSnapshot(tasks: [task]));
    final valid = jsonDecode(
      const V4BackupExportEncoder().encodeBackupData(snapshot()),
    ) as Map<String, dynamic>;
    valid['workspaceMemberships'][0]['workspaceId'] = _uuid(99);
    final file = await _archive(directory, jsonEncode(valid));

    await expectLater(
      const LifeOsBackupFileReader().read(file.path),
      throwsA(
        isA<LifeOsBackupRestoreException>().having(
          (error) => error.code,
          'code',
          LifeOsBackupRestoreErrorCode.invalidData,
        ),
      ),
    );
    expect(await database.select(database.taskRecords).get(), hasLength(1));
  });

  test(
    'v4 restore rollback keeps prior state after Membership insert failure',
    () async {
      final database = LifeOsDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final store = DriftLifeOsBackupRestoreStore(database);
      final original = _task(_uuid(80), timestamp);
      await store.replaceAll(LifeOsDataSnapshot(tasks: [original]));
      await database.customStatement('''
      CREATE TRIGGER fail_restore_membership
      BEFORE INSERT ON workspace_memberships
      BEGIN SELECT RAISE(ABORT, 'controlled'); END
    ''');

      await expectLater(
        store.replaceAll(snapshot()),
        throwsA(
          isA<LifeOsBackupRestoreException>().having(
            (error) => error.code,
            'code',
            LifeOsBackupRestoreErrorCode.persistenceFailure,
          ),
        ),
      );
      final rows = await database.select(database.entities).get();
      expect(rows.map((row) => row.id), [original.id.value]);
    },
  );

  test(
    'v1, v2, and v3 restore into schema v4 with empty Workspace state',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'lifeos-old-to-v4-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final cases = <(int, LifeOsBackupExportEncoder, LifeOsDataSnapshot)>[
        (1, const V1BackupExportEncoder(), LifeOsDataSnapshot(tasks: [task])),
        (
          2,
          const V2BackupExportEncoder(),
          LifeOsDataSnapshot(tasks: [task], notes: [note]),
        ),
        (
          3,
          const V3BackupExportEncoder(),
          LifeOsDataSnapshot(
            tasks: [task],
            notes: [note],
            relationships: [relationship],
          ),
        ),
      ];

      for (final (version, encoder, oldSnapshot) in cases) {
        final database = LifeOsDatabase(NativeDatabase.memory());
        final store = DriftLifeOsBackupRestoreStore(database);
        await store.replaceAll(snapshot());
        final file = path.join(directory.path, 'v$version.zip');
        await const LifeOsBackupFileWriter().write(
          draft: LifeOsBackupDraft(
            createdAt: timestamp,
            applicationVersion: '1.0.0+1',
            dataJson: encoder.encodeBackupData(oldSnapshot),
            formatVersion: version,
          ),
          sourceDatabaseSchemaVersion: version,
          destinationPath: file,
        );
        await store.replaceAll(await const LifeOsBackupFileReader().read(file));

        expect(await database.select(database.workspaceRecords).get(), isEmpty);
        expect(
          await database.select(database.workspaceMembershipRecords).get(),
          isEmpty,
        );
        expect(await database.select(database.outboxEntries).get(), isEmpty);
        expect(await database.select(database.taskRecords).get(), hasLength(1));
        expect(
          await database.select(database.noteRecords).get(),
          hasLength(version >= 2 ? 1 : 0),
        );
        expect(
          await database.select(database.relationshipRecords).get(),
          hasLength(version >= 3 ? 1 : 0),
        );
        expect(
          await database.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        await database.close();
      }
    },
  );

  test('production v4 file round-trip survives reopen without Outbox or device loss', () async {
    final directory = await Directory.systemTemp.createTemp(
      'lifeos-v4-roundtrip-',
    );
    addTearDown(() => directory.delete(recursive: true));
    var infrastructureId = 0;
    Future<LifeOsAppDependencies> open() => createProductionDependencies(
      applicationSupportDirectoryProvider: () async => directory,
      identifierGenerator: () => 'device-or-change-${++infrastructureId}',
      entityIdGenerator: () => _uuid(70 + infrastructureId),
      utcClock: () => timestamp,
    );

    var dependencies = await open();
    addTearDown(() => dependencies.close());
    await dependencies.taskRepository.save(task);
    await dependencies.noteRepository.save(note);
    await dependencies.relationshipRepository.save(relationship);
    await dependencies.workspaceRepository.save(workspace);
    await dependencies.workspaceRepository.save(
      LifeOsWorkspace.createUserWorkspace(
        id: nullDescriptionWorkspace.id,
        title: nullDescriptionWorkspace.title,
        description: null,
        timestamp: nullDescriptionWorkspace.createdAt,
      ),
    );
    await dependencies.workspaceRepository.save(nullDescriptionWorkspace);
    await dependencies.workspaceMembershipRepository.attach(
      workspaceId: workspace.id,
      memberEntityId: task.id,
      newMembershipId: taskMembership.id,
      timestamp: timestamp,
    );
    final noteMembership = await dependencies.workspaceMembershipRepository
        .attach(
          workspaceId: workspace.id,
          memberEntityId: note.id,
          newMembershipId: deletedNoteMembership.id,
          timestamp: timestamp,
        );
    await dependencies.workspaceMembershipRepository.remove(
      membershipId: noteMembership.id,
      timestamp: deletedNoteMembership.updatedAt,
    );
    final backupPath = path.join(directory.path, 'workspace-v4.zip');
    final exportPath = path.join(directory.path, 'workspace-v4.json');
    await dependencies.backupOperations.createBackupAt(backupPath);
    await dependencies.backupOperations.exportDataAt(exportPath);
    final deviceFile = File(path.join(directory.path, 'device_id'));
    final deviceBefore = await deviceFile.readAsString();

    await dependencies.restoreBackup(
      sourcePath: backupPath,
      destructiveReplaceConfirmed: true,
    );
    expect(
      await dependencies.database
          .select(dependencies.database.outboxEntries)
          .get(),
      isEmpty,
    );
    await dependencies.close();

    dependencies = await open();
    expect(await dependencies.taskRepository.getAll(), [task]);
    expect(await dependencies.noteRepository.getAll(), [note]);
    expect(await dependencies.relationshipRepository.getAll(), [relationship]);
    expect(await dependencies.workspaceRepository.getAll(), [
      nullDescriptionWorkspace,
      workspace,
    ]);
    expect(await dependencies.workspaceMembershipRepository.getAll(), [
      deletedNoteMembership,
      taskMembership,
    ]);
    expect(
      await dependencies.database
          .select(dependencies.database.outboxEntries)
          .get(),
      isEmpty,
    );
    expect(await deviceFile.readAsString(), deviceBefore);
    expect(
      await dependencies.database
          .customSelect('PRAGMA foreign_key_check')
          .get(),
      isEmpty,
    );
    expect(
      (await dependencies.database
              .customSelect('PRAGMA quick_check')
              .getSingle())
          .data
          .values
          .single,
      'ok',
    );

    final decoded = await const LifeOsBackupFileReader().read(backupPath);
    expect(decoded.workspaces, [workspace, nullDescriptionWorkspace]);
    expect(decoded.workspaceMemberships, [
      taskMembership,
      deletedNoteMembership,
    ]);
    final export = LifeOsDataFormatV4.decodeExport(
      await File(exportPath).readAsString(),
    );
    expect(export.workspaces, hasLength(2));
    expect(export.workspaceMemberships, hasLength(2));

    final reattached = await dependencies.workspaceMembershipRepository.attach(
      workspaceId: workspace.id,
      memberEntityId: note.id,
      newMembershipId: _id(_uuid(98), LifeOsEntityType.workspaceMembership),
      timestamp: timestamp.add(const Duration(hours: 2)),
    );
    expect(reattached.id, deletedNoteMembership.id);
    expect(reattached.lifecycle, LifeOsEntityLifecycle.active);
  });
}

LifeOsEntityId _id(String value, LifeOsEntityType type) =>
    LifeOsEntityId(value: value, entityType: type);

String _uuid(int suffix) =>
    '00000000-0000-4000-8000-${suffix.toString().padLeft(12, '0')}';

LifeOsTask _task(String id, DateTime timestamp) => LifeOsTask.createUserTask(
  id: _id(id, LifeOsEntityType.task),
  title: 'Task',
  timestamp: timestamp,
);

LifeOsNote _note(String id, DateTime timestamp) => LifeOsNote.createUserNote(
  id: _id(id, LifeOsEntityType.note),
  title: 'Note',
  content: ' exact\r\ncontent ',
  timestamp: timestamp,
);

LifeOsWorkspaceMembership _membership(
  String id,
  LifeOsEntityId workspaceId,
  LifeOsEntityId memberId,
  DateTime timestamp,
) => LifeOsWorkspaceMembership.createUserMembership(
  id: _id(id, LifeOsEntityType.workspaceMembership),
  workspaceId: workspaceId,
  memberEntityId: memberId,
  timestamp: timestamp,
);

Future<File> _archive(Directory directory, String dataJson) async {
  final data = utf8.encode(dataJson);
  final manifest = utf8.encode(
    LifeOsDataFormatV4.encodeManifest(
      BackupManifestV4(
        createdAt: DateTime.utc(2026, 9, 21),
        applicationVersion: '1.0.0+1',
        sourceDatabaseSchemaVersion: 4,
        dataSha256: sha256.convert(data).toString(),
      ),
    ),
  );
  final archive = Archive()
    ..addFile(
      ArchiveFile(lifeOsBackupManifestFileName, manifest.length, manifest),
    )
    ..addFile(ArchiveFile(lifeOsBackupDataFileName, data.length, data));
  final file = File(path.join(directory.path, 'invalid.zip'));
  await file.writeAsBytes(ZipEncoder().encode(archive)!);
  return file;
}
