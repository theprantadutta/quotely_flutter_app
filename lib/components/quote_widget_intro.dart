import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';
import '../database/database.dart';
import '../riverpods/scene_providers.dart';
import '../riverpods/today_quote_of_the_day_provider.dart';
import '../service_locator/init_service_locators.dart';
import '../services/drift_quote_service.dart';
import '../services/home_widget_store.dart';
import '../services/saved_widget_service.dart';
import '../services/scene_widget_service.dart';
import '../services/widget_analytics.dart';
import 'thread/thread.dart';

/// Telling people the home-screen widgets exist (Quote of the Day, From your
/// saved, Scene of the Day):
/// - [maybeShowQuoteWidgetIntro]: a one-time introduction on Today, from the
///   second app open on and only once onboarding is done;
/// - [chooseQuoteWidget]: You → Home-screen widgets, the same choice of three;
/// - [addQuoteWidget]: what "Add widget" does for the chosen one. Android
///   launchers that support it pin the widget directly; everywhere else (and
///   always on iOS, which has no API for it) a short sheet explains how to
///   add it by hand.
class QuoteWidgetIntro {
  QuoteWidgetIntro._();

  static bool _countedThisRun = false;

  /// The widgets exist on Android and iOS only.
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
  final kind = await showQSheet<QuotelyWidgetKind>(
    context,
    builder: (sheet) => const _ChooserSheet(intro: true),
  );
  if (kind != null && context.mounted) {
    await addQuoteWidget(context, kind: kind, source: 'intro');
  }
}

/// You → Home-screen widgets: pick one of the three, then add it.
Future<void> chooseQuoteWidget(BuildContext context) async {
  final kind = await showQSheet<QuotelyWidgetKind>(
    context,
    builder: (sheet) => const _ChooserSheet(intro: false),
  );
  if (kind != null && context.mounted) {
    await addQuoteWidget(context, kind: kind, source: 'you');
  }
}

/// "Add widget": pin [kind] where the launcher allows, otherwise explain how.
Future<void> addQuoteWidget(
  BuildContext context, {
  QuotelyWidgetKind kind = QuotelyWidgetKind.qotd,
  String source = 'you',
}) async {
  WidgetAnalytics.addTapped(kind, source);
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      if (await HomeWidget.isRequestPinWidgetSupported() ?? false) {
        await HomeWidget.requestPinWidget(
          qualifiedAndroidName: kind.androidProvider,
        );
        return;
      }
    } catch (e) {
      debugPrint('Pinning the widget failed: $e');
    }
  }
  if (!context.mounted) return;
  await showQuoteWidgetHowTo(context, kind: kind);
}

/// Platform-specific steps for adding [kind] by hand.
Future<void> showQuoteWidgetHowTo(
  BuildContext context, {
  QuotelyWidgetKind kind = QuotelyWidgetKind.qotd,
}) {
  final ios = defaultTargetPlatform == TargetPlatform.iOS;
  final steps = ios
      ? [
          'Touch and hold an empty spot on your Home Screen until the apps '
              'jiggle.',
          'Tap + (or Edit, then Add Widget) in the top corner.',
          'Search for Quotely, swipe to ${kind.label}, pick a size and tap '
              'Add Widget.',
        ]
      : [
          'Touch and hold an empty spot on your home screen.',
          'Tap Widgets.',
          'Find Quotely, then drag ${kind.label} onto your home screen.',
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
          if (ios)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'On the Lock Screen: touch and hold it, tap Customize, pick '
                'the Lock Screen, then tap the area under the clock and '
                'choose Quotely.',
                style: sheet.qt.body.copyWith(color: sheet.q.mute),
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

/// The person's saved quotes, for the From your saved preview. Empty when
/// the database isn't there (tests) or can't be read.
final savedWidgetPreviewProvider = FutureProvider<List<SavedWidgetQuote>>((
  ref,
) async {
  if (!getIt.isRegistered<AppDatabase>()) return const [];
  try {
    final rows = await DriftQuoteService.getAllFavoriteQuotes(const []);
    return rows.map(SavedWidgetQuote.fromDrift).toList();
  } catch (_) {
    return const [];
  }
});

/// Text shown in the previews, the widgets' own sample and hint lines.
const _sampleQuote = 'It always seems impossible until it’s done.';
const _sampleAuthor = 'Nelson Mandela';
const _savedHint = 'Save a quote you love and it will live here.';
const _sampleScene = 'Keep your friends close, but your enemies closer.';

String _blurb(QuotelyWidgetKind kind) => switch (kind) {
  QuotelyWidgetKind.qotd =>
    "Today's quote, over the day's poster. A new line every day.",
  QuotelyWidgetKind.saved =>
    'One of the quotes you saved, a different one each day. Works offline.',
  QuotelyWidgetKind.scene =>
    "Today's scene line, over its title's poster, with who said it.",
};

/// The introduction (on Today) and You's chooser: the three widgets as small
/// previews; "Add widget" pops the chosen one.
class _ChooserSheet extends StatefulWidget {
  final bool intro;

  const _ChooserSheet({required this.intro});

  @override
  State<_ChooserSheet> createState() => _ChooserSheetState();
}

class _ChooserSheetState extends State<_ChooserSheet> {
  var _kind = QuotelyWidgetKind.qotd;

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    return QSheetFrame(
      title: widget.intro ? null : 'Home-screen widgets',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.intro) ...[
            Text('NEW · HOME-SCREEN WIDGETS', style: qt.overline),
            const SizedBox(height: 14),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final k in QuotelyWidgetKind.values) ...[
                if (k != QuotelyWidgetKind.values.first)
                  const SizedBox(width: 10),
                Expanded(
                  child: _ChoiceTile(
                    kind: k,
                    selected: k == _kind,
                    onTap: () => setState(() => _kind = k),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          if (widget.intro) ...[
            Text(
              'Put Quotely on your home screen',
              style: qt.quoteBody.copyWith(color: t.ink),
            ),
            const SizedBox(height: 8),
          ],
          Text(_blurb(_kind), style: qt.body.copyWith(color: t.mute)),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Add widget',
            onPressed: () => Navigator.of(context).pop(_kind),
          ),
          if (widget.intro) ...[
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Not now',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final QuotelyWidgetKind kind;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      button: true,
      selected: selected,
      label: '${kind.label} widget',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? t.acc : Colors.transparent,
                  width: 2,
                ),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: QuoteWidgetPreview(kind: kind, small: true),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              kind.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: context.qt.caption.copyWith(
                color: selected ? t.ink : t.mute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small likeness of one of the widgets with today's real content when
/// the app has it (today's quote, a saved quote, today's scene), a sample
/// line otherwise. [small] is the square widget; otherwise the medium one.
class QuoteWidgetPreview extends ConsumerWidget {
  final QuotelyWidgetKind kind;
  final bool small;

  const QuoteWidgetPreview({
    super.key,
    this.kind = QuotelyWidgetKind.qotd,
    this.small = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.watch(sceneOfTheDayProvider).value?.sceneQuote;
    final (eyebrow, text, footer, poster) = switch (kind) {
      QuotelyWidgetKind.qotd => () {
        final quote = ref.watch(fetchTodayQuoteOfTheDayProvider).value;
        return (
          'QUOTE OF THE DAY',
          quote?.content.trim() ?? _sampleQuote,
          quote?.author.trim() ?? _sampleAuthor,
          scene?.posterUrl,
        );
      }(),
      QuotelyWidgetKind.saved => () {
        final saved = ref.watch(savedWidgetPreviewProvider).value ?? const [];
        final pick = SavedWidgetService.pickFor(saved, DateTime.now());
        return (
          'FROM YOUR SAVED',
          pick?.text ?? _savedHint,
          pick?.author,
          null,
        );
      }(),
      QuotelyWidgetKind.scene => (
        SceneWidgetService.eyebrow(scene?.titleName ?? 'The Godfather'),
        scene?.content.trim() ?? _sampleScene,
        scene == null
            ? 'Michael Corleone, The Godfather'
            : '${scene.characterName}, ${scene.titleName}',
        scene?.posterUrl,
      ),
    };
    return Semantics(
      label: '${kind.label} widget preview',
      excludeSemantics: true,
      child: _Likeness(
        eyebrow: eyebrow,
        text: text,
        footer: footer,
        poster: poster,
        glow: kind != QuotelyWidgetKind.qotd,
        small: small,
      ),
    );
  }
}

class _Likeness extends StatelessWidget {
  final String eyebrow;
  final String text;
  final String? footer;
  final String? poster;

  /// Without a poster: the page with the day's glow, else the plain surface.
  final bool glow;
  final bool small;

  const _Likeness({
    required this.eyebrow,
    required this.text,
    required this.footer,
    required this.poster,
    required this.glow,
    required this.small,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    final radius = small ? 16.0 : 22.0;
    final url = poster;
    return Container(
      height: small ? null : 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: t.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null && url.isNotEmpty)
              PosterWash(url: url)
            else if (glow)
              DayGlow(day: DateTime.now())
            else
              ColoredBox(color: t.surf),
            Padding(
              padding: small
                  ? const EdgeInsets.fromLTRB(9, 9, 9, 8)
                  : const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: qt.overline.copyWith(fontSize: small ? 6 : 9),
                  ),
                  const Spacer(),
                  Text(
                    text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: qt.quoteCompact.copyWith(
                      fontSize: small ? 11 : 19,
                      height: small ? 1.1 : null,
                    ),
                  ),
                  const Spacer(),
                  // Too small to read in the tiles; the line says enough.
                  if (!small && footer != null && footer!.isNotEmpty)
                    Text(
                      '— $footer',
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
    );
  }
}
