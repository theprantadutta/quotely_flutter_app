import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/urls.dart';
import 'http_service.dart';

/// What the server made of one send.
enum ReportSendResult {
  /// Stored, or already stored (the endpoint is idempotent on clientId).
  sent,

  /// A 400: the server will never take it, so retrying is pointless.
  rejected,

  /// Offline, a timeout, a 429 or 5xx, an endpoint not deployed yet: later.
  retry,
}

typedef ReportSender =
    Future<ReportSendResult> Function(Map<String, dynamic> payload);

/// One queued report.
@immutable
class OutboxItem {
  final String clientId;
  final Map<String, dynamic> payload;
  final int attempts;
  final DateTime createdAt;

  /// Not before this time (backoff). Null: send at the next flush.
  final DateTime? nextAttemptAt;

  const OutboxItem({
    required this.clientId,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.nextAttemptAt,
  });

  OutboxItem retried(DateTime now) => OutboxItem(
    clientId: clientId,
    payload: payload,
    createdAt: createdAt,
    attempts: attempts + 1,
    nextAttemptAt: now.add(ReportOutbox.backoff(attempts + 1)),
  );

  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'payload': payload,
    'attempts': attempts,
    'createdAt': createdAt.toIso8601String(),
    if (nextAttemptAt != null) 'next': nextAttemptAt!.toIso8601String(),
  };

  factory OutboxItem.fromJson(Map<String, dynamic> j) => OutboxItem(
    clientId: j['clientId'] as String,
    payload: Map<String, dynamic>.from(j['payload'] as Map),
    attempts: j['attempts'] as int? ?? 0,
    createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
        DateTime.now(),
    nextAttemptAt: DateTime.tryParse(j['next'] as String? ?? ''),
  );
}

/// The offline outbox for content flags, feedback and bug reports.
///
/// The app is offline first, so a report is never sent directly: it is saved
/// to SharedPreferences first ([enqueue]), and the user is thanked at once.
/// [flush] then sends what is due, oldest first:
///
/// - right after each [enqueue];
/// - on app start, when the app comes back to the foreground, and when the
///   connection comes back ([start] wires these up);
/// - on a timer for the earliest backoff while the app is open.
///
/// A send that fails for a reason that can pass (offline, timeout, 429, 5xx,
/// 404 before the endpoint is deployed) stays queued with exponential
/// backoff: 30 s, 1 min, 2 min… capped at 6 h, retried for as long as it
/// takes. Only a 400, which no retry can fix, removes an unsent item. Each
/// item carries a client-generated id the server is idempotent on, so a send
/// that succeeded but whose answer was lost is harmlessly resent.
class ReportOutbox {
  ReportOutbox({
    ReportSender? sender,
    DateTime Function()? clock,
    Future<SharedPreferences> Function()? prefs,
  }) : _sender = sender ?? sendReportToApi,
       _clock = clock ?? DateTime.now,
       _prefs = prefs ?? SharedPreferences.getInstance;

  /// The app's outbox. Replaceable in tests.
  static ReportOutbox instance = ReportOutbox();

  static const storageKey = 'report-outbox-v1';

  /// A queue this long means something is badly wrong; the oldest go first.
  static const maxItems = 500;

  static const _firstBackoff = Duration(seconds: 30);
  static const _maxBackoff = Duration(hours: 6);

  /// 30 s × 2^(attempts − 1), at most 6 h.
  static Duration backoff(int attempts) {
    final factor = pow(2, max(0, attempts - 1)).toInt();
    final d = _firstBackoff * factor;
    return d > _maxBackoff ? _maxBackoff : d;
  }

  final ReportSender _sender;
  final DateTime Function() _clock;
  final Future<SharedPreferences> Function() _prefs;

  Future<int>? _flushing;
  Future<int>? _followUp;
  bool _ignoreBackoffNext = false;
  bool _started = false;
  Timer? _retryTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  AppLifecycleListener? _lifecycle;

  /// Everything still waiting to be sent, oldest first.
  Future<List<OutboxItem>> pending() async => _read(await _prefs());

  /// Saves [payload] (which must hold a `clientId`) and tries to send it.
  /// Returns once it is safely stored; the send carries on in the background.
  /// Queueing the same clientId twice keeps one copy.
  Future<void> enqueue(Map<String, dynamic> payload) async {
    final clientId = payload['clientId'];
    if (clientId is! String || clientId.isEmpty) {
      throw ArgumentError('An outbox payload needs a clientId.');
    }
    final prefs = await _prefs();
    final items = _read(prefs);
    if (items.every((i) => i.clientId != clientId)) {
      items.add(
        OutboxItem(clientId: clientId, payload: payload, createdAt: _clock()),
      );
      if (items.length > maxItems) items.removeRange(0, items.length - maxItems);
      await _write(prefs, items);
    }
    unawaited(flush());
  }

  /// Sends every due item. Returns how many were sent in its pass.
  /// Passes never overlap: a call during a pass gets one follow-up pass,
  /// shared by every caller that arrived meanwhile, so an item queued
  /// mid-pass is not left waiting and nothing is sent twice.
  Future<int> flush({bool ignoreBackoff = false}) {
    final running = _flushing;
    if (running != null) {
      _ignoreBackoffNext = _ignoreBackoffNext || ignoreBackoff;
      return _followUp ??= running.then((_) {
        _followUp = null;
        final ignore = _ignoreBackoffNext;
        _ignoreBackoffNext = false;
        return flush(ignoreBackoff: ignore);
      });
    }
    final pass = _flushOnce(ignoreBackoff).whenComplete(() {
      _flushing = null;
      if (_followUp == null) _scheduleRetry();
    });
    _flushing = pass;
    return pass;
  }

  Future<int> _flushOnce(bool ignoreBackoff) async {
    var sent = 0;
    try {
      final prefs = await _prefs();
      final now = _clock();
      final due = _read(prefs).where(
        (i) =>
            ignoreBackoff ||
            i.nextAttemptAt == null ||
            !i.nextAttemptAt!.isAfter(now),
      );
      for (final item in due.toList()) {
        ReportSendResult result;
        try {
          result = await _sender(item.payload);
        } catch (e) {
          debugPrint('Outbox: sending ${item.clientId} failed: $e');
          result = ReportSendResult.retry;
        }
        // Re-read: an enqueue may have landed while the send was in flight.
        final items = _read(prefs);
        final index = items.indexWhere((i) => i.clientId == item.clientId);
        if (index < 0) continue;
        switch (result) {
          case ReportSendResult.sent:
            items.removeAt(index);
            sent++;
          case ReportSendResult.rejected:
            debugPrint('Outbox: ${item.clientId} rejected by the server.');
            items.removeAt(index);
          case ReportSendResult.retry:
            items[index] = items[index].retried(_clock());
        }
        await _write(prefs, items);
        // Offline: the rest would fail the same way. Wait for the next flush.
        if (result == ReportSendResult.retry) break;
      }
    } catch (e) {
      debugPrint('Outbox: flush failed: $e');
    }
    return sent;
  }

  /// Flushes now, on resume, and when the connection comes back. Idempotent.
  void start() {
    if (_started) return;
    _started = true;
    try {
      _connectivity = Connectivity().onConnectivityChanged.listen((results) {
        if (results.any((r) => r != ConnectivityResult.none)) {
          unawaited(flush(ignoreBackoff: true));
        }
      });
    } catch (e) {
      debugPrint('Outbox: no connectivity events: $e');
    }
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(flush()));
    unawaited(flush());
  }

  @visibleForTesting
  void stop() {
    _started = false;
    _retryTimer?.cancel();
    _connectivity?.cancel();
    _lifecycle?.dispose();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (!_started) return;
    unawaited(() async {
      final items = await pending();
      if (items.isEmpty) return;
      final now = _clock();
      final next = items
          .map((i) => i.nextAttemptAt ?? now)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      var wait = next.difference(now);
      if (wait < const Duration(seconds: 5)) wait = const Duration(seconds: 5);
      _retryTimer = Timer(wait, () => unawaited(flush()));
    }());
  }

  List<OutboxItem> _read(SharedPreferences prefs) {
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return [
        for (final j in json.decode(raw) as List)
          OutboxItem.fromJson(Map<String, dynamic>.from(j as Map)),
      ];
    } catch (e) {
      // Never expected; keep the raw text so nothing is silently lost.
      debugPrint('Outbox: unreadable queue, kept aside: $e');
      prefs.setString('$storageKey-corrupt', raw);
      return [];
    }
  }

  Future<void> _write(SharedPreferences prefs, List<OutboxItem> items) =>
      prefs.setString(
        storageKey,
        json.encode([for (final i in items) i.toJson()]),
      );
}

/// POST Report/Submit with the app's API key.
Future<ReportSendResult> sendReportToApi(Map<String, dynamic> payload) async {
  final base = kApiUrl;
  if (base == null || base.isEmpty) return ReportSendResult.retry;
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      // Every status is answered below; none should throw.
      validateStatus: (_) => true,
    ),
  );
  try {
    final response = await dio.post<dynamic>(
      '$base/Report/Submit',
      data: payload,
      options: Options(
        contentType: Headers.jsonContentType,
        headers: {'X-Api-Key': HttpService.apiKey},
      ),
    );
    return classifyReportResponse(response.statusCode);
  } on DioException catch (e) {
    debugPrint('Outbox: Report/Submit unreachable: ${e.type}');
    return ReportSendResult.retry;
  } finally {
    dio.close();
  }
}

/// 2xx sent; 400, 413 and 422 rejected for good; anything else retried.
@visibleForTesting
ReportSendResult classifyReportResponse(int? status) {
  if (status == null) return ReportSendResult.retry;
  if (status >= 200 && status < 300) return ReportSendResult.sent;
  if (status == 400 || status == 413 || status == 422) {
    return ReportSendResult.rejected;
  }
  return ReportSendResult.retry;
}
