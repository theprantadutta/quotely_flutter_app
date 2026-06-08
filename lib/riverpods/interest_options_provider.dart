import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/fact_service.dart';
import '../services/tag_service.dart';

part '../generated/riverpods/interest_options_provider.g.dart';

/// All selectable interests for the picker: every quote tag merged with every
/// fact category, ordered by popularity so the most-used topics surface first.
///
/// Tags carry a real popularity signal (`quoteCount`); fact categories arrive
/// from the API already ordered by how many facts use them. We interleave the
/// two by their popularity *rank* (position within its own group) so the top
/// tags and top categories both appear near the top, then de-dupe.
@Riverpod(keepAlive: true)
Future<List<String>> interestOptions(Ref ref) async {
  final tagsResponse = await TagService.getAllTags(
    pageNumber: 1,
    pageSize: 1000,
    getAllRows: true,
  );
  final categories = await FactService.getAllFactsCategories();

  final tags = [...tagsResponse.tags]
    ..sort((a, b) => b.quoteCount.compareTo(a.quoteCount));
  final tagNames = tags.map((t) => t.name).toList();

  // rank ∈ [0,1): 0 = most popular within its group. Sorting the combined
  // list by rank interleaves the two vocabularies proportionally.
  double rank(int index, int length) => length <= 1 ? 0 : index / length;
  final ranked = <({String name, double rank})>[
    for (var i = 0; i < tagNames.length; i++)
      (name: tagNames[i], rank: rank(i, tagNames.length)),
    for (var i = 0; i < categories.length; i++)
      (name: categories[i], rank: rank(i, categories.length)),
  ]..sort((a, b) => a.rank.compareTo(b.rank));

  final seen = <String>{};
  final merged = <String>[];
  for (final entry in ranked) {
    final trimmed = entry.name.trim();
    if (trimmed.isEmpty) continue;
    if (seen.add(trimmed.toLowerCase())) merged.add(trimmed);
  }
  return merged;
}
