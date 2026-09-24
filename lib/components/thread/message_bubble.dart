import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dtos/scene_quote_dto.dart';
import '../../services/activity_service.dart';
import '../../state_providers/scene_state.dart';
import '../../theme/app_theme.dart';
import 'message_actions.dart';
import 'q_controls.dart';
import 'q_image.dart';
import 'thread_message.dart';

enum BubbleVariant {
  /// First item / quote of the day: `quoteHero` text, roomy padding.
  hero,

  /// Standard thread bubble.
  regular,

  /// Saved lists, archives, author detail.
  compact,
}

/// 22/22/22/6 corners: the 6px "tail" sits bottom-left, next to the avatar.
BorderRadius bubbleRadius(double r, {double tail = 6}) => BorderRadius.only(
  topLeft: Radius.circular(r),
  topRight: Radius.circular(r),
  bottomRight: Radius.circular(r),
  bottomLeft: Radius.circular(tail),
);

/// Formats 1234 as "1.2k" for reaction pills.
String compactCount(int n) {
  if (n < 1000) return '$n';
  final k = n / 1000;
  return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
}

/// A quote, scene or fact as a chat message: avatar + sender + bubble +
/// optional reactions. Long-press opens the action sheet.
class MessageBubble extends ConsumerWidget {
  final ThreadMessage message;
  final BubbleVariant variant;

  /// Hide the avatar column (compact lists, title detail).
  final bool showAvatar;

  /// Hide the title chip (title detail, where it would be redundant).
  final bool showTitleChip;

  /// Override the sender line ("Luffy · Ep. 4", "Spoiler · Ep. 1071").
  final String? senderLabel;

  final bool showReactions;

  /// Author/character name shown above the bubble.
  final bool showSender;

  final double avatarSize;

  /// Count this toward the streak card (off for demo/onboarding bubbles).
  final bool trackView;

  const MessageBubble({
    super.key,
    required this.message,
    this.variant = BubbleVariant.regular,
    this.showAvatar = true,
    this.showTitleChip = true,
    this.senderLabel,
    this.showReactions = false,
    this.showSender = true,
    this.avatarSize = 34,
    this.trackView = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.q;
    final qt = context.qt;
    final m = message;
    // Streak card counts; de-duplicated per session, so rebuilds are free.
    if (trackView) ActivityService.instance.markViewed(m.kind.name, m.itemId);
    final style = switch (variant) {
      BubbleVariant.hero => qt.quoteHero,
      BubbleVariant.regular => qt.quoteBody,
      BubbleVariant.compact => qt.quoteCompact,
    };
    final radius = variant == BubbleVariant.compact ? 20.0 : 22.0;
    final padding = switch (variant) {
      BubbleVariant.hero => const EdgeInsets.fromLTRB(17, 16, 17, 16),
      BubbleVariant.regular => const EdgeInsets.fromLTRB(16, 14, 16, 14),
      BubbleVariant.compact => const EdgeInsets.fromLTRB(15, 13, 15, 13),
    };

    final scene = m.scene;
    final spoilerHidden = scene != null && isSpoilerHidden(ref, scene);

    Widget bubbleBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          m.text,
          style: style,
          textWidthBasis: TextWidthBasis.longestLine,
          textScaler: MediaQuery.textScalerOf(context),
        ),
        if (scene != null && showTitleChip) ...[
          const SizedBox(height: 12),
          TitleChip(scene: scene),
        ],
      ],
    );

    Widget bubble = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.surf,
        borderRadius: bubbleRadius(radius),
      ),
      child: bubbleBody,
    );

    if (scene != null && scene.isSpoiler) {
      bubble = SpoilerBubble(
        hidden: spoilerHidden,
        onReveal: () =>
            ref.read(revealedSpoilersProvider.notifier).reveal(scene.id),
        radius: bubbleRadius(radius),
        child: bubble,
      );
    }

    final semanticsLabel = spoilerHidden
        ? 'Spoiler hidden, double-tap to reveal'
        : '${m.sender}: ${m.text}';

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSender)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              senderLabel ?? m.sender,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: qt.label,
            ),
          ),
        Semantics(
          label: semanticsLabel,
          excludeSemantics: true,
          onLongPressHint: 'More actions',
          child: Pressable(
            pressedScale: 0.985,
            onLongPress: () => showMessageActions(context, ref, m),
            child: bubble,
          ),
        ),
        if (showReactions) ...[
          const SizedBox(height: 6),
          ReactionRow(message: m),
        ],
      ],
    );

    // Short lines make short bubbles (longestLine + min main axis); long
    // ones take the width left beside the avatar column.
    if (!showAvatar) {
      return Align(alignment: Alignment.centerLeft, child: column);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: m.kind == MessageKind.fact
              ? null
              : () => openSender(context, m),
          child: m.kind == MessageKind.fact
              ? BrandAvatar(size: avatarSize)
              : QAvatar(
                  name: m.sender,
                  imageUrl: watchSenderImage(ref, m),
                  size: avatarSize,
                ),
        ),
        const SizedBox(width: 10),
        Flexible(child: column),
      ],
    );
  }
}

/// Whether [scene] should render blurred right now.
bool isSpoilerHidden(WidgetRef ref, SceneQuoteDto scene) {
  if (!scene.isSpoiler) return false;
  if (!ref.watch(spoilerShieldProvider)) return false;
  if (ref.watch(revealedSpoilersProvider).contains(scene.id)) return false;
  final watched = ref.watch(watchedUpToProvider)[scene.titleId];
  final after = scene.spoilerAfterEpisode ?? scene.episode;
  if (watched != null && after != null && after <= watched) return false;
  return true;
}

/// Like · Share · ⋯ under a bubble.
class ReactionRow extends ConsumerWidget {
  final ThreadMessage message;

  const ReactionRow({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = watchIsSaved(ref, message);
    final base = message.scene?.likes ?? 0;
    final count = base + (saved ? 1 : 0);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ReactionPill.like(
          liked: saved,
          count: count,
          onTap: () => toggleSaved(ref, message),
        ),
        ReactionPill(
          icon: kShareIcon,
          label: 'Share',
          onTap: () => shareMessage(message),
        ),
        ReactionPill(
          icon: Icons.more_horiz_rounded,
          semanticLabel: 'More',
          onTap: () => showMessageActions(context, ref, message),
        ),
      ],
    );
  }
}

/// 12/700 pill. Liked = `accSoft`/`accInk` with a filled heart that pops.
class ReactionPill extends StatefulWidget {
  final IconData? icon;
  final String? label;
  final String? semanticLabel;
  final VoidCallback onTap;
  final bool active;
  final bool isLike;

  const ReactionPill({
    super.key,
    this.icon,
    this.label,
    this.semanticLabel,
    required this.onTap,
    this.active = false,
  }) : isLike = false;

  ReactionPill.like({
    super.key,
    required bool liked,
    required int count,
    required this.onTap,
  }) : icon = liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
       label = count > 0 ? compactCount(count) : null,
       semanticLabel = liked
           ? 'Saved${count > 0 ? ', $count' : ''}. Double-tap to remove'
           : 'Save',
       active = liked,
       isLike = true;

  @override
  State<ReactionPill> createState() => _ReactionPillState();
}

class _ReactionPillState extends State<ReactionPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final Animation<double> _scale = TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
  ]).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut));

  @override
  void didUpdateWidget(ReactionPill old) {
    super.didUpdateWidget(old);
    if (widget.isLike &&
        widget.active &&
        !old.active &&
        !context.reduceMotion) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final fg = widget.active ? t.accInk : t.ink;
    return HitTarget(
      onTap: widget.onTap,
      semanticLabel: widget.semanticLabel ?? widget.label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.active ? t.accSoft : t.surf,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null)
              ScaleTransition(
                scale: _scale,
                child: Icon(widget.icon, size: 16, color: fg),
              ),
            if (widget.icon != null && widget.label != null)
              const SizedBox(width: 5),
            if (widget.label != null)
              Text(widget.label!, style: context.qt.label.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

/// Poster + title + "Movie · 1994" attached inside a scene bubble. Taps
/// through to the title page.
class TitleChip extends StatelessWidget {
  final SceneQuoteDto scene;

  const TitleChip({super.key, required this.scene});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      button: true,
      label: '${scene.titleName}, ${scene.chipMeta}',
      excludeSemantics: true,
      child: Pressable(
        onTap: () => openSender(context, ThreadMessage.fromScene(scene)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 7, 12, 7),
          decoration: BoxDecoration(
            color: t.bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              QPoster(url: scene.posterUrl, width: 26, height: 38, radius: 5),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      scene.titleName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.qt.chip.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(scene.chipMeta, style: context.qt.caption),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 18, color: t.mute),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blurs [child] behind a "Tap to reveal spoiler" pill. The blur animates
/// away on reveal; only the bubble is blurred, never the list.
class SpoilerBubble extends StatelessWidget {
  final bool hidden;
  final VoidCallback onReveal;
  final BorderRadius radius;
  final Widget child;

  const SpoilerBubble({
    super.key,
    required this.hidden,
    required this.onReveal,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: hidden ? 6 : 0),
      duration: context.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 250),
      builder: (context, sigma, _) {
        final blurred = sigma > 0.05
            ? ClipRRect(
                borderRadius: radius,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: child,
                ),
              )
            : child;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Blocks the title chip and long-press while hidden.
            // Wide enough for the pill even when the line is very short.
            IgnorePointer(
              ignoring: hidden,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: hidden ? 230 : 0),
                child: blurred,
              ),
            ),
            if (hidden)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onReveal();
                  },
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: t.ink,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Tap to reveal spoiler',
                        maxLines: 1,
                        softWrap: false,
                        style: context.qt.label.copyWith(
                          color: t.bg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Three pulsing 6px dots in a small bubble: "someone is typing".
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      label: 'Looking for a quote',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const BrandAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: t.surf,
              borderRadius: bubbleRadius(20),
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Opacity(
                      opacity: context.reduceMotion
                          ? 0.6
                          : 0.3 + 0.7 * _pulse((_c.value - i * 0.18) % 1),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: t.mute,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _pulse(double x) => x < 0.5 ? x * 2 : (1 - x) * 2;
}
