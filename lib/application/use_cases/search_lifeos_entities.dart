import '../search/lifeos_search_result.dart';
import '../search/lifeos_unified_search_reader.dart';

final class SearchLifeOsEntities {
  const SearchLifeOsEntities(this._reader);

  final LifeOsUnifiedSearchReader _reader;

  Future<List<LifeOsSearchResult>> call(String query, {required int limit}) {
    if (limit <= 0) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Search limit must be positive.',
      );
    }

    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return Future.value(const <LifeOsSearchResult>[]);
    }

    return _reader.search(query: normalizedQuery, limit: limit);
  }
}
