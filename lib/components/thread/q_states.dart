import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'q_controls.dart';
import 'q_pills.dart';
import 'skeletons.dart';

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

/// Loading placeholder for one entry: text lines, then who said it,
/// shimmering. (Kept under this name for existing callers.)
class BubbleSkeleton extends StatelessWidget {
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
  Widget build(BuildContext context) => Shimmer(
    child: EntrySkeleton(lines: lines, width: width, byline: avatar),
  );
}

/// A column of entry skeletons for first loads.
class ThreadSkeleton extends StatelessWidget {
  final int count;

  const ThreadSkeleton({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) => EntryListSkeleton(count: count);
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
            child: Text('QUOTELY', style: context.qt.overline),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              message,
              style: context.qt.quoteCompact.copyWith(
                color: t.ink.withValues(alpha: 0.86),
              ),
            ),
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

/// "Loading the next page": one more entry, shimmering, where it will land.
class LoadMoreIndicator extends StatelessWidget {
  /// A people row instead of an entry (People lists).
  final bool person;

  const LoadMoreIndicator({super.key, this.person = false});

  @override
  Widget build(BuildContext context) => Padding(
    padding: person
        ? const EdgeInsets.symmetric(horizontal: 16)
        : const EdgeInsets.fromLTRB(22, 20, 22, 28),
    child: Shimmer(
      child: person
          ? const PersonRowSkeleton()
          : const EntrySkeleton(lines: 2, width: 0.82),
    ),
  );
}
