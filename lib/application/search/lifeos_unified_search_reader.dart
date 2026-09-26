import 'lifeos_search_result.dart';

abstract interface class LifeOsUnifiedSearchReader {
  /// Searches active Task, Note, and Workspace state using a normalized,
  /// non-empty literal query and returns at most [limit] globally ordered
  /// results.
  Future<List<LifeOsSearchResult>> search({
    required String query,
    required int limit,
  });
}
