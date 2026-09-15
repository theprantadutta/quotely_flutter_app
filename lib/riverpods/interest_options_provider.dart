import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/default_interests.dart';
import '../services/fact_service.dart';
import '../services/tag_service.dart';

part '../generated/riverpods/interest_options_provider.g.dart';

/// Cache of the last successfully merged vocabulary. Written by the background
/// refresh below, read on the next launch.
const String kInterestOptionsCacheKey = 'interest-options-cache';

/// All selectable interests for the picker: every quote tag merged with every
/// fact category, ordered by popularity so the most-used topics surface first.
///
/// Resolves without touching the network. A first launch used to block here on
/// two requests - 1243 tags at ~223 KB plus 118 categories - before the picker
/// could draw a single chip, which is the wait this removes. The baked-in
/// [kDefaultInterestOptions] is the floor; a cached list from a previous
/// refresh is preferred when present, and a refresh is kicked off on every
/// build so anything added on the backend appears on the next launch.
@Riverpod(keepAlive: true)
Future<List<String>> interestOptions(Ref ref) async {
  final prefs = await SharedPreferences.getInstance();
  final cached = prefs.getStringList(kInterestOptionsCacheKey);

  // Deliberately not awaited: the whole point is that nothing here waits on the
  // network. Failures are swallowed - the baked-in list is always serviceable,
  // so a refresh that cannot reach the API is not worth surfacing.
  unawaited(_refreshInterestOptions(prefs));

  if (cached != null && cached.isNotEmpty) return cached;
  return kDefaultInterestOptions;
}

/// Fetches both vocabularies, merges them and caches the result for next
/// launch. This is the same merge [kDefaultInterestOptions] was generated with,
/// so a refreshed list differs from the baked-in one only by what has actually
/// changed on the backend.
Future<void> _refreshInterestOptions(SharedPreferences prefs) async {
  try {
    final tagsResponse = await TagService.getAllTags(
      pageNumber: 1,
      pageSize: 1000,
      getAllRows: true,
    );
    final categories = await FactService.getAllFactsCategories();
    if (tagsResponse.tags.isEmpty && categories.isEmpty) return;

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

    if (merged.isNotEmpty) {
      await prefs.setStringList(kInterestOptionsCacheKey, merged);
    }
  } catch (_) {
    // Offline or API down. The baked-in list already covers this.
  }
}
