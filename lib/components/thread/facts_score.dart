import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../../riverpods/scene_providers.dart';
import '../../services/app_analytics.dart';
import '../../services/facts_game.dart';
import '../../theme/app_theme.dart';
import 'message_actions.dart';
import 'q_controls.dart';
import 'q_sheet.dart';
import 'share_card.dart';

/// One dot per question of the day: accent for right, a muted fill for
/// wrong, an empty ring for not answered yet.
class FactsScoreDots extends StatelessWidget {
  final List<bool> results;
  final int total;
  final double size;
  final double gap;

  const FactsScoreDots({
    super.key,
    required this.results,
    this.total = kFactsPerDay,
    this.size = 12,
    this.gap = 8,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final right = results.where((r) => r).length;
    final wrong = results.length - right;
    return Semantics(
      label: '$right right, $wrong wrong',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Container(
              key: ValueKey('facts-dot-$i'),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i >= results.length
                    ? Colors.transparent
                    : results[i]
                    ? t.acc
                    : t.mute.withValues(alpha: 0.32),
                border: i >= results.length
                    ? Border.all(color: t.line, width: 1.5)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The end of the day's round: the score large in the serif, a verdict,
/// the dots, the streak, then Share my score and Browse facts.
class FactsResultCard extends StatelessWidget {
  final FactsRound round;
  final int streak;
  final int best;
  final VoidCallback onShare;
  final VoidCallback onBrowse;

  const FactsResultCard({
    super.key,
    required this.round,
    required this.streak,
    required this.best,
    required this.onShare,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    final streakLabel = factsStreakLabel(streak);
    final bestLine = best > streak ? 'Best $best' : null;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(26, 6, 26, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (box.maxHeight - 22).clamp(0, double.infinity),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  Text('TODAY’S ROUND', style: qt.overline),
                  const SizedBox(height: 14),
                  Semantics(
                    label: '${round.correct} out of $kFactsPerDay today',
                    excludeSemantics: true,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${round.correct}/$kFactsPerDay'),
                          TextSpan(
                            text: ' today',
                            style: qt.quoteFact.copyWith(color: t.mute),
                          ),
                        ],
                      ),
                      style: qt.quoteSpotlight.copyWith(
                        fontSize: 72,
                        height: 1,
                        color: t.ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(factsVerdict(round.correct), style: qt.sectionTitle),
                  const SizedBox(height: 26),
                  FactsScoreDots(results: round.results, size: 14, gap: 9),
                  const SizedBox(height: 26),
                  Container(width: 28, height: 2, color: t.acc),
                  const SizedBox(height: 12),
                  Text(
                    [?streakLabel, ?bestLine].join(' · '),
                    style: qt.rowTitle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A new round of $kFactsPerDay arrives tomorrow.',
                    style: qt.meta,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 28),
                child: Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Browse facts',
                        onPressed: onBrowse,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Share my score',
                        icon: kShareIcon,
                        onPressed: onShare,
                      ),
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

/// The score as a share image, in the share card's look: the eyebrow,
/// the score large in the serif, the dots, the streak and the Quotely
/// mark. It never shows the facts or the answers.
class FactsScoreShareCard extends StatelessWidget {
  final List<bool> results;
  final int streak;
  final BackdropStyle backdrop;
  final ImageProvider? poster;
  final DateTime? day;

  const FactsScoreShareCard({
    super.key,
    required this.results,
    required this.streak,
    this.backdrop = BackdropStyle.poster,
    this.poster,
    this.day,
  });

  static const eyebrow = 'Quotely · True or false';

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    final correct = results.where((r) => r).length;
    final streakLabel = factsStreakLabel(streak);
    return SizedBox.fromSize(
      size: ShareCard.size,
      child: Material(
        type: MaterialType.transparency,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ShareCardBackground(backdrop: backdrop, poster: poster, day: day),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 34, 30, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: qt.overline.copyWith(color: t.ink, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      '$correct/$kFactsPerDay',
                      maxLines: 1,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontFamily: kFontSerif,
                        fontWeight: FontWeight.w400,
                        fontSize: 120,
                        height: 1,
                        letterSpacing: -2,
                        color: t.ink,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FactsScoreDots(results: results, size: 18, gap: 10),
                    const SizedBox(height: 26),
                    Container(width: 28, height: 2, color: t.acc),
                    const SizedBox(height: 12),
                    Text(
                      streakLabel ?? 'Played today',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: qt.rowTitle.copyWith(fontSize: 16),
                    ),
                    const Spacer(),
                    const ShareCardMark(),
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

/// The day's scene poster, the same one the page backdrop uses.
Future<String?> _dayPosterUrl(BuildContext context) async {
  try {
    final container = ProviderScope.containerOf(context, listen: false);
    final sotd = await container
        .read(sceneOfTheDayProvider.future)
        .timeout(const Duration(seconds: 2));
    final url = sotd?.sceneQuote.posterUrl;
    return url == null || url.isEmpty ? null : url;
  } catch (_) {
    return null;
  }
}

/// Renders [FactsScoreShareCard] offscreen: PNG bytes at 1080x1350.
Future<Uint8List?> renderFactsScoreCard(
  BuildContext context, {
  required List<bool> results,
  required int streak,
}) async {
  final bg = await loadShareBackground(
    context,
    posterUrl: () => _dayPosterUrl(context),
  );
  if (bg == null || !context.mounted) return null;
  return captureShareImage(
    context,
    FactsScoreShareCard(
      results: results,
      streak: streak,
      backdrop: bg.backdrop,
      poster: bg.poster,
    ),
  );
}

void _logShared(FactsRound round, int streak, String format) =>
    logAppEvent('facts_score_shared', {
      'score': round.correct,
      'total': kFactsPerDay,
      'streak': streak,
      'format': format,
    });

/// Share my score: the same small sheet as any share, image first.
Future<void> shareFactsScore(
  BuildContext context, {
  required FactsRound round,
  required int streak,
}) {
  HapticFeedback.selectionClick();
  final origin = shareOriginOf(context);
  final text = factsScoreShareText(
    correct: round.correct,
    streak: streak,
    platform: defaultTargetPlatform,
  );
  const subject = 'My True or False score on Quotely';
  return showQSheet(
    context,
    builder: (sheet) => QSheetFrame(
      title: 'Share my score',
      child: Column(
        children: [
          ShareImageAction(
            onShare: (onRendered) async {
              final bytes = await renderFactsScoreCard(
                context,
                results: round.results,
                streak: streak,
              );
              if (!onRendered()) return;
              if (bytes == null) {
                _logShared(round, streak, 'text');
                await SharePlus.instance.share(
                  ShareParams(
                    text: text,
                    subject: subject,
                    sharePositionOrigin: origin,
                  ),
                );
                return;
              }
              const name = 'quotely-true-or-false.png';
              _logShared(round, streak, 'image');
              await SharePlus.instance.share(
                ShareParams(
                  files: [
                    XFile.fromData(bytes, mimeType: 'image/png', name: name),
                  ],
                  fileNameOverrides: [name],
                  text: text,
                  subject: subject,
                  sharePositionOrigin: origin,
                ),
              );
            },
          ),
          SheetAction(
            icon: Icons.notes_rounded,
            label: 'Share as text',
            onTap: () {
              Navigator.of(sheet).pop();
              _logShared(round, streak, 'text');
              SharePlus.instance.share(
                ShareParams(
                  text: text,
                  subject: subject,
                  sharePositionOrigin: origin,
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
