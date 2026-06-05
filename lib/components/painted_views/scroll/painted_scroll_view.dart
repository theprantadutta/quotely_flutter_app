import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../shared/painted_action_buttons.dart';
import '../shared/painted_card_style.dart';
import '../shared/painted_content.dart';
import '../shared/painted_skeleton.dart';
import 'scroll_section_painter.dart';

/// 📜 Scroll mode: a continuous vertical feed painted as one flowing sheet —
/// theme-colored gradient cards connected by an accent timeline that draws
/// itself as you scroll. The only mode with pull-to-refresh.
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      widget.actions.onLastItemReached();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.items.isEmpty && widget.isLoadingMore) {
      return const PaintedSkeletonPane(mode: PaintedSkeletonMode.scroll);
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 16),
      itemCount: widget.items.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: LoadingAnimationWidget.hexagonDots(
                color: theme.primaryColor,
                size: 28,
              ),
            ),
          );
        }
        final content = widget.items[index];
        return RepaintBoundary(
          child: _ScrollFeedItem(
            content: content,
            actions: widget.actions,
            isFirst: index == 0,
            isLast: index == widget.items.length - 1 && !widget.hasMoreData,
          ),
        );
      },
    );
  }
}

class _ScrollFeedItem extends ConsumerWidget {
  final PaintedContent content;
  final PaintedContentActions actions;
  final bool isFirst;
  final bool isLast;

  const _ScrollFeedItem({
    required this.content,
    required this.actions,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardStyle = PaintedCardStyle.of(context);
    final ink = cardStyle.ink;
    final accent = cardStyle.accent;
    final isFavorite = actions.isFavorite(ref, content);

    return CustomPaint(
      painter: ScrollSectionPainter(
        style: cardStyle,
        isFirst: isFirst,
        isLast: isLast,
        isFavorite: isFavorite,
      ),
      child: Padding(
        // Left inset clears the painted timeline rail
        padding: const EdgeInsets.fromLTRB(46, 14, 22, 12),
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
                height: 1.5,
                fontStyle: content.type == PaintedContentType.quote
                    ? FontStyle.italic
                    : FontStyle.normal,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
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
            Row(
              children: [
                PaintedReportShareButtons(
                  content: content,
                  actions: actions,
                  color: cardStyle.faintInk,
                  size: 18,
                ),
                const Spacer(),
                PaintedHeartFavorite(
                  content: content,
                  actions: actions,
                  activeColor: Colors.redAccent,
                  inactiveColor: cardStyle.faintInk,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
