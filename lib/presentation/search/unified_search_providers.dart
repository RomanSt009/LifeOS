import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/search_lifeos_entities.dart';

final searchLifeOsEntitiesProvider = Provider<SearchLifeOsEntities>((ref) {
  throw UnimplementedError(
    'searchLifeOsEntitiesProvider must be overridden by app composition.',
  );
});

final unifiedSearchRevisionProvider =
    NotifierProvider<UnifiedSearchRevisionController, int>(
      UnifiedSearchRevisionController.new,
    );

class UnifiedSearchRevisionController extends Notifier<int> {
  @override
  int build() => 0;

  void advance() => state += 1;
}
