import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/activity_service.dart';
import '../../state_providers/scene_state.dart';
import '../../theme/app_theme.dart';
import 'message_actions.dart';
import 'message_bubble.dart';
import 'q_controls.dart';
import 'q_image.dart';
import 'thread_message.dart';

/// Picks a spotlight size so a line of any length fits one screen: short
/// lines go big, long ones step down. Keeps the reading font and scale.
TextStyle spotlightStyle(BuildContext context, String text) {
  final base = context.qt.quoteSpotlight;
  final n = text.length;
  final factor = n <= 70
      ? 1.0
      : n <= 130
      ? 0.8
      : n <= 220
      ? 0.66
      : n <= 340
      ? 0.56
      : 0.48;
  return base.copyWith(
    fontSize: base.fontSize! * factor,
    height: factor >= 0.8 ? 1.04 : 1.14,
  );
}

/// One screen of the Spotlight feed: an overline, the line set large in
/// the reading font, then who said it. Leaves room on the right for the
/// [SpotlightRail]. Long-press opens the action sheet.
class SpotlightEntry extends ConsumerWidget {
  final ThreadMessage message;

  /// Small mono label above the line ("QUOTE OF THE DAY").
  final String? eyebrow;

  /// Extra line under the sender ("Movie · 1994").
  final String? detail;

  const SpotlightEntry({
    super.key,
    required this.message,
    this.eyebrow,
    this.detail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final qt = context.qt;
    final m = message;
    ActivityService.instance.markViewed(m.kind.name, m.itemId);
    final scene = m.scene;

    Widget line = Text(
      m.text,
      style: spotlightStyle(context, m.text),
      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
    );
    if (scene != null && scene.isSpoiler) {
      line = SpoilerBubble(
        hidden: isSpoilerHidden(ref, scene),
        onReveal: () =>
            ref.read(revealedSpoilersProvider.notifier).reveal(scene.id),
        radius: BorderRadius.circular(12),
        child: line,
      );
    }

    final tappableSender = m.kind != MessageKind.fact;
    final attribution = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tappableSender ? () => openSender(context, m) : null,
      child: Row(
        children: [
          if (m.kind == MessageKind.fact)
            const BrandAvatar(size: 34)
          else
            QAvatar(
              name: m.sender,
              imageUrl: watchSenderImage(ref, m),
              size: 34,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m.kind == MessageKind.fact ? 'Quotely' : m.sender,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: qt.rowTitle,
                ),
                if (_detail(m) case final d?) ...[
                  const SizedBox(height: 2),
                  Text(
                    d,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: qt.meta,
                  ),
                ],
              ],
            ),
          ),
          if (tappableSender)
            Icon(Icons.arrow_forward_rounded, size: 16, color: t.mute),
        ],
      ),
    );

    return Semantics(
      label: '${m.sender}: ${m.text}',
      onLongPressHint: 'More actions',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          showMessageActions(context, ref, m);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 76, 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: qt.overline.copyWith(color: t.ink),
                ),
                const SizedBox(height: 22),
              ],
              Flexible(child: SingleChildScrollView(child: line)),
              const SizedBox(height: 28),
              attribution,
            ],
          ),
        ),
      ),
    );
  }

  String? _detail(ThreadMessage m) {
    if (detail != null) return detail;
    return switch (m.kind) {
      MessageKind.quote =>
        m.quote!.tags.isEmpty ? null : _cap(m.quote!.tags.first),
      MessageKind.scene => '${m.scene!.titleName} · ${m.scene!.chipMeta}',
      MessageKind.fact => m.fact!.aiFactCategory,
    };
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// The vertical action column at the right edge of the Spotlight feed:
/// Save, Share, More, and optionally Ask.
class SpotlightRail extends ConsumerWidget {
  final ThreadMessage? message;
  final VoidCallback? onAsk;

  const SpotlightRail({super.key, required this.message, this.onAsk});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final m = message;
    final saved = m != null && watchIsSaved(ref, m);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (m != null) ...[
          _RailButton(
            icon: saved
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: saved ? 'Saved' : 'Save',
            color: saved ? t.acc : t.ink,
            onTap: () {
              HapticFeedback.lightImpact();
              toggleSaved(ref, m);
            },
          ),
          _RailButton(
            icon: kShareIcon,
            label: 'Share',
            onTap: () => shareMessage(m),
          ),
          _RailButton(
            icon: Icons.more_horiz_rounded,
            label: 'More',
            onTap: () => showMessageActions(context, ref, m),
          ),
        ],
        if (onAsk != null)
          _RailButton(
            icon: Icons.auto_awesome_outlined,
            label: 'Ask',
            onTap: onAsk!,
          ),
      ],
    );
  }
}

class _RailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _RailButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.9,
        child: SizedBox(
          width: 56,
          height: 60,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color ?? t.ink),
              const SizedBox(height: 4),
              Text(
                label,
                style: context.qt.caption.copyWith(
                  fontSize: 10.5,
                  color: t.ink.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Background behind the feed: nothing extra (the [PageBackdrop] shows
/// through), or a poster washed into
/// the page colour so type stays readable on top.
class SpotlightBackdrop extends StatelessWidget {
  final Color tint;
  final String? imageUrl;

  const SpotlightBackdrop({super.key, required this.tint, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final url = imageUrl;
    // The switcher's default Stack hands children loose constraints; the
    // layout builder makes both backdrops fill the screen.
    return AnimatedSwitcher(
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      duration: context.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 450),
      child: url == null || url.isEmpty
          ? const SizedBox.shrink(key: ValueKey('none'))
          : Stack(
              key: ValueKey(url),
              fit: StackFit.expand,
              children: [
                ColoredBox(color: t.bg),
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    httpHeaders: kImageHeaders,
                    memCacheWidth: 200,
                    fadeInDuration: const Duration(milliseconds: 300),
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                // Wash toward the page colour: poster colour, paper legibility.
                ColoredBox(
                  color: t.bg.withValues(alpha: t.isDark ? 0.72 : 0.7),
                ),
              ],
            ),
    );
  }
}

/// The app's background: the page colour with the day's hue as soft glows,
/// strongest top-right and a fainter echo bottom-left. Appearance →
/// Background glow off leaves the plain page colour. Every screen sits on
/// this (the tab shell, [ThreadPage] and the full-screen flows), so it is
/// opaque and paints [child] on top.
class PageBackdrop extends ConsumerWidget {
  final Widget? child;

  const PageBackdrop({super.key, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final on = ref.watch(appearanceProvider.select((a) => a.backgroundGlow));
    final hue = t.glowFor(DateTime.now());
    // Dark pages need less opacity for the same visible lift.
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
    final content = child ?? const SizedBox.expand();
    return DecoratedBox(
      decoration: BoxDecoration(color: t.bg),
      child: !on
          ? content
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: glow(const Alignment(1.0, -1.0), 1.6, 1.0),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: glow(const Alignment(-1.1, 1.0), 1.4, 0.7),
                ),
                child: content,
              ),
            ),
    );
  }
}

/// Small "3 / 7" position marker for the top of the feed.
class SpotlightCounter extends StatelessWidget {
  final int index;
  final int total;

  const SpotlightCounter({super.key, required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    return Text(
      '${index + 1} / $total',
      style: context.qt.overline.copyWith(color: context.q.ink),
    );
  }
}
