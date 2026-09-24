import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'message_bubble.dart';
import 'q_controls.dart';
import 'q_pills.dart';

/// Fade + 12px slide-up on first build, staggered by [index] × 40ms.
/// Respects reduce-motion.
class Entrance extends StatefulWidget {
  final Widget child;
  final int index;

  /// Delay per [index] step. 40ms for lists; onboarding builds up slower.
  final Duration stagger;

  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.stagger = const Duration(milliseconds: 40),
  });

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    final delay = widget.stagger * widget.index.clamp(0, 8);
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Bubble-shaped placeholder with a soft shimmer in `ph`.
class BubbleSkeleton extends StatefulWidget {
  final double width;
  final int lines;
  final bool avatar;

  const BubbleSkeleton({
    super.key,
    this.width = 0.8,
    this.lines = 2,
    this.avatar = true,
  });

  @override
  State<BubbleSkeleton> createState() => _BubbleSkeletonState();
}

class _BubbleSkeletonState extends State<BubbleSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: t.ph,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Opacity(
          opacity: context.reduceMotion ? 0.8 : 0.55 + 0.45 * _c.value,
          child: child,
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final bubbleW =
                (c.maxWidth - (widget.avatar ? 44 : 0)) * widget.width;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.avatar) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: t.ph,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: bar(90, 10),
                    ),
                    Container(
                      width: bubbleW,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: t.surf,
                        borderRadius: bubbleRadius(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < widget.lines; i++) ...[
                            if (i > 0) const SizedBox(height: 8),
                            bar(
                              i == widget.lines - 1
                                  ? bubbleW * 0.45
                                  : bubbleW - 32,
                              14,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A column of bubble skeletons for first loads.
class ThreadSkeleton extends StatelessWidget {
  final int count;

  const ThreadSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          BubbleSkeleton(width: i.isEven ? 0.92 : 0.7, lines: i.isEven ? 3 : 2),
        ],
      ],
    );
  }
}

/// Empty state: one system pill and a line of `mute` text. No illustration.
class EmptyState extends StatelessWidget {
  final String pill;
  final String? message;
  final Widget? action;

  const EmptyState({super.key, required this.pill, this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SystemPill(pill),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(message!, textAlign: TextAlign.center, style: context.qt.body),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Error as a message from Quotely plus a Retry button.
class ErrorBubble extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBubble({
    super.key,
    this.message = 'Something went wrong. Check your connection and try again.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('Quotely', style: context.qt.label),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: t.surf,
              borderRadius: bubbleRadius(22),
            ),
            child: Text(message, style: context.qt.quoteCompact),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// Small centered spinner for "loading the next page".
class LoadMoreIndicator extends StatelessWidget {
  const LoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}
