import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:shared_preferences/shared_preferences.dart';

import 'http_service.dart';

/// The app's data rule: **local first**.
///
/// - The local copy has something: return it immediately, and refresh from
///   the backend in the background. The fresh result is saved for next time;
///   the screen the user is reading does not change under them.
/// - The local copy is empty (first launch, a new filter): wait for the
///   backend, which saves as it goes.
/// - The backend fails: the (empty) local result is returned, as the old
///   fallback did, and the screen shows its empty state. Only a failed local
///   read plus a failed backend surfaces the error.
///
/// Background refreshes are de-duplicated per [key] and throttled to
/// [refreshEvery], so paging through a feed doesn't refetch every page.
class LocalFirst {
  LocalFirst._();

  static const refreshEvery = Duration(minutes: 10);
  static final Map<String, DateTime> _refreshed = {};
  static final Set<String> _inFlight = {};

  static Future<T> load<T>({
    required String key,
    required Future<T> Function() local,
    required Future<T> Function() remote,
    required bool Function(T value) isEmpty,
  }) async {
    T? cached;
    try {
      cached = await local();
    } catch (e) {
      debugPrint('LocalFirst[$key]: local read failed: $e');
    }
    if (cached != null && !isEmpty(cached)) {
      refreshInBackground(key, remote);
      return cached;
    }
    try {
      final value = await remote();
      _refreshed[key] = DateTime.now();
      return value;
    } catch (e) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  /// Runs [remote] (which saves its own result) without waiting for it.
  static void refreshInBackground<T>(String key, Future<T> Function() remote) {
    if (_inFlight.contains(key)) return;
    final last = _refreshed[key];
    if (last != null && DateTime.now().difference(last) < refreshEvery) return;
    _inFlight.add(key);
    unawaited(
      remote()
          .then<void>(
            (_) => _refreshed[key] = DateTime.now(),
            onError: (Object e) =>
                debugPrint('LocalFirst[$key]: background refresh failed: $e'),
          )
          .whenComplete(() => _inFlight.remove(key)),
    );
  }

  // --- Endpoints without a table: a saved copy of the last good response --

  static const _prefix = 'lf-cache:';

  /// GET [url] local first, from a saved copy of its last 200 response.
  ///
  /// [todayOnly]: a copy saved on an earlier day doesn't count (today's
  /// picks); the backend is waited for instead.
  /// [ignoreParams]: query parameters left out of the cache key, such as the
  /// session's random `seed`, so the copy survives a new session.
  static Future<Response> get(
    String url, {
    bool todayOnly = false,
    Set<String> ignoreParams = const {'seed'},
  }) {
    final key = _keyFor(url, ignoreParams);
    return load<Response>(
      key: key,
      local: () async {
        final body = await _read(key, todayOnly: todayOnly);
        return Response(
          requestOptions: RequestOptions(path: url),
          statusCode: body == null ? 204 : 200,
          data: body,
        );
      },
      remote: () async {
        final response = await HttpService.get(url);
        if (response.statusCode == 200 && response.data is String) {
          await _write(key, response.data as String);
        }
        return response;
      },
      isEmpty: (r) => r.statusCode != 200,
    );
  }

  static String _keyFor(String url, Set<String> ignoreParams) {
    final uri = Uri.parse(url);
    final params = Map.of(uri.queryParameters)
      ..removeWhere((k, _) => ignoreParams.contains(k));
    final keys = params.keys.toList()..sort();
    final query = [for (final k in keys) '$k=${params[k]}'].join('&');
    return '$_prefix${uri.path}?$query';
  }

  static String _day(DateTime d) =>
      DateUtils.dateOnly(d).toIso8601String().substring(0, 10);

  static Future<String?> _read(String key, {required bool todayOnly}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final saved = json.decode(raw) as Map<String, dynamic>;
    if (todayOnly && saved['day'] != _day(DateTime.now())) return null;
    return saved['body'] as String?;
  }

  static Future<void> _write(String key, String body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      json.encode({'day': _day(DateTime.now()), 'body': body}),
    );
  }
}
