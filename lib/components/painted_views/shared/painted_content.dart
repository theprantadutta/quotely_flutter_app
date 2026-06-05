import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PaintedContentType { quote, fact }

/// Immutable render model shared by all painted view modes — one shape for
/// both quotes and facts so Book/Deck/Scroll/Coverflow render either without
/// knowing which screen they're on.
class PaintedContent {
  /// Stable string id (AiFact ids are ints, stringified by the mapper).
  final String id;

  /// The quote text / fact text (up to ~1000 chars).
  final String body;

  /// Author name for quotes; null for facts.
  final String? title;

  /// Category for facts; null for quotes.
  final String? subtitle;

  /// Tag chips. For facts this is the category as a single tag.
  final List<String> tags;

  /// Author slug for quote → author detail navigation; null for facts.
  final String? routeSlug;

  final PaintedContentType type;

  /// The original DTO (QuoteDto / AiFactDto) — action handlers cast this
  /// back when they need the full object (e.g. Drift favorite updates).
  final Object source;

  const PaintedContent({
    required this.id,
    required this.body,
    required this.type,
    required this.source,
    this.title,
    this.subtitle,
    this.tags = const [],
    this.routeSlug,
  });
}

/// Behavior bundle wired once per screen and passed to every view mode.
class PaintedContentActions {
  /// Reactive favorite state — implementations use
  /// `ref.watch(provider.select(...))` so only the affected card rebuilds.
  final bool Function(WidgetRef ref, PaintedContent content) isFavorite;

  final Future<void> Function(WidgetRef ref, PaintedContent content)
  onFavoriteToggle;

  final Future<void> Function(PaintedContent content) onShare;

  final void Function(BuildContext context, PaintedContent content) onReport;

  /// Author tap for quotes (pushes AuthorDetailScreen); null for facts.
  final void Function(BuildContext context, PaintedContent content)?
  onTitleTap;

  /// Pagination trigger — called by each mode when the user nears the end.
  final Future<void> Function() onLastItemReached;

  /// Full refresh — pull-to-refresh in scroll mode, top-bar button elsewhere.
  final Future<void> Function() onRefresh;

  const PaintedContentActions({
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onShare,
    required this.onReport,
    required this.onLastItemReached,
    required this.onRefresh,
    this.onTitleTap,
  });
}
