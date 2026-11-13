import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/feedback_sheet.dart';
import 'package:quotely_flutter_app/components/review_prompt.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/dtos/ai_fact_dto.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/services/report_outbox.dart';
import 'package:quotely_flutter_app/services/review_prompt_policy.dart';
import 'package:quotely_flutter_app/services/store_review.dart' as store;
import 'package:quotely_flutter_app/services/user_reports.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _d = DateTime.utc(2026);

final _quote = QuoteDto(
  id: 'quote-42',
  author: 'Nelson Mandela',
  content: 'It always seems impossible until it’s done.',
  tags: const ['hope'],
  authorSlug: 'nelson-mandela',
  length: 44,
  dateAdded: _d,
  dateModified: _d,
);

final _fact = AiFactDto(
  id: 7,
  content: 'Octopuses have three hearts.',
  aiFactCategory: 'Animals',
  provider: 'test',
  dateAdded: _d,
  dateModified: _d,
);

/// A host page with one button that runs [onTap] with a context under the
/// app's theme, navigator and ScaffoldMessenger.
Widget _host(void Function(BuildContext context) onTap) => ProviderScope(
  child: MaterialApp(
    theme: buildQuotelyTheme(Brightness.light, const AppearanceSettings()),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => onTap(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ),
);

/// Offline: every send fails, so whatever is queued stays in the outbox.
ReportOutbox _offlineOutbox() =>
    ReportOutbox(sender: (_) async => ReportSendResult.retry);

Future<List<Map<String, dynamic>>> _queued() async => [
  for (final i in await ReportOutbox.instance.pending()) i.payload,
];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ReportOutbox.instance = _offlineOutbox();
    UserReports.deviceContext = () async => {
      'platform': 'android',
      'appVersion': '3.1.1+24',
    };
  });

  group('content flag sheet', () {
    testWidgets('queues the flag offline and thanks the user at once', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          (c) => showReportSheet(c, ThreadMessage.fromQuote(_quote)),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Report this quote'), findsOneWidget);
      await tester.tap(find.text('Wrong author'));
      await tester.enterText(
        find.byKey(const Key('report-correction')),
        'Maya Angelou',
      );
      await tester.ensureVisible(find.text('Send report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(find.text('Report this quote'), findsNothing);
      expect(find.text(kReportThanks), findsOneWidget);

      final queued = await _queued();
      expect(queued, hasLength(1));
      final p = queued.single;
      expect(p['kind'], 'content_flag');
      expect(p['contentType'], 'quote');
      expect(p['contentId'], 'quote-42');
      expect(p['reason'], 'Wrong author');
      expect(p['correction'], 'Maya Angelou');
      expect(p['contentSnapshot'], contains('impossible'));
      expect(p['platform'], 'android');
      expect(p.containsKey('contactEmail'), isFalse);
      expect((p['clientId'] as String).length, 36);
    });

    testWidgets('fact flags send the numeric id and the free text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host((c) => showReportSheet(c, ThreadMessage.fromFact(_fact))),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Something else'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('report-issue')),
        'It is actually three hearts and blue blood',
      );
      await tester.ensureVisible(find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      final p = (await _queued()).single;
      expect(p['contentType'], 'fact');
      expect(p['contentId'], '7');
      expect(p['reason'], 'Something else');
      expect(p['message'], startsWith('It is actually'));
    });

    testWidgets('a malformed contact email blocks the send', (tester) async {
      await tester.pumpWidget(
        _host((c) => showReportSheet(c, ThreadMessage.fromQuote(_quote))),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('+ Add contact email'));
      await tester.tap(find.text('+ Add contact email'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('report-email')), 'nope');
      await tester.ensureVisible(find.text('Send report'));
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(find.textContaining('doesn’t look like an email'), findsOneWidget);
      expect(await _queued(), isEmpty);
    });
  });

  group('feedback sheet', () {
    testWidgets('Send stays off until there is a message', (tester) async {
      await tester.pumpWidget(_host((c) => showFeedbackSheet(c)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final send = find.widgetWithText(PrimaryButton, 'Send');
      expect(tester.widget<PrimaryButton>(send).onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('feedback-message')),
        'More scenes from anime please',
      );
      await tester.pump();
      expect(tester.widget<PrimaryButton>(send).onPressed, isNotNull);
    });

    testWidgets('queues a bug report with email and device info', (
      tester,
    ) async {
      await tester.pumpWidget(_host((c) => showFeedbackSheet(c)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Email (optional)'), findsOneWidget);
      await tester.tap(find.text('Bug'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('feedback-message')),
        'The widget stays blank after a reboot',
      );
      await tester.enterText(
        find.byKey(const Key('feedback-email')),
        'me@example.com',
      );
      await tester.ensureVisible(find.text('Send'));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text(kReportThanks), findsOneWidget);
      final p = (await _queued()).single;
      expect(p['kind'], 'bug');
      expect(p['message'], 'The widget stays blank after a reboot');
      expect(p['contactEmail'], 'me@example.com');
      expect(p['platform'], 'android');
    });

    testWidgets('unticking device info leaves it out', (tester) async {
      await tester.pumpWidget(_host((c) => showFeedbackSheet(c)));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback-message')),
        'Love it',
      );
      await tester.ensureVisible(find.byKey(const Key('feedback-device')));
      await tester.tap(find.byKey(const Key('feedback-device')));
      await tester.pump();
      await tester.ensureVisible(find.text('Send'));
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      final p = (await _queued()).single;
      expect(p['kind'], 'feedback');
      expect(p.containsKey('platform'), isFalse);
      expect(p.containsKey('appVersion'), isFalse);
      expect(p.containsKey('contactEmail'), isFalse);
    });
  });

  group('review prompt', () {
    final now = DateTime(2026, 11, 2, 10);
    late int reviewRequests;

    setUp(() {
      // First opened 40 days ago: due.
      SharedPreferences.setMockInitialValues({
        ReviewPromptPolicy.kFirstOpen: now
            .subtract(const Duration(days: 40))
            .toIso8601String(),
        ReviewPromptPolicy.kActiveDays: 6,
      });
      ReviewPrompt.clock = () => now;
      ReviewPrompt.resetSession();
      reviewRequests = 0;
      store.requestInAppReview = () async => reviewRequests++;
    });

    Widget prompt() => _host(
      (c) => ReviewPrompt.maybeShow(
        c,
        isCalm: () => true,
        settle: Duration.zero,
        retryEvery: Duration.zero,
        attempts: 1,
      ),
    );

    testWidgets('"Yes!" asks the OS for a review and is remembered', (
      tester,
    ) async {
      await tester.pumpWidget(prompt());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Enjoying Quotely?'), findsOneWidget);
      await tester.tap(find.text('Yes!'));
      await tester.pumpAndSettle();

      expect(reviewRequests, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(ReviewPromptPolicy.kTimesAsked), 1);
      expect(prefs.getString(ReviewPromptPolicy.kLastAnswer), 'yes');
    });

    testWidgets('"Not really" opens the feedback sheet', (tester) async {
      await tester.pumpWidget(prompt());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not really'));
      await tester.pumpAndSettle();

      expect(find.text('What could be better?'), findsOneWidget);
      expect(reviewRequests, 0);
    });

    testWidgets('shown once per session', (tester) async {
      await tester.pumpWidget(prompt());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Enjoying Quotely?'), findsNothing);
    });

    testWidgets('never over another sheet', (tester) async {
      late BuildContext page;
      await tester.pumpWidget(
        _host((c) {
          page = c;
          showQSheet(c, builder: (_) => const Text('another sheet'));
        }),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('another sheet'), findsOneWidget);

      // Not awaited: its delays only advance while the tester pumps.
      unawaited(
        ReviewPrompt.maybeShow(
          page,
          isCalm: () => true,
          settle: Duration.zero,
          retryEvery: Duration.zero,
          attempts: 1,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Enjoying Quotely?'), findsNothing);
    });

    testWidgets('not shown before it is due', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(prompt());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Enjoying Quotely?'), findsNothing);
    });
  });
}
