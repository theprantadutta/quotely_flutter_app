import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';
import '../constants/urls.dart';
import 'drift_fact_service.dart';
import 'drift_quote_service.dart';
import 'http_service.dart';

/// Why the backend hid a quote or fact.
@immutable
class Retraction {
  /// `misattributed`, `not_verified` (quotes) or `not_accurate` (facts).
  final String reason;

  /// Who probably said the quote, when the check could tell.
  final String? probablyBy;

  /// A verified quote by the same author that was added in its place.
  final String? replacementId;

  const Retraction({required this.reason, this.probablyBy, this.replacementId});

  Map<String, Object?> toJson() => {
    'r': reason,
    if (probablyBy != null) 'by': probablyBy,
    if (replacementId != null) 'rep': replacementId,
  };

  static Retraction? fromJson(Object? json) {
    if (json is! Map) return null;
    final r = json['r'];
    if (r is! String) return null;
    final by = json['by'];
    final rep = json['rep'];
    return Retraction(
      reason: r,
      probablyBy: by is String && by.isNotEmpty ? by : null,
      replacementId: rep is String && rep.isNotEmpty ? rep : null,
    );
  }

  /// The note under a saved item. [author] is who the quote was credited to.
  String note({String? author}) {
    if (reason == 'not_accurate') {
      return 'Our fact-check found this isn’t accurate.';
    }
    final credited = (author == null || author.isEmpty)
        ? 'this author'
        : author;
    if (probablyBy != null) {
      return 'Our checks found this is probably by $probablyBy, not $credited.';
    }
    return 'Our checks couldn’t confirm $credited said this.';
  }
}

/// Quotes and facts the backend hid as not genuine (misattributed quotes,
/// facts the fact-check removed). Once a day, after the library sync, the
/// list is fetched: unsaved local copies are deleted, so hidden content never
/// shows, even offline; saved ones are kept (nothing a person saved is ever
/// removed) and marked with a short, honest note, and they stay out of
/// "From your saved" and the saved widget. Keys match ThreadMessage.key:
/// `quote:<id>` and `fact:<id>`. Never throws.
class Retractions {
  Retractions._();

  static const syncEvery = Duration(hours: 20);

  /// The current map, for widgets to rebuild on.
  static final ValueNotifier<Map<String, Retraction>> current = ValueNotifier(
    const {},
  );

  static bool _loaded = false;

  static Retraction? of(String key) => current.value[key];

  static bool isRetracted(String key) => current.value.containsKey(key);

  /// Reads the stored map once (cheap; safe to call repeatedly).
  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      current.value = decode(prefs.getString(kRetractionsKey)).map;
    } catch (e) {
      debugPrint('Retractions: load failed: $e');
    }
  }

  /// Fetches the list if the last sync is older than [syncEvery].
  static Future<void> maybeSync({DateTime? now}) async {
    try {
      await load();
      final prefs = await SharedPreferences.getInstance();
      final last = decode(prefs.getString(kRetractionsKey)).at;
      final at = now ?? DateTime.now();
      if (last != null && at.difference(last) < syncEvery) return;
      await sync(now: at);
    } catch (e) {
      debugPrint('Retractions: sync failed: $e');
    }
  }

  /// Fetches, stores, and deletes unsaved local copies.
  static Future<void> sync({DateTime? now}) async {
    final response = await fetch();
    if (response == null) return;
    final map = parseResponse(response);
    if (map == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kRetractionsKey, encode(map, now ?? DateTime.now()));
    current.value = map;
    final quoteIds = <String>{};
    final factIds = <int>{};
    for (final key in map.keys) {
      if (key.startsWith('quote:')) quoteIds.add(key.substring(6));
      if (key.startsWith('fact:')) {
        final id = int.tryParse(key.substring(5));
        if (id != null) factIds.add(id);
      }
    }
    final q = await DriftQuoteService.deleteUnsaved(quoteIds);
    final f = await DriftFactService.deleteUnsaved(factIds);
    debugPrint(
      'Retractions: ${map.length} hidden; removed $q quotes and $f facts kept locally',
    );
  }

  /// The raw response body, or null on any failure (an older backend
  /// without the endpoint answers 404: nothing changes).
  @visibleForTesting
  static Future<String?> Function() fetch = () async {
    try {
      final response = await HttpService.get('$kApiUrl/$kGetRetractions');
      if (response.statusCode != 200) return null;
      final data = response.data;
      return data is String ? data : jsonEncode(data);
    } catch (_) {
      return null;
    }
  };

  /// `{"generatedAt":..., "quotes":[{"id","reason","probablyBy","replacementId"}], "facts":[{"id","reason"}]}`
  /// to the keyed map; null when the body isn't that shape.
  @visibleForTesting
  static Map<String, Retraction>? parseResponse(String body) {
    try {
      final json = jsonDecode(body);
      if (json is! Map) return null;
      final quotes = json['quotes'];
      final facts = json['facts'];
      if (quotes is! List || facts is! List) return null;
      final map = <String, Retraction>{};
      for (final q in quotes) {
        if (q is! Map || q['id'] is! String) continue;
        map['quote:${q['id']}'] = Retraction(
          reason: q['reason'] is String
              ? q['reason'] as String
              : 'not_verified',
          probablyBy: q['probablyBy'] is String
              ? q['probablyBy'] as String
              : null,
          replacementId: q['replacementId'] is String
              ? q['replacementId'] as String
              : null,
        );
      }
      for (final f in facts) {
        if (f is! Map || f['id'] == null) continue;
        map['fact:${f['id']}'] = const Retraction(reason: 'not_accurate');
      }
      return map;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  static String encode(Map<String, Retraction> map, DateTime at) => jsonEncode({
    'at': at.toIso8601String(),
    'items': {for (final e in map.entries) e.key: e.value.toJson()},
  });

  @visibleForTesting
  static ({Map<String, Retraction> map, DateTime? at}) decode(String? raw) {
    if (raw == null) return (map: const {}, at: null);
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return (map: const {}, at: null);
      final items = json['items'];
      final map = <String, Retraction>{};
      if (items is Map) {
        for (final e in items.entries) {
          final r = Retraction.fromJson(e.value);
          if (e.key is String && r != null) map[e.key as String] = r;
        }
      }
      final at = json['at'] is String
          ? DateTime.tryParse(json['at'] as String)
          : null;
      return (map: map, at: at);
    } catch (_) {
      return (map: const {}, at: null);
    }
  }

  @visibleForTesting
  static void resetForTest([Map<String, Retraction> map = const {}]) {
    _loaded = true;
    current.value = map;
  }
}
