import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/urls.dart';
import '../dtos/coming_soon_dto.dart';
import '../util/countdown.dart';
import 'http_service.dart';
import 'local_first.dart';

/// `Spotlight/GetComingSoon`, local first: the last good response is saved
/// in prefs, so the Scenes strip shows offline and at once on launch.
///
/// The strip is a nice-to-have, so this never throws: a 404 (a backend
/// without the endpoint yet), a bad body or no network with nothing saved
/// all read as an empty list, and the strip hides.
class ComingSoonService {
  ComingSoonService._();

  static const cacheKey = 'coming-soon:v1';

  /// The request; replaced in tests.
  @visibleForTesting
  static Future<Response> Function(int count) fetch = (count) =>
      HttpService.get('$kApiUrl/$kGetComingSoon?count=$count');

  static Future<List<ComingSoonDto>> getComingSoon({
    int count = 10,
    DateTime? now,
  }) async {
    try {
      final items = await LocalFirst.load<List<ComingSoonDto>>(
        key: cacheKey,
        local: _readCache,
        remote: () => _fetch(count),
        isEmpty: (v) => v.isEmpty,
      );
      return visible(items, now ?? DateTime.now());
    } catch (e) {
      debugPrint('ComingSoon: $e');
      return const [];
    }
  }

  /// Drops what a saved copy can hold past its time: dated releases already
  /// out (a day after release they stop being "coming"). Items with nothing
  /// to open are dropped too.
  static List<ComingSoonDto> visible(List<ComingSoonDto> items, DateTime now) =>
      [
        for (final item in items)
          if (item.titles.isNotEmpty &&
              (item.reason == ComingSoonReason.trending ||
                  (daysUntilRelease(item.releaseDate, now) ?? 0) >= 0))
            item,
      ];

  static Future<List<ComingSoonDto>> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    if (raw == null) return const [];
    return ComingSoonDto.listFromJson(json.decode(raw));
  }

  static Future<List<ComingSoonDto>> _fetch(int count) async {
    final Response response;
    try {
      response = await fetch(count);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return _save('[]');
      rethrow;
    }
    // Not deployed yet (or rolled back): nothing to show, and nothing stale.
    if (response.statusCode == 404) return _save('[]');
    if (response.statusCode != 200) {
      throw Exception('GetComingSoon failed with ${response.statusCode}');
    }
    final body = response.data is String
        ? response.data as String
        : json.encode(response.data);
    final items = ComingSoonDto.listFromJson(json.decode(body));
    await _save(body);
    return items;
  }

  static Future<List<ComingSoonDto>> _save(String body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, body);
    return ComingSoonDto.listFromJson(json.decode(body));
  }
}
