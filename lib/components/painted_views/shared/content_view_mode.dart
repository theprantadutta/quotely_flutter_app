import 'package:flutter/material.dart';

/// The custom-painted view modes shared by the Home (quotes) and Facts
/// screens. Persisted globally under [kContentViewModeKey].
enum ContentViewMode { book, deck, scroll, coverflow }

extension ContentViewModeX on ContentViewMode {
  IconData get icon => switch (this) {
    ContentViewMode.book => Icons.menu_book_outlined,
    ContentViewMode.deck => Icons.style_outlined,
    ContentViewMode.scroll => Icons.receipt_long_outlined,
    ContentViewMode.coverflow => Icons.view_carousel_outlined,
  };

  String get label => switch (this) {
    ContentViewMode.book => 'Book',
    ContentViewMode.deck => 'Card Deck',
    ContentViewMode.scroll => 'Scroll',
    ContentViewMode.coverflow => 'Coverflow',
  };

  String get description => switch (this) {
    ContentViewMode.book => 'Flip through pages like a real book',
    ContentViewMode.deck => 'Swipe cards off a stacked deck',
    ContentViewMode.scroll => 'A flowing reading thread',
    ContentViewMode.coverflow => 'Spin a 3D carousel',
  };

  /// The next mode in cycle order (used by the top-bar cycle button).
  ContentViewMode get next =>
      ContentViewMode.values[(index + 1) % ContentViewMode.values.length];

  /// Only the scroll mode has a vertical scrollable that can host a
  /// RefreshIndicator; the other modes show an explicit refresh button.
  bool get supportsPullToRefresh => this == ContentViewMode.scroll;
}
