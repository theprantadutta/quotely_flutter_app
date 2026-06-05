import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/painted_action_buttons.dart';
import '../shared/painted_card_style.dart';
import '../shared/painted_content.dart';
import '../shared/painted_skeleton.dart';
import '../shared/painted_text_layout.dart';
import 'book_chrome_painter.dart';
import 'page_curl_painter.dart';
import 'ribbon_bookmark.dart';

/// 📖 Book mode: each quote/fact is one full page. Swiping turns the page
/// with a painted curl that sweeps the whole width; the next page (opaque)
/// is revealed underneath as the fold advances.
class PaintedBookView extends ConsumerStatefulWidget {
  final List<PaintedContent> items;
  final PaintedContentActions actions;
  final bool isLoadingMore;
  final bool hasMoreData;

  const PaintedBookView({
    super.key,
    required this.items,
    required this.actions,
    required this.isLoadingMore,
    required this.hasMoreData,
  });

  @override
  ConsumerState<PaintedBookView> createState() => _PaintedBookViewState();
}

class _PaintedBookViewState extends ConsumerState<PaintedBookView>
    with SingleTickerProviderStateMixin {
  int _index = 0;

  /// Flip progress 0..1. Forward flips drive 0 → 1 (current page turns,
  /// revealing the next page). Backward navigation runs the same flip in
  /// reverse with the roles swapped.
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  double? _dragStartX;
  bool _draggingBackward = false;

  @override
  void didUpdateWidget(covariant PaintedBookView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.items.length && widget.items.isNotEmpty) {
      _index = widget.items.length - 1;
    }
    if (widget.items.length < oldWidget.items.length) {
      _index = 0;
      _flip.value = 0;
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details, double pageWidth) {
    if (!mounted || _flip.isAnimating) return;
    _dragStartX = details.localPosition.dx;
    // Backward flips start in the left 30% of the page and need history
    _draggingBackward =
        details.localPosition.dx < pageWidth * 0.3 && _index > 0;
    if (_draggingBackward) {
      // Pre-step: the previous item becomes "current", fully folded (t=1);
      // dragging right unfolds it back over this page.
      setState(() {
        _index--;
        _flip.value = 1;
      });
    }
  }

  void _onDragUpdate(DragUpdateDetails details, double pageWidth) {
    final startX = _dragStartX;
    if (startX == null || _flip.isAnimating) return;
    final dx = details.localPosition.dx - startX;
    if (_draggingBackward) {
      _flip.value = (1 - dx / pageWidth).clamp(0.0, 1.0);
    } else {
      if (_index >= widget.items.length - 1) return;
      _flip.value = (-dx / pageWidth).clamp(0.0, 1.0);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragStartX == null || _flip.isAnimating) return;
    _dragStartX = null;
    final velocity = details.velocity.pixelsPerSecond.dx;
    final t = _flip.value;

    if (_draggingBackward) {
      // Settle open (t→0, previous page restored) unless barely moved
      final settleOpen = t < 0.7 || velocity > 700;
      if (settleOpen) {
        _settleTo(0);
      } else {
        _settleTo(1, onComplete: () {
          setState(() {
            _index++;
            _flip.value = 0;
          });
        });
      }
      _draggingBackward = false;
      return;
    }

    final complete = t > 0.3 || velocity < -700;
    if (complete && _index < widget.items.length - 1) {
      _settleTo(1, onComplete: () {
        setState(() {
          _index++;
          _flip.value = 0;
        });
        if (_index >= widget.items.length - 3) {
          widget.actions.onLastItemReached();
        }
      });
    } else {
      _settleTo(0);
    }
  }

  void _settleTo(double target, {VoidCallback? onComplete}) {
    final distance = (target - _flip.value).abs();
    _flip
        .animateTo(
          target,
          duration: Duration(
            milliseconds: (320 * distance).clamp(80, 320).round(),
          ),
          curve: target == 1 ? Curves.easeOutCubic : Curves.easeOut,
        )
        .whenComplete(() {
          // The settle can outlive this view (mode switch mid-flip).
          if (!mounted) return;
          onComplete?.call();
        });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.isLoadingMore) {
      return const PaintedSkeletonPane(mode: PaintedSkeletonMode.page);
    }
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cardStyle = PaintedCardStyle.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final pageRect = Rect.fromLTWH(
          8,
          6,
          constraints.maxWidth - 16,
          constraints.maxHeight - 34,
        );

        final current = widget.items[_index];
        final next = _index + 1 < widget.items.length
            ? widget.items[_index + 1]
            : null;

        return GestureDetector(
          onHorizontalDragStart: (d) => _onDragStart(d, pageRect.width),
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, pageRect.width),
          onHorizontalDragEnd: _onDragEnd,
          child: RepaintBoundary(
            child: Stack(
              children: [
                // Next page underneath (revealed by the fold). Pages paint
                // their own opaque surface, so nothing bleeds through.
                Positioned.fromRect(
                  rect: pageRect,
                  child: next != null
                      ? _BookPage(
                          content: next,
                          actions: widget.actions,
                          interactive: false,
                        )
                      : widget.isLoadingMore
                      ? const PaintedSkeletonPane(
                          mode: PaintedSkeletonMode.page,
                        )
                      : const SizedBox.shrink(),
                ),
                // Current page, clipped left of the crease during flips
                Positioned.fromRect(
                  rect: pageRect,
                  child: AnimatedBuilder(
                    animation: _flip,
                    builder: (context, child) => ClipPath(
                      clipper: PageCurlClipper(
                        t: _flip.value,
                        pagesRect: Offset.zero & pageRect.size,
                      ),
                      child: child,
                    ),
                    child: _BookPage(
                      content: current,
                      actions: widget.actions,
                      interactive: true,
                    ),
                  ),
                ),
                // The animated fold itself
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: PageCurlPainter(
                        progress: _flip,
                        style: cardStyle,
                        pagesRect: pageRect,
                      ),
                    ),
                  ),
                ),
                // Page number hint
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '${_index + 1} / ${widget.items.length}${widget.hasMoreData ? '+' : ''}',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One full, opaque book page: body in the middle, meta + actions at the
/// bottom, ribbon bookmark over the top-right edge.
class _BookPage extends ConsumerWidget {
  final PaintedContent content;
  final PaintedContentActions actions;

  /// The next page underneath is visible but must not steal taps.
  final bool interactive;

  const _BookPage({
    required this.content,
    required this.actions,
    required this.interactive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cardStyle = PaintedCardStyle.of(context);
    final ink = cardStyle.ink;
    final accent = cardStyle.accent;

    final page = LayoutBuilder(
      builder: (context, constraints) {
        // Body area: page minus paddings and the ~120px meta/footer zone
        final bodyBox = Size(
          constraints.maxWidth - 60,
          constraints.maxHeight - 196,
        );
        final fontSize = fitFontSize(
          text: content.body,
          box: bodyBox,
          baseStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
          max: 24,
          min: 13,
        );
        final bodyStyle = TextStyle(
          fontSize: fontSize,
          height: 1.5,
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
          painter: BookPagePainter(style: cardStyle),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 24, 30, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (content.subtitle != null)
                      Padding(
                        // Clear the ribbon hanging at top-right
                        padding: const EdgeInsets.only(right: 48),
                        child: Text(
                          content.subtitle!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    // Body fills the middle of the page
                    Expanded(
                      child: overflows
                          ? Padding(
                              padding: const EdgeInsets.only(top: 30),
                              child: SingleChildScrollView(
                                child: Text(content.body, style: bodyStyle),
                              ),
                            )
                          : Center(
                              child: Text(content.body, style: bodyStyle),
                            ),
                    ),
                    const SizedBox(height: 10),
                    // Footer: author, tags, actions
                    if (content.title != null)
                      GestureDetector(
                        onTap: actions.onTitleTap == null
                            ? null
                            : () => actions.onTitleTap!(context, content),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 2,
                              color: accent.withValues(alpha: 0.6),
                              margin: const EdgeInsets.only(bottom: 6),
                            ),
                            Text(
                              content.title!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (content.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final tag in content.tags.take(3))
                              _InkStamp(label: tag, color: accent),
                            if (content.tags.length > 3)
                              _InkStamp(
                                label: '+${content.tags.length - 3}',
                                color: accent,
                              ),
                          ],
                        ),
                      ),
                    PaintedReportShareButtons(
                      content: content,
                      actions: actions,
                      color: cardStyle.faintInk,
                      size: 19,
                    ),
                  ],
                ),
              ),
              // Ribbon bookmark hanging over the top edge
              Positioned(
                top: 0,
                right: 26,
                child: RibbonBookmark(content: content, actions: actions),
              ),
            ],
          ),
        );
      },
    );

    return interactive ? page : IgnorePointer(child: page);
  }
}

class _InkStamp extends StatelessWidget {
  final String label;
  final Color color;

  const _InkStamp({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
