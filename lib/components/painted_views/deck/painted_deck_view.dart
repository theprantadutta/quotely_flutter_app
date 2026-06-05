import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/painted_action_buttons.dart';
import '../shared/painted_content.dart';
import '../shared/painted_skeleton.dart';
import '../shared/painted_text_layout.dart';
import 'deck_card_painter.dart';

/// 🃏 Deck mode: a stacked deck of paper cards. Swipe the top card away
/// (rotation + spring physics) to reveal the next; a painted left-edge tab
/// brings the previous card back.
class PaintedDeckView extends ConsumerStatefulWidget {
  final List<PaintedContent> items;
  final PaintedContentActions actions;
  final bool isLoadingMore;
  final bool hasMoreData;

  const PaintedDeckView({
    super.key,
    required this.items,
    required this.actions,
    required this.isLoadingMore,
    required this.hasMoreData,
  });

  @override
  ConsumerState<PaintedDeckView> createState() => _PaintedDeckViewState();
}

class _PaintedDeckViewState extends ConsumerState<PaintedDeckView>
    with TickerProviderStateMixin {
  int _index = 0;
  Offset _dragOffset = Offset.zero;
  bool _isFlyingOut = false;

  late final AnimationController _snapController = AnimationController.unbounded(
    vsync: this,
  );

  late final AnimationController _flyOutController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  /// Animates the remaining stack into their new slots with overshoot.
  late final AnimationController _promoteController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  Offset _flyOutTarget = Offset.zero;

  @override
  void initState() {
    super.initState();
    _snapController.addListener(() {
      setState(() => _dragOffset = _dragOffset * _snapController.value);
    });
  }

  @override
  void didUpdateWidget(covariant PaintedDeckView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clamp the index when the item list shrinks (refresh / filter change)
    if (_index >= widget.items.length && widget.items.isNotEmpty) {
      _index = widget.items.length - 1;
    }
    if (widget.items.length < oldWidget.items.length) {
      _index = 0;
      _dragOffset = Offset.zero;
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    _flyOutController.dispose();
    _promoteController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isFlyingOut) return;
    setState(() => _dragOffset += details.delta);
  }

  void _onPanEnd(DragEndDetails details, Size size) {
    if (_isFlyingOut) return;
    final velocity = details.velocity.pixelsPerSecond;
    final shouldDismiss =
        _dragOffset.dx.abs() > size.width * 0.35 || velocity.dx.abs() > 800;

    if (shouldDismiss && _index < widget.items.length) {
      _flyOut(size);
    } else {
      _snapBack(velocity);
    }
  }

  void _flyOut(Size size) {
    _isFlyingOut = true;
    final direction = _dragOffset.dx >= 0 ? 1.0 : -1.0;
    _flyOutTarget = Offset(
      direction * size.width * 1.4,
      _dragOffset.dy + size.height * 0.2,
    );
    final start = _dragOffset;
    final animation = CurvedAnimation(
      parent: _flyOutController,
      curve: Curves.easeIn,
    );
    void tick() {
      setState(
        () => _dragOffset = Offset.lerp(start, _flyOutTarget, animation.value)!,
      );
    }

    _flyOutController.addListener(tick);
    _flyOutController.forward(from: 0).whenComplete(() {
      _flyOutController.removeListener(tick);
      setState(() {
        _index++;
        _dragOffset = Offset.zero;
        _isFlyingOut = false;
      });
      _promoteController.forward(from: 0);
      if (widget.items.length - _index < 4) {
        widget.actions.onLastItemReached();
      }
    });
  }

  void _snapBack(Offset velocity) {
    // Spring the card back to center; the controller value scales the
    // current offset from 1 → 0 with a slight overshoot.
    const spring = SpringDescription(mass: 1, stiffness: 380, damping: 24);
    _snapController.value = 1;
    _snapController.animateWith(
      SpringSimulation(spring, 1, 0, -velocity.distance / 1000),
    );
  }

  void _goBack() {
    if (_index == 0) return;
    setState(() {
      _index--;
      _dragOffset = Offset.zero;
    });
    _promoteController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && widget.isLoadingMore) {
      return const PaintedSkeletonPane(mode: PaintedSkeletonMode.card);
    }
    if (_index >= widget.items.length) {
      // Ran past the end (e.g. waiting on pagination)
      return widget.isLoadingMore
          ? const PaintedSkeletonPane(mode: PaintedSkeletonMode.card)
          : Center(
              child: TextButton.icon(
                onPressed: _index > 0 ? _goBack : null,
                icon: const Icon(Icons.undo),
                label: const Text('Back to the deck'),
              ),
            );
    }

    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final cardWidth = size.width * 0.82;
        final cardHeight = size.height * 0.78;

        final visible = <Widget>[];
        // Bottom-up: deepest card first
        for (var depth = 3; depth >= 0; depth--) {
          final itemIndex = _index + depth;
          if (itemIndex >= widget.items.length) {
            if (depth == 3 && widget.isLoadingMore && widget.hasMoreData) {
              visible.add(
                _positionedCard(
                  depth: depth,
                  cardWidth: cardWidth,
                  cardHeight: cardHeight,
                  child: const PaintedSkeletonPane(
                    mode: PaintedSkeletonMode.card,
                  ),
                ),
              );
            }
            continue;
          }

          final content = widget.items[itemIndex];
          final card = RepaintBoundary(
            child: _DeckCard(
              content: content,
              actions: widget.actions,
              depth: depth,
              size: Size(cardWidth, cardHeight),
            ),
          );

          if (depth == 0) {
            // Top card: draggable with rotation anchored at bottom center
            final rotation = _dragOffset.dx / size.width * 0.35;
            visible.add(
              Center(
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: (d) => _onPanEnd(d, size),
                  child: Transform.translate(
                    offset: _dragOffset,
                    child: Transform.rotate(
                      angle: rotation,
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: card,
                      ),
                    ),
                  ),
                ),
              ),
            );
          } else {
            visible.add(
              _positionedCard(
                depth: depth,
                cardWidth: cardWidth,
                cardHeight: cardHeight,
                child: card,
              ),
            );
          }
        }

        return Stack(
          children: [
            ...visible,
            // Return tab: painted left-edge handle to go back a card
            if (_index > 0)
              Positioned(
                left: 0,
                top: size.height * 0.42,
                child: GestureDetector(
                  onTap: _goBack,
                  child: Container(
                    width: 30,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.85),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            // Progress hint
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '${min(_index + 1, widget.items.length)} / ${widget.items.length}${widget.hasMoreData ? '+' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Stacked (non-top) cards animate to their slots with a springy promote.
  Widget _positionedCard({
    required int depth,
    required double cardWidth,
    required double cardHeight,
    required Widget child,
  }) {
    return Center(
      child: AnimatedBuilder(
        animation: _promoteController,
        builder: (context, c) {
          final promote = CurvedAnimation(
            parent: _promoteController,
            curve: Curves.elasticOut,
          ).value;
          // During a promote animation, cards slide from depth+1 → depth
          final effectiveDepth = _promoteController.isAnimating
              ? depth + (1 - promote)
              : depth.toDouble();
          return Transform.translate(
            offset: Offset(0, 14.0 * effectiveDepth),
            child: Transform.scale(
              scale: 1 - 0.045 * effectiveDepth,
              child: c,
            ),
          );
        },
        child: SizedBox(width: cardWidth, height: cardHeight, child: child),
      ),
    );
  }
}

class _DeckCard extends ConsumerWidget {
  final PaintedContent content;
  final PaintedContentActions actions;
  final int depth;
  final Size size;

  const _DeckCard({
    required this.content,
    required this.actions,
    required this.depth,
    required this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ink = isDark ? const Color(0xFFE8DEC8) : const Color(0xFF3A2E1E);
    final accent = isDark ? theme.colorScheme.secondary : theme.primaryColor;

    final bodyBox = Size(size.width - 56, size.height - 150);
    final fontSize = fitFontSize(
      text: content.body,
      box: bodyBox,
      baseStyle: theme.textTheme.bodyMedium ?? const TextStyle(),
      max: 21,
      min: 12,
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

    return CustomPaint(
      painter: DeckCardPainter(
        brightness: theme.brightness,
        tint: theme.primaryColor,
        depth: depth,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 10),
        child: depth > 0
            // Deeper cards: chrome only — content hidden under the stack
            ? const SizedBox.expand()
            : Column(
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
                  Expanded(
                    child: overflows
                        ? SingleChildScrollView(
                            child: Text(content.body, style: bodyStyle),
                          )
                        : Center(
                            child: Text(content.body, style: bodyStyle),
                          ),
                  ),
                  if (content.title != null)
                    GestureDetector(
                      onTap: actions.onTitleTap == null
                          ? null
                          : () => actions.onTitleTap!(context, content),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '— ${content.title}',
                          style: TextStyle(
                            fontSize: 14,
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
                      ),
                      const Spacer(),
                      PaintedHeartFavorite(
                        content: content,
                        actions: actions,
                        activeColor: Colors.redAccent,
                        inactiveColor: ink.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
