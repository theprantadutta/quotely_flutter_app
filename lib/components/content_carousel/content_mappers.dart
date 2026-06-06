import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../dtos/ai_fact_dto.dart';
import '../../dtos/quote_dto.dart';
import '../../screens/author_detail_screen.dart';
import '../../services/drift_fact_service.dart';
import '../../services/drift_quote_service.dart';
import '../../state_providers/favorite_fact_ids.dart';
import '../../state_providers/favorite_quote_ids.dart';
import '../facts_screen/report_fact_dialog.dart';
import '../home_screen/report_quote_dialog.dart';
import 'content_item.dart';

ContentItem contentItemFromQuote(QuoteDto quote) => ContentItem(
  id: quote.id,
  body: quote.content,
  title: quote.author,
  tags: quote.tags,
  routeSlug: quote.authorSlug,
  type: ContentItemType.quote,
  source: quote,
);

ContentItem contentItemFromFact(AiFactDto fact) => ContentItem(
  id: fact.id.toString(),
  body: fact.content,
  subtitle: fact.aiFactCategory,
  tags: [fact.aiFactCategory],
  type: ContentItemType.fact,
  source: fact,
);

/// Builds the quote action bundle (share text format, favorite toggling via
/// Drift, report dialog, author navigation).
///
/// [enableAuthorTap] is false on the Author Detail screen, where navigating
/// to the tapped author would just push the same screen again.
ContentActions buildQuoteContentActions({
  required Future<void> Function() onLastItemReached,
  bool enableAuthorTap = true,
}) {
  return ContentActions(
    isFavorite: (ref, item) =>
        ref.watch(favoriteQuoteIdsProvider).contains(item.id),
    onFavoriteToggle: (ref, item) async {
      final quote = item.source as QuoteDto;
      final newValue = !ref.read(favoriteQuoteIdsProvider).contains(quote.id);
      ref
          .read(favoriteQuoteIdsProvider.notifier)
          .addOrUpdateViaStatus(quote.id, newValue);
      await DriftQuoteService.changeQuoteUpdateStatus(quote, newValue);
    },
    onShare: (item) async {
      final quote = item.source as QuoteDto;
      final shareText =
          '''
"${quote.content}" - ${quote.author}

Shared via Quotely
''';
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Amazing quote by ${quote.author}',
          sharePositionOrigin: const Rect.fromLTRB(0, 0, 0, 0),
        ),
      );
    },
    onReport: (context, item) {
      showDialog(
        context: context,
        builder: (_) => ReportQuoteDialog(quote: item.source as QuoteDto),
      );
    },
    onTitleTap: !enableAuthorTap
        ? null
        : (context, item) {
            if (item.routeSlug == null) return;
            context.push(
              '${AuthorDetailScreen.kRouteName}/${item.routeSlug}',
            );
          },
    onLastItemReached: onLastItemReached,
  );
}

/// Builds the fact action bundle (share text format, favorite toggling via
/// Drift, report dialog).
ContentActions buildFactContentActions({
  required Future<void> Function() onLastItemReached,
}) {
  return ContentActions(
    isFavorite: (ref, item) => ref
        .watch(favoriteFactIdsProvider)
        .contains((item.source as AiFactDto).id),
    onFavoriteToggle: (ref, item) async {
      final fact = item.source as AiFactDto;
      final newValue = !ref.read(favoriteFactIdsProvider).contains(fact.id);
      ref
          .read(favoriteFactIdsProvider.notifier)
          .addOrUpdateViaStatus(fact.id, newValue);
      await DriftFactService.changeFactFavoriteStatus(fact, newValue);
    },
    onShare: (item) async {
      final fact = item.source as AiFactDto;
      final shareText =
          '''
"${fact.content}"

Shared via Quotely
''';
      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Amazing fact from Quotely',
          sharePositionOrigin: const Rect.fromLTRB(0, 0, 0, 0),
        ),
      );
    },
    onReport: (context, item) {
      showDialog(
        context: context,
        builder: (_) => ReportFactDialog(fact: item.source as AiFactDto),
      );
    },
    onTitleTap: null,
    onLastItemReached: onLastItemReached,
  );
}
