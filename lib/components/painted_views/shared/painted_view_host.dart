import 'package:flutter/material.dart';

import '../book/painted_book_view.dart';
import '../coverflow/painted_coverflow_view.dart';
import '../deck/painted_deck_view.dart';
import '../scroll/painted_scroll_view.dart';
import 'content_view_mode.dart';
import 'painted_content.dart';

/// Routes a list of [PaintedContent] to the active painted view mode.
/// Both the Home (quotes) and Facts screens render through this widget.
class PaintedViewHost extends StatelessWidget {
  final ContentViewMode mode;
  final List<PaintedContent> items;
  final PaintedContentActions actions;
  final bool isLoadingMore;
  final bool hasMoreData;

  const PaintedViewHost({
    super.key,
    required this.mode,
    required this.items,
    required this.actions,
    required this.isLoadingMore,
    required this.hasMoreData,
  });

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      ContentViewMode.book => PaintedBookView(
        key: const PageStorageKey('painted_book'),
        items: items,
        actions: actions,
        isLoadingMore: isLoadingMore,
        hasMoreData: hasMoreData,
      ),
      ContentViewMode.deck => PaintedDeckView(
        key: const PageStorageKey('painted_deck'),
        items: items,
        actions: actions,
        isLoadingMore: isLoadingMore,
        hasMoreData: hasMoreData,
      ),
      ContentViewMode.scroll => PaintedScrollView(
        key: const PageStorageKey('painted_scroll'),
        items: items,
        actions: actions,
        isLoadingMore: isLoadingMore,
        hasMoreData: hasMoreData,
      ),
      ContentViewMode.coverflow => PaintedCoverflowView(
        key: const PageStorageKey('painted_coverflow'),
        items: items,
        actions: actions,
        isLoadingMore: isLoadingMore,
        hasMoreData: hasMoreData,
      ),
    };
  }
}
