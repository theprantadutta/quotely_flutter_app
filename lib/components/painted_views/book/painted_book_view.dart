import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/painted_action_buttons.dart';
import '../shared/painted_content.dart';
import '../shared/painted_skeleton.dart';
import '../shared/painted_text_layout.dart';
import 'book_chrome_painter.dart';
import 'page_curl_painter.dart';
import 'ribbon_bookmark.dart';

/// 📖 Book mode: each quote/fact is an open-book spread. Body text fills the
/// left page; author/category, tags, actions, and the ribbon-bookmark
/// favorite live on the right page. Swiping turns the page with a painted
/// curl; the next spread is revealed underneath as the fold advances.
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
  /// revealing the next spread). Backward navigation runs the same flip in
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

  bool get _hasNext => _index < widget.items.length - 1 || widget.hasMoreData;

  void _onDragStart(DragStartDetails details, double bookWidth) {
    if (_flip.isAnimating) return;
    _dragStartX = details.localPosition.dx;
    // Backward flips start in the left 40% of the book and need history
    _draggingBackward = details.localPosition.dx < bookWidth * 0.4 && _index > 0;
    if (_draggingBackward) {
      // Pre-step: the previous item becomes "current", fully folded (t=1);
      // dragging right unfolds it back over this spread.
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
      if (!_hasNext && _index >= widget.items.length - 1) return;
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
        .whenComplete(() => onComplete?.call());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.isLoadingMore) {
      return const PaintedSkeletonPane(mode: PaintedSkeletonMode.page);
    }
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bookWidth = constraints.maxWidth - 16;
        final bookHeight = constraints.maxHeight - 24;
        final pagesRect = Rect.fromLTWH(
          BookChromePainter.coverBorder,
          BookChromePainter.coverBorder,
          bookWidth - BookChromePainter.coverBorder * 2,
          bookHeight - BookChromePainter.coverBorder * 2,
        );
        final pageWidth = pagesRect.width / 2;

        final current = widget.items[_index];
        final next = _index + 1 < widget.items.length
            ? widget.items[_index + 1]
            : null;

        return Center(
          child: GestureDetector(
            onHorizontalDragStart: (d) => _onDragStart(d, bookWidth),
            onHorizontalDragUpdate: (d) => _onDragUpdate(d, pageWidth),
            onHorizontalDragEnd: _onDragEnd,
            child: SizedBox(
              width: bookWidth,
              height: bookHeight,
              child: RepaintBoundary(
                child: Stack(
                  children: [
                    // Book chrome (cover, paper, spine, page edges)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BookChromePainter(
                          brightness: theme.brightness,
                          tint: theme.primaryColor,
                        ),
                      ),
                    ),
                    // Next spread underneath (revealed by the fold)
                    if (next != null)
                      Positioned.fromRect(
                        rect: pagesRect,
                        child: _BookSpread(
                          content: next,
                          actions: widget.actions,
                          interactive: false,
                        ),
                      )
                    else if (widget.isLoadingMore)
                      Positioned.fromRect(
                        rect: pagesRect,
                        child: const PaintedSkeletonPane(
                          mode: PaintedSkeletonMode.page,
                        ),
                      ),
                    // Current spread, clipped left of the crease during flips
                    Positioned.fromRect(
                      rect: pagesRect,
                      child: AnimatedBuilder(
                        animation: _flip,
                        builder: (context, child) => ClipPath(
                          clipper: PageCurlClipper(
                            t: _flip.value,
                            pagesRect: Offset.zero & pagesRect.size,
                          ),
                          child: child,
                        ),
                        child: _BookSpread(
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
                            brightness: theme.brightness,
                            tint: theme.primaryColor,
                            pagesRect: pagesRect,
                          ),
                        ),
                      ),
                    ),
                    // Page number hint
                    Positioned(
                      bottom: 2,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          '${_index + 1} / ${widget.items.length}${widget.hasMoreData ? '+' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One open spread: body on the left page, meta + actions on the right.
class _BookSpread extends ConsumerWidget {
  final PaintedContent content;
  final PaintedContentActions actions;

  /// The next spread underneath is visible but must not steal taps.
  final bool interactive;

  const _BookSpread({
    required this.content,
    required this.actions,
    required this.interactive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? const Color(0xFFE8DEC8) : const Color(0xFF3A2E1E);
    final accent = isDark ? theme.colorScheme.secondary : theme.primaryColor;

    final spread = LayoutBuilder(
      builder: (context, constraints) {
        final pageWidth = constraints.maxWidth / 2;
        final bodyBox = Size(pageWidth - 44, constraints.maxHeight - 48);
        final fontSize = fitFontSize(
          text: content.body,
          box: bodyBox,
          baseStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
          max: 18,
          min: 10,
        );
        final bodyStyle = TextStyle(
          fontSize: fontSize,
          height: 1.45,
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

        return Row(
          children: [
            // Left page: the text itself
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                child: overflows
                    ? SingleChildScrollView(
                        child: Text(content.body, style: bodyStyle),
                      )
                    : Center(child: Text(content.body, style: bodyStyle)),
              ),
            ),
            // Right page: meta, tags, actions, ribbon
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 22, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (content.title != null)
                          GestureDetector(
                            onTap: actions.onTitleTap == null
                                ? null
                                : () => actions.onTitleTap!(context, content),
                            child: Text(
                              content.title!,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        if (content.subtitle != null)
                          Text(
                            content.subtitle!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Container(
                          width: 56,
                          height: 2,
                          color: accent.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        // Tag "ink stamps"
                        Wrap(
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
                        const Spacer(),
                        PaintedReportShareButtons(
                          content: content,
                          actions: actions,
                          color: ink.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  // Ribbon bookmark hanging over the top edge
                  Positioned(
                    top: 0,
                    right: 18,
                    child: RibbonBookmark(content: content, actions: actions),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    return interactive ? spread : IgnorePointer(child: spread);
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
