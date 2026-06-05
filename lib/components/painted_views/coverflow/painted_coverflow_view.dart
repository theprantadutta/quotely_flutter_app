import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/painted_action_buttons.dart';
import '../shared/painted_content.dart';
import '../shared/painted_skeleton.dart';
import '../shared/painted_text_layout.dart';
import 'coverflow_card_painter.dart';

/// 🎠 Coverflow mode: a horizontal 3D carousel. The centered card faces the
/// user; neighbors rotate away in perspective with painted reflections
/// beneath. Tap a side card to bring it to the front.
class PaintedCoverflowView extends ConsumerStatefulWidget {
  final List<PaintedContent> items;
  final PaintedContentActions actions;
  final bool isLoadingMore;
  final bool hasMoreData;

  const PaintedCoverflowView({
    super.key,
    required this.items,
    required this.actions,
    required this.isLoadingMore,
    required this.hasMoreData,
  });

  @override
  ConsumerState<PaintedCoverflowView> createState() =>
      _PaintedCoverflowViewState();
}

class _PaintedCoverflowViewState extends ConsumerState<PaintedCoverflowView> {
  final _pageController = PageController(viewportFraction: 0.62);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.isLoadingMore) {
      return const PaintedSkeletonPane(mode: PaintedSkeletonMode.card);
    }

    // Trailing skeleton card while the next page loads
    final showTrailingSkeleton = widget.hasMoreData && widget.isLoadingMore;
    final itemCount = widget.items.length + (showTrailingSkeleton ? 1 : 0);

    return PageView.builder(
      controller: _pageController,
      itemCount: itemCount,
      onPageChanged: (index) {
        HapticFeedback.selectionClick();
        if (index >= widget.items.length - 3) {
          widget.actions.onLastItemReached();
        }
      },
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double page = index.toDouble();
            if (_pageController.position.haveDimensions) {
              page = _pageController.page ?? page;
            }
            final delta = (index - page).clamp(-1.5, 1.5);

            final scale = 1 - 0.10 * delta.abs();
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..translateByDouble(-delta * 28.0, 0, 0, 1)
              ..rotateY(-delta * 0.85)
              ..scaleByDouble(scale, scale, scale, 1);

            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: _CoverflowChild(
                isCenter: delta.abs() < 0.5,
                onSideTap: () => _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                ),
                child: child!,
              ),
            );
          },
          child: index >= widget.items.length
              ? const PaintedSkeletonPane(mode: PaintedSkeletonMode.card)
              : RepaintBoundary(
                  child: _CoverflowCard(
                    content: widget.items[index],
                    actions: widget.actions,
                  ),
                ),
        );
      },
    );
  }
}

/// Wraps the card: side cards get a scrim + tap-to-center; the center card
/// passes touches through to its content.
class _CoverflowChild extends StatelessWidget {
  final bool isCenter;
  final VoidCallback onSideTap;
  final Widget child;

  const _CoverflowChild({
    required this.isCenter,
    required this.onSideTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isCenter) return child;
    return GestureDetector(
      onTap: onSideTap,
      child: AbsorbPointer(
        child: Opacity(opacity: 0.7, child: child),
      ),
    );
  }
}

class _CoverflowCard extends ConsumerWidget {
  final PaintedContent content;
  final PaintedContentActions actions;

  const _CoverflowCard({required this.content, required this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? const Color(0xFFE8DEC8) : const Color(0xFF3A2E1E);
    final accent = isDark ? theme.colorScheme.secondary : theme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardHeight =
              constraints.maxHeight * CoverflowCardPainter.cardFraction;
          final bodyBox = Size(
            constraints.maxWidth - 44,
            cardHeight - 130,
          );
          final fontSize = fitFontSize(
            text: content.body,
            box: bodyBox,
            baseStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
            max: 19,
            min: 11,
          );
          final bodyStyle = TextStyle(
            fontSize: fontSize,
            height: 1.4,
            fontStyle: content.type == PaintedContentType.quote
                ? FontStyle.italic
                : FontStyle.normal,
            color: ink,
          );
          final overflows = textOverflows(
            text: content.body,
            box: bodyBox,
            style: bodyStyle,
          );

          return CustomPaint(
            painter: CoverflowCardPainter(
              brightness: theme.brightness,
              tint: theme.primaryColor,
            ),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                child: SizedBox(
                  height: cardHeight - 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (content.subtitle != null) ...[
                        Text(
                          content.subtitle!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Expanded(
                        child: overflows
                            ? SingleChildScrollView(
                                child: Text(content.body, style: bodyStyle),
                              )
                            : Text(content.body, style: bodyStyle),
                      ),
                      if (content.title != null)
                        GestureDetector(
                          onTap: actions.onTitleTap == null
                              ? null
                              : () => actions.onTitleTap!(context, content),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '— ${content.title}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          PaintedReportShareButtons(
                            content: content,
                            actions: actions,
                            color: ink.withValues(alpha: 0.6),
                            size: 18,
                          ),
                          const Spacer(),
                          PaintedHeartFavorite(
                            content: content,
                            actions: actions,
                            activeColor: Colors.redAccent,
                            inactiveColor: ink.withValues(alpha: 0.5),
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
