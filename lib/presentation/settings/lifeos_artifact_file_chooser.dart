import 'package:file_selector/file_selector.dart';

abstract interface class LifeOsArtifactFileChooser {
  Future<String?> chooseBackupDestination({
    required String suggestedName,
    required String fileTypeLabel,
  });

  Future<String?> chooseExportDestination({
    required String suggestedName,
    required String fileTypeLabel,
  });

  Future<String?> chooseBackupToRestore({required String fileTypeLabel});
}

class FileSelectorLifeOsArtifactFileChooser
    implements LifeOsArtifactFileChooser {
  const FileSelectorLifeOsArtifactFileChooser();

  @override
  Future<String?> chooseBackupDestination({
    required String suggestedName,
    required String fileTypeLabel,
  }) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [
        XTypeGroup(label: fileTypeLabel, extensions: const ['zip']),
      ],
    );
    return location?.path;
  }

  @override
  Future<String?> chooseExportDestination({
    required String suggestedName,
    required String fileTypeLabel,
  }) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: [
        XTypeGroup(label: fileTypeLabel, extensions: const ['json']),
      ],
    );
    return location?.path;
  }

  @override
  Future<String?> chooseBackupToRestore({required String fileTypeLabel}) async {
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(label: fileTypeLabel, extensions: const ['zip']),
      ],
    );
    return file?.path;
  }
}

String lifeOsBackupSuggestedFileName(DateTime timestamp) {
  return 'lifeos-backup-${_fileTimestamp(timestamp)}.zip';
}

String lifeOsExportSuggestedFileName(DateTime timestamp) {
  return 'lifeos-export-${_fileTimestamp(timestamp)}.json';
}

String _fileTimestamp(DateTime timestamp) {
  final utc = timestamp.toUtc();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${utc.year.toString().padLeft(4, '0')}'
      '${twoDigits(utc.month)}${twoDigits(utc.day)}T'
      '${twoDigits(utc.hour)}${twoDigits(utc.minute)}${twoDigits(utc.second)}Z';
}
