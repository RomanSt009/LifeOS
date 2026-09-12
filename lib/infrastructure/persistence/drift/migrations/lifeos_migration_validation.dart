import 'package:drift/drift.dart';

final class LifeOsMigrationValidationException implements Exception {
  const LifeOsMigrationValidationException(this.message);

  final String message;

  @override
  String toString() => 'LifeOsMigrationValidationException: $message';
}

Future<void> validateLifeOsMigration(GeneratedDatabase database) async {
  final foreignKeyViolations = await database
      .customSelect('PRAGMA foreign_key_check')
      .get();
  if (foreignKeyViolations.isNotEmpty) {
    throw const LifeOsMigrationValidationException(
      'Foreign-key validation failed.',
    );
  }

  final quickCheck = await database.customSelect('PRAGMA quick_check').get();
  final isValid =
      quickCheck.length == 1 && quickCheck.single.data.values.single == 'ok';
  if (!isValid) {
    throw const LifeOsMigrationValidationException(
      'SQLite quick_check failed.',
    );
  }
}
