import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/services/report_outbox.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A server stand-in: answers from [answers] (default: sent) and records
/// every payload it received, keyed by clientId like the real endpoint.
class FakeServer {
  final List<Map<String, dynamic>> received = [];
  final Set<String> stored = {};
  ReportSendResult Function(Map<String, dynamic> payload) answer =
      (_) => ReportSendResult.sent;

  Future<ReportSendResult> send(Map<String, dynamic> payload) async {
    received.add(payload);
    final result = answer(payload);
    if (result == ReportSendResult.sent) stored.add(payload['clientId']);
    return result;
  }
}

Map<String, dynamic> _report(String id) => {
  'clientId': id,
  'kind': 'feedback',
  'message': 'Report $id',
};

void main() {
  late DateTime now;
  late FakeServer server;

  ReportOutbox outbox() =>
      ReportOutbox(sender: server.send, clock: () => now);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 11, 2, 9);
    server = FakeServer();
  });

  test('a report is stored locally and sent right away when online', () async {
    final box = outbox();
    await box.enqueue(_report('aaaaaaaa-1'));
    await box.flush();

    expect(server.stored, {'aaaaaaaa-1'});
    expect(await box.pending(), isEmpty);
  });

  test('offline: the report stays queued with backoff, then flushes', () async {
    server.answer = (_) => ReportSendResult.retry;
    final box = outbox();
    await box.enqueue(_report('aaaaaaaa-1'));
    await box.flush();

    var pending = await box.pending();
    expect(pending, hasLength(1));
    expect(pending.single.attempts, 1);
    expect(pending.single.nextAttemptAt, now.add(const Duration(seconds: 30)));

    // Still in backoff: not tried again.
    final sendsSoFar = server.received.length;
    await box.flush();
    expect(server.received.length, sendsSoFar);

    // Back online after the backoff.
    server.answer = (_) => ReportSendResult.sent;
    now = now.add(const Duration(minutes: 1));
    expect(await box.flush(), 1);
    expect(await box.pending(), isEmpty);
    expect(server.stored, {'aaaaaaaa-1'});
  });

  test('a regained connection ignores the backoff', () async {
    server.answer = (_) => ReportSendResult.retry;
    final box = outbox();
    await box.enqueue(_report('aaaaaaaa-1'));
    await box.flush();

    server.answer = (_) => ReportSendResult.sent;
    expect(await box.flush(ignoreBackoff: true), 1);
    expect(await box.pending(), isEmpty);
  });

  test('backoff doubles and is capped at 6 hours', () {
    expect(ReportOutbox.backoff(1), const Duration(seconds: 30));
    expect(ReportOutbox.backoff(2), const Duration(minutes: 1));
    expect(ReportOutbox.backoff(3), const Duration(minutes: 2));
    expect(ReportOutbox.backoff(20), const Duration(hours: 6));
  });

  test('queueing the same client id twice keeps one copy', () async {
    server.answer = (_) => ReportSendResult.retry;
    final box = outbox();
    await box.enqueue(_report('aaaaaaaa-1'));
    await box.enqueue(_report('aaaaaaaa-1'));
    expect(await box.pending(), hasLength(1));
  });

  test('every resend carries the same client id, so the server stores one',
      () async {
    // The first answer is lost (timeout) although the server stored it.
    var calls = 0;
    server.answer = (_) =>
        calls++ == 0 ? ReportSendResult.retry : ReportSendResult.sent;
    final box = outbox();
    await box.enqueue(_report('aaaaaaaa-1'));
    await box.flush();
    now = now.add(const Duration(hours: 1));
    await box.flush();

    expect(server.received, hasLength(2));
    expect(
      server.received.map((p) => p['clientId']).toSet(),
      {'aaaaaaaa-1'},
    );
    expect(await box.pending(), isEmpty);
  });

  test('concurrent flushes never send an item twice', () async {
    final gate = Completer<void>();
    final box = ReportOutbox(
      sender: (p) async {
        await gate.future;
        return server.send(p);
      },
      clock: () => now,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      ReportOutbox.storageKey,
      '[{"clientId":"aaaaaaaa-1","payload":{"clientId":"aaaaaaaa-1","kind":"bug","message":"x"},'
      '"attempts":0,"createdAt":"2026-11-02T09:00:00.000"}]',
    );

    final a = box.flush();
    final b = box.flush();
    gate.complete();
    await Future.wait([a, b]);
    await box.flush();

    expect(server.received, hasLength(1));
    expect(await box.pending(), isEmpty);
  });

  test('the queue survives a restart', () async {
    server.answer = (_) => ReportSendResult.retry;
    final before = outbox();
    await before.enqueue(_report('aaaaaaaa-1'));
    await before.enqueue(_report('aaaaaaaa-2'));
    await before.flush();

    // A new instance (the app restarted) reads the same storage.
    server.answer = (_) => ReportSendResult.sent;
    now = now.add(const Duration(days: 1));
    final after = outbox();
    expect(await after.pending(), hasLength(2));
    await after.flush();
    expect(await after.pending(), isEmpty);
    expect(server.stored, {'aaaaaaaa-1', 'aaaaaaaa-2'});
  });

  test('items go out oldest first', () async {
    server.answer = (_) => ReportSendResult.retry;
    final box = outbox();
    await box.enqueue(_report('aaaaaaaa-1'));
    await box.enqueue(_report('aaaaaaaa-2'));
    await box.enqueue(_report('aaaaaaaa-3'));
    await box.flush();

    server.received.clear();
    server.answer = (_) => ReportSendResult.sent;
    await box.flush(ignoreBackoff: true);
    expect(
      server.received.map((p) => p['clientId']),
      ['aaaaaaaa-1', 'aaaaaaaa-2', 'aaaaaaaa-3'],
    );
  });

  test('a 400 drops the report; other failures keep it', () async {
    final box = outbox();
    server.answer = (p) => p['clientId'] == 'aaaaaaaa-1'
        ? ReportSendResult.rejected
        : ReportSendResult.sent;
    await box.enqueue(_report('aaaaaaaa-1'));
    await box.flush();
    expect(await box.pending(), isEmpty);
    expect(server.stored, isEmpty);
  });

  test('a sender that throws counts as a retry, never a loss', () async {
    final box = ReportOutbox(
      sender: (_) async => throw Exception('socket closed'),
      clock: () => now,
    );
    await box.enqueue(_report('aaaaaaaa-1'));
    await box.flush();
    expect(await box.pending(), hasLength(1));
  });

  test('HTTP statuses map to sent, rejected or retry', () {
    expect(classifyReportResponse(200), ReportSendResult.sent);
    expect(classifyReportResponse(400), ReportSendResult.rejected);
    expect(classifyReportResponse(404), ReportSendResult.retry);
    expect(classifyReportResponse(429), ReportSendResult.retry);
    expect(classifyReportResponse(503), ReportSendResult.retry);
    expect(classifyReportResponse(null), ReportSendResult.retry);
  });
}
