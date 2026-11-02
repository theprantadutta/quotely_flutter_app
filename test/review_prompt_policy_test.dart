import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/services/review_prompt_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  late ReviewPromptPolicy policy;

  Future<void> make() async {
    policy = ReviewPromptPolicy(
      await SharedPreferences.getInstance(),
      clock: () => now,
    );
  }

  /// Opens the app once a day for [days] days, starting today.
  Future<void> useDaily(int days) async {
    for (var i = 0; i < days; i++) {
      await policy.recordAppOpen();
      now = now.add(const Duration(days: 1));
    }
    now = now.subtract(const Duration(days: 1));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 1, 1, 10);
    await make();
  });

  test('opens on the same day count once; first open is kept', () async {
    await policy.recordAppOpen();
    now = now.add(const Duration(hours: 5));
    await policy.recordAppOpen();
    expect(policy.activeDays, 1);
    now = now.add(const Duration(days: 1));
    await policy.recordAppOpen();
    expect(policy.activeDays, 2);
    expect(policy.firstOpen, DateTime(2026, 1, 1, 10));
  });

  test('not due before any use', () {
    expect(policy.isDue, isFalse);
  });

  test('not due after 14 active days, due after 15', () async {
    await useDaily(14);
    expect(policy.isDue, isFalse);
    now = now.add(const Duration(days: 1));
    await policy.recordAppOpen();
    expect(policy.activeDays, 15);
    expect(policy.isDue, isTrue);
  });

  test('due 30 days after the first open even with few active days', () async {
    await policy.recordAppOpen();
    now = now.add(const Duration(days: 29));
    await policy.recordAppOpen();
    expect(policy.isDue, isFalse);
    now = now.add(const Duration(days: 1));
    expect(policy.activeDays, 2);
    expect(policy.isDue, isTrue);
  });

  test('re-asked only after 30 days, whatever the answer', () async {
    await useDaily(15);
    await policy.recordShown();
    await policy.recordAnswer(ReviewPromptAnswer.later);
    expect(policy.isDue, isFalse);

    now = now.add(const Duration(days: 29));
    expect(policy.isDue, isFalse);
    now = now.add(const Duration(days: 1));
    expect(policy.isDue, isTrue);
  });

  test('"Not really" waits 30 days too', () async {
    await useDaily(15);
    await policy.recordShown();
    await policy.recordAnswer(ReviewPromptAnswer.notReally);
    now = now.add(const Duration(days: 30));
    expect(policy.isDue, isTrue);
    expect(policy.lastAnswer, 'not_really');
  });

  test('after "Yes!" it stays quiet for 120 days', () async {
    await useDaily(15);
    await policy.recordShown();
    await policy.recordAnswer(ReviewPromptAnswer.yes);

    now = now.add(const Duration(days: 31));
    expect(policy.isDue, isFalse);
    now = now.add(const Duration(days: 88)); // 119 days
    expect(policy.isDue, isFalse);
    now = now.add(const Duration(days: 1)); // 120 days
    expect(policy.isDue, isTrue);
  });

  test('asked at most 4 times ever', () async {
    await useDaily(15);
    for (var i = 0; i < ReviewPromptPolicy.maxAsks; i++) {
      expect(policy.isDue, isTrue, reason: 'ask ${i + 1}');
      await policy.recordShown();
      await policy.recordAnswer(ReviewPromptAnswer.later);
      now = now.add(const Duration(days: 31));
    }
    expect(policy.timesAsked, ReviewPromptPolicy.maxAsks);
    now = now.add(const Duration(days: 365));
    expect(policy.isDue, isFalse);
  });

  test('state survives a restart', () async {
    await useDaily(15);
    await policy.recordShown();
    await make(); // a new instance over the same SharedPreferences
    expect(policy.activeDays, 15);
    expect(policy.timesAsked, 1);
    expect(policy.isDue, isFalse);
  });
}
