import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/shared_preference_keys.dart';
import 'carousel_skeleton.dart';
import 'content_card.dart';
import 'content_item.dart';

/// The one view mode for quotes & facts: a vertical card carousel. Each item
/// is a full card; the previous/next cards peek at the edges and cards
/// scale/fade slightly while swiping, snapping one card per swipe.
///
/// "More content" affordances: edge peeks, soft gradient fades at the
/// viewport edges, pulsing chevrons when there are cards above/below, and a
/// one-time "swipe up" coach overlay on first launch.
class VerticalContentCarousel extends StatefulWidget {
  final List<ContentItem> items;
  final ContentActions actions;
  final bool isLoadingMore;
  final bool hasMoreData;

  const VerticalContentCarousel({
    super.key,
    required this.items,
    required this.actions,
    required this.isLoadingMore,
    required this.hasMoreData,
  });

  @override
  State<VerticalContentCarousel> createState() =>
      _VerticalContentCarouselState();
}

class _VerticalContentCarouselState extends State<VerticalContentCarousel>
    with SingleTickerProviderStateMixin {
  // <1 so the neighbouring cards peek above/below the active one.
  final PageController _controller = PageController(viewportFraction: 0.82);

  int _index = 0;

  /// Drives the chevron/coach bobbing.
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  bool _coachVisible = false;
  Timer? _coachTimer;

  @override
  void initState() {
    super.initState();
    _maybeShowCoach();
  }

  Future<void> _maybeShowCoach() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(kCarouselCoachShownKey) ?? false) return;
    if (!mounted) return;
    setState(() => _coachVisible = true);
    // Auto-dismiss if the user never swipes.
    _coachTimer = Timer(const Duration(seconds: 7), _dismissCoach);
  }

  Future<void> _dismissCoach() async {
    _coachTimer?.cancel();
    if (!mounted || !_coachVisible) return;
    setState(() => _coachVisible = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kCarouselCoachShownKey, true);
  }

  @override
  void didUpdateWidget(covariant VerticalContentCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh / filter change rebuilds the list from scratch — snap back up.
    if (widget.items.length < oldWidget.items.length &&
        _controller.hasClients) {
      _index = 0;
      _controller.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _coachTimer?.cancel();
    _bob.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _index = index);
    if (_coachVisible) _dismissCoach();
    if (index >= widget.items.length - 3) {
      widget.actions.onLastItemReached();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.isLoadingMore) {
      return const FractionallySizedBox(
        heightFactor: 0.82,
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CarouselSkeletonCard(),
        ),
      );
    }
    if (widget.items.isEmpty) return const SizedBox.shrink();

    // One trailing skeleton page while the next batch loads.
    final showTrailingSkeleton = widget.isLoadingMore && widget.hasMoreData;
    final itemCount = widget.items.length + (showTrailingSkeleton ? 1 : 0);

    final hasAbove = _index > 0;
    final hasBelow = _index < itemCount - 1 || widget.hasMoreData;

    return Stack(
      children: [
        PageView.builder(
          key: const PageStorageKey('vertical_content_carousel'),
          controller: _controller,
          scrollDirection: Axis.vertical,
          onPageChanged: _onPageChanged,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final child = index >= widget.items.length
                ? const CarouselSkeletonCard()
                : ContentCard(
                    item: widget.items[index],
                    actions: widget.actions,
                  );

            // Subtle scale on the cards entering/leaving the viewport.
            // Deliberately no opacity fade — translucent neighbours read
            // as a weird glass panel behind the active card.
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double delta = 0;
                if (_controller.position.haveDimensions) {
                  delta = ((_controller.page ?? 0) - index).clamp(-1.0, 1.0);
                }
                return Transform.scale(
                  scale: 1 - 0.05 * delta.abs(),
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: child,
              ),
            );
          },
        ),
        // Pulsing chevrons whenever there's content above/below.
        _EdgeChevron(visible: hasAbove, top: true, bob: _bob),
        _EdgeChevron(visible: hasBelow, top: false, bob: _bob),
        // One-time swipe coach.
        if (_coachVisible)
          Positioned(
            left: 0,
            right: 0,
            bottom: 64,
            child: Center(child: _SwipeCoach(bob: _bob)),
          ),
      ],
    );
  }
}

/// A gently bobbing chevron hinting at more content above/below.
class _EdgeChevron extends StatelessWidget {
  final bool visible;
  final bool top;
  final Animation<double> bob;

  const _EdgeChevron({
    required this.visible,
    required this.top,
    required this.bob,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withValues(
      alpha: 0.40,
    );
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: visible ? 1 : 0,
          child: AnimatedBuilder(
            animation: bob,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, (top ? -2.5 : 2.5) * bob.value),
              child: child,
            ),
            child: Icon(
              top
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 24,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// First-launch "Swipe up for more" pill, dismissed by the first swipe (or
/// a timer) and never shown again.
class _SwipeCoach extends StatelessWidget {
  final Animation<double> bob;

  const _SwipeCoach({required this.bob});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: bob,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -5 * bob.value),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.inverseSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swipe_up_rounded,
              size: 18,
              color: theme.colorScheme.onInverseSurface,
            ),
            const SizedBox(width: 8),
            Text(
              'Swipe up for more',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onInverseSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
