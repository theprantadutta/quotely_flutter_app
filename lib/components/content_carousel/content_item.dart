import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ContentItemType { quote, fact }

/// Immutable render model shared by the Home (quotes) and Facts screens —
/// one shape for both so the carousel renders either without knowing which
/// screen it's on.
class ContentItem {
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

  final ContentItemType type;

  /// The original DTO (QuoteDto / AiFactDto) — action handlers cast this
  /// back when they need the full object (e.g. Drift favorite updates).
  final Object source;

  const ContentItem({
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

/// Behavior bundle wired once per screen and passed to the carousel.
class ContentActions {
  /// Reactive favorite state — implementations use
  /// `ref.watch(provider.select(...))` so only the affected card rebuilds.
  final bool Function(WidgetRef ref, ContentItem item) isFavorite;

  final Future<void> Function(WidgetRef ref, ContentItem item)
  onFavoriteToggle;

  final Future<void> Function(ContentItem item) onShare;

  final void Function(BuildContext context, ContentItem item) onReport;

  /// Author tap for quotes (pushes AuthorDetailScreen); null for facts.
  final void Function(BuildContext context, ContentItem item)? onTitleTap;

  /// Pagination trigger — called when the user nears the end.
  final Future<void> Function() onLastItemReached;

  const ContentActions({
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onShare,
    required this.onReport,
    required this.onLastItemReached,
    this.onTitleTap,
  });
}
