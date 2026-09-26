import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';
import '../constants/urls.dart';
import '../dtos/ai_fact_response_dto.dart';
import '../dtos/author_response_dto.dart';
import '../dtos/quote_response_dto.dart';
import '../dtos/tag_response_dto.dart';
import 'drift_author_service.dart';
import 'drift_fact_service.dart';
import 'drift_quote_service.dart';
import 'drift_tag_service.dart';
import 'http_service.dart';
import 'scene_repository.dart';

/// The downloadable packs, in display order.
enum OfflinePack {
  quotes('Quotes', 'quotes'),
  authors('Authors', 'people'),
  facts('Facts', 'facts'),
  scenes('Scenes', 'lines');

  final String label;
  final String unit;
  const OfflinePack(this.label, this.unit);
}

/// Why a sync did or didn't run.
enum SyncBlock { none, offline, wifiOnly }

/// Downloads the whole library (quotes and tags, authors, facts, scenes)
/// into the local database. Used by Offline library's button and,
/// automatically, at most once a day on app start ([maybeRunDaily]), so
/// the local-first screens have everything to show next time.
class LibrarySync {
  LibrarySync._();

  static const lastSyncedKey = 'offline_data_last_downloaded';
  static const dailyEvery = Duration(hours: 24);

  /// A full list shorter than this is treated as suspect and not used to
  /// delete local rows.
  static const _pruneMinimum = 100;

  static bool _running = false;
  static bool get running => _running;

  /// Saved item counts per pack (null = never downloaded).
  static Future<Map<OfflinePack, int?>> packCounts() async {
    final prefs = await SharedPreferences.getInstance();
    // Installs that downloaded before packs existed had one "everything" date.
    final legacy = prefs.getString(lastSyncedKey) != null;
    return {
      for (final p in OfflinePack.values)
        p:
            prefs.getInt('$kOfflinePackCountPrefix${p.name}') ??
            (legacy && p != OfflinePack.scenes ? 0 : null),
    };
  }

  static Future<DateTime?> lastSynced() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(lastSyncedKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Whether the network allows a download right now (Offline library's
  /// "Wi-Fi only" switch, on by default).
  static Future<SyncBlock> networkBlock() async {
    final results = await Connectivity().checkConnectivity();
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return SyncBlock.offline;
    }
    final prefs = await SharedPreferences.getInstance();
    final wifiOnly = prefs.getBool(kWifiOnlyKey) ?? true;
    final unmetered =
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
    if (wifiOnly && !unmetered) return SyncBlock.wifiOnly;
    return SyncBlock.none;
  }

  /// Downloads one pack and records its count. Returns the count.
  static Future<int> downloadPack(OfflinePack pack) async {
    final count = switch (pack) {
      OfflinePack.quotes => await _downloadQuotes(),
      OfflinePack.authors => await _downloadAuthors(),
      OfflinePack.facts => await _downloadFacts(),
      OfflinePack.scenes => await SceneRepository.instance.downloadAll(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$kOfflinePackCountPrefix${pack.name}', count);
    return count;
  }

  /// Downloads every pack. [onPack] reports each pack's start (null count)
  /// and result (count, or -1 on failure). Returns whether all succeeded.
  static Future<bool> downloadAll({
    void Function(OfflinePack pack, int? count)? onPack,
  }) async {
    if (_running) return false;
    _running = true;
    var ok = true;
    try {
      for (final pack in OfflinePack.values) {
        onPack?.call(pack, null);
        try {
          onPack?.call(pack, await downloadPack(pack));
        } catch (e) {
          debugPrint('LibrarySync: ${pack.name} failed: $e');
          onPack?.call(pack, -1);
          ok = false;
        }
      }
      if (ok) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(lastSyncedKey, DateTime.now().toIso8601String());
      }
    } finally {
      _running = false;
    }
    return ok;
  }

  /// On app start: if the last full sync is older than a day (or never
  /// happened) and the network allows it, sync everything silently.
  static Future<void> maybeRunDaily() async {
    try {
      final last = await lastSynced();
      if (last != null && DateTime.now().difference(last) < dailyEvery) return;
      if (await networkBlock() != SyncBlock.none) return;
      final ok = await downloadAll();
      debugPrint('LibrarySync: daily sync ${ok ? 'done' : 'incomplete'}');
    } catch (e) {
      debugPrint('LibrarySync: daily sync failed: $e');
    }
  }

  static Future<int> _downloadQuotes() async {
    final response = await HttpService.get(
      '$kApiUrl/$kGetAllQuotes?getAllRows=true',
    );
    if (response.statusCode != 200) throw Exception('Failed to fetch quotes');
    final quotes = QuoteResponseDto.fromJson(json.decode(response.data)).quotes;
    await DriftQuoteService.saveNewQuotesToDatabase(quotes);
    // A complete list: anything local the backend no longer has was removed
    // there (duplicates, content). Guarded against a truncated response.
    if (quotes.length >= _pruneMinimum) {
      await DriftQuoteService.pruneMissing({for (final q in quotes) q.id});
    }
    // Tags ride along with quotes (they power the Topics chips offline).
    final tagResponse = await HttpService.get(
      '$kApiUrl/$kGetAllTags?getAllRows=true',
    );
    if (tagResponse.statusCode == 200) {
      final tags = TagResponseDto.fromJson(json.decode(tagResponse.data)).tags;
      await DriftTagService.saveTagsToDatabase(tags);
    }
    return quotes.length;
  }

  static Future<int> _downloadAuthors() async {
    final response = await HttpService.get(
      '$kApiUrl/$kGetAllAuthors?getAllRows=true',
    );
    if (response.statusCode != 200) throw Exception('Failed to fetch authors');
    final authors = AuthorResponseDto.fromJson(
      json.decode(response.data),
    ).authors;
    await DriftAuthorService.saveAuthorsToDatabase(authors);
    return authors.length;
  }

  static Future<int> _downloadFacts() async {
    final response = await HttpService.get(
      '$kApiUrl/$kGetAllAiFacts?getAllRows=true',
    );
    if (response.statusCode != 200) throw Exception('Failed to fetch facts');
    final facts = AiFactResponseDto.fromJson(
      json.decode(response.data),
    ).aiFacts;
    await DriftFactService.saveNewFactsToDatabase(facts);
    if (facts.length >= _pruneMinimum) {
      await DriftFactService.pruneMissing({for (final f in facts) f.id});
    }
    return facts.length;
  }
}
