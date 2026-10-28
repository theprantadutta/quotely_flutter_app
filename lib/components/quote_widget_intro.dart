import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';
import '../riverpods/scene_providers.dart';
import '../riverpods/today_quote_of_the_day_provider.dart';
import '../services/quote_widget_service.dart';
import 'thread/thread.dart';

/// Telling people the Quote of the Day home-screen widget exists:
/// - [maybeShowQuoteWidgetIntro]: a one-time introduction on Today, from the
///   second app open on and only once onboarding is done;
/// - [addQuoteWidget]: what "Add widget" does, here and in You → Home-screen
///   widget. Android launchers that support it pin the widget directly;
///   everywhere else (and always on iOS, which has no API for it) a short
///   sheet explains how to add it by hand.
class QuoteWidgetIntro {
  QuoteWidgetIntro._();

  static bool _countedThisRun = false;

  /// The widget exists on Android and iOS only.
  static bool get platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Counts this app open, once per run.
  static Future<int> recordAppOpen(SharedPreferences prefs) async {
    final count = prefs.getInt(kAppOpenCountKey) ?? 0;
    if (_countedThisRun) return count;
    _countedThisRun = true;
    await prefs.setInt(kAppOpenCountKey, count + 1);
    return count + 1;
  }

  /// Not yet shown, onboarding finished (the same three gates as the router),
  /// and not the first open.
  static bool shouldShow(SharedPreferences prefs) =>
      platformSupported &&
      !(prefs.getBool(kQuoteWidgetIntroShownKey) ?? false) &&
      (prefs.getBool('onboardingShown') ?? false) &&
      (prefs.getBool(kHasSelectedInterestsKey) ?? false) &&
      (prefs.getBool(kHasSeenNotificationPrompt) ?? false) &&
      (prefs.getInt(kAppOpenCountKey) ?? 0) >= 2;

  @visibleForTesting
  static void debugReset() => _countedThisRun = false;
}

/// Counts the open and, if it is time, shows the introduction once. Called
/// by Today after the legal consent sheet, so the two never stack.
Future<void> maybeShowQuoteWidgetIntro(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await QuoteWidgetIntro.recordAppOpen(prefs);
  if (!QuoteWidgetIntro.shouldShow(prefs) || !context.mounted) return;
  // Remembered as soon as it is shown: dismissing it by swiping counts too.
  await prefs.setBool(kQuoteWidgetIntroShownKey, true);
  if (!context.mounted) return;
  final add = await showQSheet<bool>(
    context,
    builder: (sheet) => const _IntroSheet(),
  );
  if (add == true && context.mounted) await addQuoteWidget(context);
}

/// "Add widget": pin it where the launcher allows, otherwise explain how.
Future<void> addQuoteWidget(BuildContext context) async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      if (await HomeWidget.isRequestPinWidgetSupported() ?? false) {
        await HomeWidget.requestPinWidget(
          qualifiedAndroidName: QuoteWidgetService.androidProvider,
        );
        return;
      }
    } catch (e) {
      debugPrint('Pinning the widget failed: $e');
    }
  }
  if (!context.mounted) return;
  await showQuoteWidgetHowTo(context);
}

/// Platform-specific steps for adding the widget by hand.
Future<void> showQuoteWidgetHowTo(BuildContext context) {
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  final steps = ios
      ? const [
          'Touch and hold an empty spot on your Home Screen until the apps '
              'jiggle.',
          'Tap + (or Edit, then Add Widget) in the top corner.',
          'Search for Quotely, pick a size and tap Add Widget.',
        ]
      : const [
          'Touch and hold an empty spot on your home screen.',
          'Tap Widgets.',
          'Find Quotely, then drag Quote of the Day onto your home screen.',
        ];
  return showQSheet<void>(
    context,
    builder: (sheet) => QSheetFrame(
      title: 'Add the widget',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    child: Text(
                      '${i + 1}',
                      style: sheet.qt.overline.copyWith(color: sheet.q.ink),
                    ),
                  ),
                  Expanded(child: Text(steps[i], style: sheet.qt.body)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: 'Got it',
            onPressed: () => Navigator.of(sheet).pop(),
          ),
        ],
      ),
    ),
  );
}

class _IntroSheet extends StatelessWidget {
  const _IntroSheet();

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    return QSheetFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('NEW · HOME-SCREEN WIDGET', style: qt.overline),
          const SizedBox(height: 14),
          const QuoteWidgetPreview(),
          const SizedBox(height: 20),
          Text(
            "Put today's quote on your home screen",
            style: qt.quoteBody.copyWith(color: t.ink),
          ),
          const SizedBox(height: 8),
          Text(
            "A new line every day, over the day's poster, without opening "
            'the app.',
            style: qt.body.copyWith(color: t.mute),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Add widget',
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Not now',
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

/// A small likeness of the medium widget: today's quote over the day's
/// poster when the app has them, a sample line otherwise.
class QuoteWidgetPreview extends ConsumerWidget {
  const QuoteWidgetPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final qt = context.qt;
    final quote = ref.watch(fetchTodayQuoteOfTheDayProvider).value;
    final poster = ref.watch(sceneOfTheDayProvider).value?.sceneQuote.posterUrl;
    final text =
        quote?.content.trim() ?? 'It always seems impossible until it’s done.';
    final author = quote?.author.trim() ?? 'Nelson Mandela';
    return Semantics(
      label: 'Widget preview',
      excludeSemantics: true,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: t.line),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (poster != null && poster.isNotEmpty)
                PosterWash(url: poster)
              else
                ColoredBox(color: t.surf),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUOTE OF THE DAY',
                      style: qt.overline.copyWith(fontSize: 9),
                    ),
                    const Spacer(),
                    Text(
                      text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: qt.quoteCompact.copyWith(fontSize: 19),
                    ),
                    const Spacer(),
                    Text(
                      '— $author',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: qt.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
