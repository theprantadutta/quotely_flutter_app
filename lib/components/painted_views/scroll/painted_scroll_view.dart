import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../shared/painted_action_buttons.dart';
import '../shared/painted_content.dart';
import '../shared/painted_skeleton.dart';
import 'parchment_painter.dart';
import 'scroll_roll_painter.dart';
import 'wax_seal.dart';

/// 📜 Scroll mode: a continuous parchment that unrolls vertically. Pinned
/// painted rolls cap the top and bottom; each item sits on torn-edge aged
/// paper with a wax-seal favorite. The only mode with pull-to-refresh.
class PaintedScrollView extends ConsumerStatefulWidget {
  final List<PaintedContent> items;
  final PaintedContentActions actions;
  final bool isLoadingMore;
  final bool hasMoreData;

  const PaintedScrollView({
    super.key,
    required this.items,
    required this.actions,
    required this.isLoadingMore,
    required this.hasMoreData,
  });

  @override
  ConsumerState<PaintedScrollView> createState() => _PaintedScrollViewState();
}

class _PaintedScrollViewState extends ConsumerState<PaintedScrollView> {
  final _scrollController = ScrollController();
  double _scrollShift = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Drive the roll-rotation illusion (cheap setState — painter only).
    setState(() => _scrollShift = _scrollController.offset / 40);

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      widget.actions.onLastItemReached();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final tint = theme.primaryColor;

    if (widget.items.isEmpty && widget.isLoadingMore) {
      return PaintedSkeletonPane(mode: PaintedSkeletonMode.scroll);
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _RollHeaderDelegate(
            brightness: brightness,
            tint: tint,
            scrollShift: _scrollShift,
            flipped: false,
          ),
        ),
        SliverList.builder(
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final content = widget.items[index];
            return RepaintBoundary(
              child: _ParchmentItem(
                content: content,
                actions: widget.actions,
                brightness: brightness,
                tint: tint,
                isLast: index == widget.items.length - 1,
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 56,
            child: CustomPaint(
              painter: ScrollRollPainter(
                brightness: brightness,
                tint: tint,
                scrollShift: _scrollShift,
                flipped: true,
              ),
              size: const Size(double.infinity, 56),
            ),
          ),
        ),
        if (widget.isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: LoadingAnimationWidget.hexagonDots(
                  color: theme.primaryColor,
                  size: 28,
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
      ],
    );
  }
}

class _RollHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Brightness brightness;
  final Color tint;
  final double scrollShift;
  final bool flipped;

  _RollHeaderDelegate({
    required this.brightness,
    required this.tint,
    required this.scrollShift,
    required this.flipped,
  });

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return CustomPaint(
      painter: ScrollRollPainter(
        brightness: brightness,
        tint: tint,
        scrollShift: scrollShift,
        flipped: flipped,
      ),
      size: const Size(double.infinity, 56),
    );
  }

  @override
  bool shouldRebuild(_RollHeaderDelegate oldDelegate) =>
      oldDelegate.scrollShift != scrollShift ||
      oldDelegate.brightness != brightness ||
      oldDelegate.tint != tint;
}

class _ParchmentItem extends ConsumerWidget {
  final PaintedContent content;
  final PaintedContentActions actions;
  final Brightness brightness;
  final Color tint;
  final bool isLast;

  const _ParchmentItem({
    required this.content,
    required this.actions,
    required this.brightness,
    required this.tint,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = brightness == Brightness.dark;
    final ink = isDark
        ? const Color(0xFFE8DEC8)
        : const Color(0xFF3A2E1E);
    final accent = isDark ? theme.colorScheme.secondary : theme.primaryColor;

    return CustomPaint(
      painter: ParchmentPainter(
        brightness: brightness,
        tint: tint,
        seed: content.id.hashCode,
        drawDivider: !isLast,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.subtitle != null) ...[
              Text(
                content.subtitle!.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              content.body,
              style: TextStyle(
                fontSize: 16,
                height: 1.55,
                fontStyle: content.type == PaintedContentType.quote
                    ? FontStyle.italic
                    : FontStyle.normal,
                color: ink,
              ),
            ),
            const SizedBox(height: 10),
            if (content.title != null)
              GestureDetector(
                onTap: actions.onTitleTap == null
                    ? null
                    : () => actions.onTitleTap!(context, content),
                child: Text(
                  '— ${content.title}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                PaintedReportShareButtons(
                  content: content,
                  actions: actions,
                  color: ink.withValues(alpha: 0.6),
                  size: 18,
                ),
                const Spacer(),
                WaxSeal(content: content, actions: actions),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
