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
/// viewport edges when there are cards above/below, and a one-time "swipe up"
/// coach overlay on first launch.
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

  /// Drives the swipe-coach bobbing. Created lazily only when the coach is
  /// actually shown — never touch it in dispose() unless it exists, or building
  /// its ticker on a deactivated element throws.
  AnimationController? _bob;

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
    // Create the bobbing controller now (while the element is active), only
    // because we're actually about to show the coach.
    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
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
    _bob?.dispose();
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Cover the peeking neighbour card (~9% of the viewport each side,
        // from viewportFraction 0.82) plus a little, so its border melts away.
        final fadeHeight = constraints.maxHeight * 0.13;
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
                      delta = ((_controller.page ?? 0) - index).clamp(
                        -1.0,
                        1.0,
                      );
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
            // Soft fades at the top/bottom edges: the peeking neighbour cards
            // melt into the tinted background, hinting at more content
            // without arrows or a visible band.
            _EdgeFade(visible: hasAbove, top: true, height: fadeHeight),
            _EdgeFade(visible: hasBelow, top: false, height: fadeHeight),
            // One-time swipe coach.
            if (_coachVisible && _bob != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 64,
                child: Center(child: _SwipeCoach(bob: _bob!)),
              ),
          ],
        );
      },
    );
  }
}

/// A soft gradient fade at the top/bottom edge. By letting the peeking
/// neighbour card dissolve into the background it signals "more content"
/// above/below without a literal arrow.
class _EdgeFade extends StatelessWidget {
  final bool visible;
  final bool top;
  final double height;

  const _EdgeFade({
    required this.visible,
    required this.top,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Match the screen's real background: scaffold colour + the faint primary
    // tint the nav layout paints on top. Fading to the flat scaffold colour
    // alone leaves a visible mismatched band.
    final bg = Color.alphaBlend(
      theme.primaryColor.withValues(alpha: 0.09),
      theme.scaffoldBackgroundColor,
    );
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 0,
      right: 0,
      height: height,
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: visible ? 1 : 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                end: top ? Alignment.bottomCenter : Alignment.topCenter,
                colors: [bg, bg.withValues(alpha: 0.0)],
              ),
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
      builder: (context, child) =>
          Transform.translate(offset: Offset(0, -5 * bob.value), child: child),
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
