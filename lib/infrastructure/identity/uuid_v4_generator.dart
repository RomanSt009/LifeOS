import 'package:uuid/uuid.dart';

typedef IdentifierGenerator = String Function();

String generateUuidV4() => const Uuid().v4();
