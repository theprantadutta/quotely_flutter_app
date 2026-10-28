import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../riverpods/scene_providers.dart';
import '../../theme/app_theme.dart';
import 'q_image.dart';
import 'thread_message.dart';

const kBrandLogoAsset = 'assets/brand/app/logo-512.png';

/// The overline on a share card. Scenes always name their title; quotes and
/// facts take the screen's own label ("Quote of the day") when there is one.
String shareEyebrowFor(ThreadMessage m, {String? hint}) {
  if (m.kind == MessageKind.scene) return 'Scene · ${m.scene!.titleName}';
  if (hint != null && hint.isNotEmpty) return hint;
  return switch (m.kind) {
    MessageKind.quote => m.date != null ? 'Quote of the day' : 'Quote',
    MessageKind.fact => 'Fact',
    MessageKind.scene => 'Scene',
  };
}

/// The poster a card is washed with: a scene's own title poster, else the
/// day's scene poster (the one [PageBackdrop] uses). Null means the glow.
Future<String?> sharePosterUrlFor(BuildContext context, ThreadMessage m) async {
  final own = m.scene?.posterUrl;
  if (own != null && own.isNotEmpty) return own;
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

/// Decoded small: the wash blurs it to colour anyway.
ImageProvider sharePosterProvider(String url) => ResizeImage(
  CachedNetworkImageProvider(url, headers: kImageHeaders),
  width: 320,
);

/// Renders [m] as a [ShareCard] offscreen and returns the PNG bytes at
/// 1080x1350, or null if anything fails. The card follows Appearance →
/// Background. With Poster, the poster is loaded before the capture; if it
/// doesn't arrive in time the card falls back to the glow.
Future<Uint8List?> renderShareCard(
  BuildContext context,
  ThreadMessage m, {
  String? eyebrow,
}) async {
  final theme = Theme.of(context);
  final overlay = Overlay.of(context, rootOverlay: true);

  final backdrop = ProviderScope.containerOf(
    context,
    listen: false,
  ).read(appearanceProvider).backdrop;

  ImageProvider? poster;
  final url = backdrop == BackdropStyle.poster
      ? await sharePosterUrlFor(context, m)
      : null;
  if (!context.mounted) return null;
  final pending = <Future<void>>[
    precacheImage(
      ResizeImage(const AssetImage(kBrandLogoAsset), width: 256),
      context,
    ),
  ];
  if (url != null) {
    final candidate = sharePosterProvider(url);
    var ok = true;
    pending.add(
      precacheImage(candidate, context, onError: (_, _) => ok = false)
          .timeout(const Duration(seconds: 4), onTimeout: () => ok = false)
          .then((_) {
            if (ok) poster = candidate;
          }),
    );
  }
  await Future.wait(pending);
  if (!context.mounted) return null;

  final key = GlobalKey();
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 0,
      top: 0,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Transform.translate(
            // Laid out and painted, but well outside the viewport.
            offset: const Offset(-10000, 0),
            child: Theme(
              data: theme,
              child: MediaQuery(
                // The card is an image: it keeps its own type sizes.
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.noScaling),
                child: RepaintBoundary(
                  key: key,
                  child: ShareCard(
                    message: m,
                    eyebrow: shareEyebrowFor(m, hint: eyebrow),
                    backdrop: backdrop,
                    poster: poster,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(
      pixelRatio: ShareCard.outputWidth / ShareCard.size.width,
    );
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } catch (_) {
    return null;
  } finally {
    entry.remove();
  }
}

/// The portrait card behind "Share as image", in the Spotlight look: the
/// background per Appearance → Background (the poster washed into the page
/// colour, the day's glow, or the plain page colour), a mono overline,
/// the line large in the serif, who said it, and the Quotely mark.
///
/// Laid out at [size] and captured at 3x, so 1080x1350 on every device.
class ShareCard extends StatelessWidget {
  static const size = Size(360, 450);
  static const outputWidth = 1080.0;

  final ThreadMessage message;
  final String eyebrow;

  /// Appearance → Background. Poster without a [poster] paints the glow.
  final BackdropStyle backdrop;

  /// Already-loaded poster to wash the card with.
  final ImageProvider? poster;

  /// Picks the glow hue; defaults to today.
  final DateTime? day;

  const ShareCard({
    super.key,
    required this.message,
    required this.eyebrow,
    this.backdrop = BackdropStyle.poster,
    this.poster,
    this.day,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final qt = context.qt;
    final m = message;
    final (name, detail) = switch (m.kind) {
      MessageKind.quote => (m.sender, null),
      MessageKind.scene => (
        m.sender,
        '${m.scene!.titleName} · ${m.scene!.chipMeta}',
      ),
      MessageKind.fact => (_cap(m.fact!.aiFactCategory), null),
    };

    // Material gives the text a default style: an overlay entry has none,
    // and bare Text there paints the debug underline.
    return SizedBox.fromSize(
      size: size,
      child: Material(
        type: MaterialType.transparency,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              switch (backdrop) {
                BackdropStyle.plain => ColoredBox(color: t.bg),
                BackdropStyle.poster when poster != null => _Wash(
                  poster: poster!,
                ),
                _ => _Glow(day: day ?? DateTime.now()),
              },
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
                    const SizedBox(height: 18),
                    Expanded(child: _FittedLine(text: m.text)),
                    const SizedBox(height: 20),
                    Container(width: 28, height: 2, color: t.acc),
                    const SizedBox(height: 12),
                    if (name.isNotEmpty)
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: qt.rowTitle.copyWith(fontSize: 16),
                      ),
                    if (detail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: qt.meta,
                      ),
                    ],
                    const SizedBox(height: 26),
                    _Footer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// The line in the display serif, as large as fits the space: short lines
/// go big, long ones step down, and only past the floor does it ellipsize.
class _FittedLine extends StatelessWidget {
  final String text;

  const _FittedLine({required this.text});

  static const _max = 48.0;
  static const _min = 15.0;

  TextStyle _style(Color color, double size) => TextStyle(
    fontFamily: kFontSerif,
    fontWeight: FontWeight.w400,
    fontSize: size,
    height: size >= 30 ? 1.04 : 1.14,
    letterSpacing: size * -0.012,
    color: color,
    leadingDistribution: TextLeadingDistribution.even,
  );

  @override
  Widget build(BuildContext context) {
    final ink = context.q.ink;
    final direction = Directionality.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        bool fits(double size) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: _style(ink, size)),
            textDirection: direction,
            textScaler: TextScaler.noScaling,
          )..layout(maxWidth: box.maxWidth);
          final ok = painter.height <= box.maxHeight;
          painter.dispose();
          return ok;
        }

        // Binary search on half-point steps.
        var lo = _min, hi = _max;
        if (fits(hi)) {
          lo = hi;
        } else {
          while (hi - lo > 0.5) {
            final mid = (lo + hi) / 2;
            if (fits(mid)) {
              lo = mid;
            } else {
              hi = mid;
            }
          }
        }
        final style = _style(ink, lo);
        int? maxLines;
        if (!fits(lo)) {
          final lineHeight = lo * style.height!;
          maxLines = (box.maxHeight / lineHeight).floor().clamp(1, 1000);
        }
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            text,
            style: style,
            maxLines: maxLines,
            overflow: maxLines == null ? null : TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
          ),
        );
      },
    );
  }
}

/// The Quotely mark and wordmark, with the tagline across from it.
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Row(
      children: [
        const BrandIcon(size: 24, radius: 6),
        const SizedBox(width: 9),
        Text(
          'Quotely',
          style: TextStyle(
            fontFamily: kFontSerif,
            fontSize: 22,
            height: 1,
            color: t.ink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Wisdom, one message at a time'.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: context.qt.overline.copyWith(fontSize: 8.5),
          ),
        ),
      ],
    );
  }
}

/// [PosterWash] with an already-loaded image, so the capture never sees a
/// blank frame.
class _Wash extends StatelessWidget {
  final ImageProvider poster;

  const _Wash({required this.poster});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: t.bg),
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Image(
            image: poster,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        ColoredBox(color: t.bg.withValues(alpha: t.isDark ? 0.72 : 0.7)),
      ],
    );
  }
}

/// The page colour with the day's glow, as [PageBackdrop] paints it.
class _Glow extends StatelessWidget {
  final DateTime day;

  const _Glow({required this.day});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final hue = t.glowFor(day);
    final k = t.isDark ? 0.34 : 0.5;
    RadialGradient glow(Alignment center, double radius, double strength) =>
        RadialGradient(
          center: center,
          radius: radius,
          colors: [
            hue.withValues(alpha: strength * k),
            hue.withValues(alpha: strength * k * 0.45),
            hue.withValues(alpha: 0),
          ],
          stops: const [0, 0.5, 1],
        );
    return DecoratedBox(
      decoration: BoxDecoration(color: t.bg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: glow(const Alignment(1.0, -1.0), 1.6, 1.0),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glow(const Alignment(-1.1, 1.0), 1.4, 0.7),
          ),
        ),
      ),
    );
  }
}
