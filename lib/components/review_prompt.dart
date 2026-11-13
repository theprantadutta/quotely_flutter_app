import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_analytics.dart';
import '../services/review_prompt_policy.dart';
import '../services/store_review.dart';
import 'feedback_sheet.dart';
import 'thread/thread.dart';

/// App-wide hooks for the "Enjoying Quotely?" prompt.
abstract final class ReviewPrompt {
  /// Clock for the policy. Replaceable in tests.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  static bool _shownThisSession = false;
  static AppLifecycleListener? _lifecycle;

  @visibleForTesting
  static void resetSession() => _shownThisSession = false;

  static Future<ReviewPromptPolicy> policy() async =>
      ReviewPromptPolicy(await SharedPreferences.getInstance(), clock: clock);

  /// Counts today as a day of use now and on every resume. Never throws.
  static Future<void> start() async {
    Future<void> record() async {
      try {
        await (await policy()).recordAppOpen();
      } catch (e) {
        debugPrint('Recording app use failed: $e');
      }
    }

    _lifecycle ??= AppLifecycleListener(onResume: () => unawaited(record()));
    await record();
  }

  /// Shows the prompt if it is due, at a calm moment. Waits [settle] (content
  /// loaded, the user reading), then shows it only while [isCalm] holds and
  /// nothing else is on top: no sheet, dialog or pushed screen. If the moment
  /// isn't calm it checks again every [retryEvery], up to [attempts] times,
  /// then gives up for this session.
  static Future<void> maybeShow(
    BuildContext context, {
    required bool Function() isCalm,
    Duration settle = const Duration(seconds: 8),
    Duration retryEvery = const Duration(seconds: 10),
    int attempts = 6,
  }) async {
    if (_shownThisSession) return;
    try {
      if (!(await policy()).isDue) return;
      await Future<void>.delayed(settle);
      for (var i = 0; i < attempts; i++) {
        if (!context.mounted || _shownThisSession) return;
        if (isCalm() && _nothingOnTop(context)) {
          await _show(context);
          return;
        }
        await Future<void>.delayed(retryEvery);
      }
    } catch (e) {
      debugPrint('Review prompt failed: $e');
    }
  }

  static bool _nothingOnTop(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    final root = Navigator.maybeOf(context, rootNavigator: true);
    return root == null || !root.canPop();
  }

  static Future<void> _show(BuildContext context) async {
    _shownThisSession = true;
    final p = await policy();
    if (!p.isDue || !context.mounted) return;
    await p.recordShown();
    logAppEvent('review_prompt_shown', {'times_asked': p.timesAsked});
    if (!context.mounted) return;
    final answer = await showQSheet<ReviewPromptAnswer>(
      context,
      builder: (_) => const ReviewPromptSheet(),
    );
    final effective = answer ?? ReviewPromptAnswer.later;
    await p.recordAnswer(effective);
    logAppEvent('review_prompt_answer', {
      'answer': answer?.wire ?? 'dismissed',
    });
    switch (effective) {
      case ReviewPromptAnswer.yes:
        await requestInAppReview();
      case ReviewPromptAnswer.notReally:
        if (context.mounted) {
          await showFeedbackSheet(context, title: 'What could be better?');
        }
      case ReviewPromptAnswer.later:
        break;
    }
  }
}

/// "Enjoying Quotely?": Yes! / Not really / Later.
class ReviewPromptSheet extends StatelessWidget {
  const ReviewPromptSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    void answer(ReviewPromptAnswer a) => Navigator.of(context).pop(a);
    return QSheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: BrandIcon(size: 56, radius: 13)),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              'Enjoying Quotely?',
              textAlign: TextAlign.center,
              style: context.qt.sectionTitle,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You’ve been reading with us for a while. We’d love to know how '
            'it’s going.',
            textAlign: TextAlign.center,
            style: context.qt.body.copyWith(color: t.mute),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Yes!',
            onPressed: () => answer(ReviewPromptAnswer.yes),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Not really',
            onPressed: () => answer(ReviewPromptAnswer.notReally),
          ),
          const SizedBox(height: 4),
          Center(
            child: QTextButton(
              label: 'Later',
              onPressed: () => answer(ReviewPromptAnswer.later),
            ),
          ),
        ],
      ),
    );
  }
}
