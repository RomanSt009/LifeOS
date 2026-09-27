import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/ask_about_lifeos_workspace.dart';
import '../../application/use_cases/check_lifeos_local_ai_availability.dart';

final checkLifeOsLocalAiAvailabilityProvider =
    Provider<CheckLifeOsLocalAiAvailability>((ref) {
      throw UnimplementedError(
        'checkLifeOsLocalAiAvailabilityProvider must be overridden by app composition.',
      );
    });

final askAboutLifeOsWorkspaceProvider = Provider<AskAboutLifeOsWorkspace>((
  ref,
) {
  throw UnimplementedError(
    'askAboutLifeOsWorkspaceProvider must be overridden by app composition.',
  );
});

final lifeOsLocalAiModelNameProvider = Provider<String>((ref) {
  throw UnimplementedError(
    'lifeOsLocalAiModelNameProvider must be overridden by app composition.',
  );
});
