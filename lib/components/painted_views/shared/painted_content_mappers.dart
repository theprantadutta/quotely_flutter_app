import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../dtos/ai_fact_dto.dart';
import '../../../dtos/quote_dto.dart';
import '../../../screens/author_detail_screen.dart';
import '../../../services/drift_fact_service.dart';
import '../../../services/drift_quote_service.dart';
import '../../../state_providers/favorite_fact_ids.dart';
import '../../../state_providers/favorite_quote_ids.dart';
import '../../facts_screen/report_fact_dialog.dart';
import '../../home_screen/report_quote_dialog.dart';
import 'painted_content.dart';

PaintedContent paintedFromQuote(QuoteDto quote) => PaintedContent(
  id: quote.id,
  body: quote.content,
  title: quote.author,
  tags: quote.tags,
  routeSlug: quote.authorSlug,
  type: PaintedContentType.quote,
  source: quote,
);

PaintedContent paintedFromFact(AiFactDto fact) => PaintedContent(
  id: fact.id.toString(),
  body: fact.content,
  subtitle: fact.aiFactCategory,
  tags: [fact.aiFactCategory],
  type: PaintedContentType.fact,
  source: fact,
);

/// Builds the quote action bundle, porting the exact behavior of the old
/// HomeScreenQuoteListView (share text format, favorite toggling via Drift,
/// report dialog, author navigation).
PaintedContentActions buildQuotePaintedActions({
  required Future<void> Function() onLastItemReached,
  required Future<void> Function() onRefresh,
}) {
  return PaintedContentActions(
    isFavorite: (ref, content) =>
        ref.watch(favoriteQuoteIdsProvider).contains(content.id),
    onFavoriteToggle: (ref, content) async {
      final quote = content.source as QuoteDto;
      final newValue = !ref.read(favoriteQuoteIdsProvider).contains(quote.id);
      ref
          .read(favoriteQuoteIdsProvider.notifier)
          .addOrUpdateViaStatus(quote.id, newValue);
      await DriftQuoteService.changeQuoteUpdateStatus(quote, newValue);
    },
    onShare: (content) async {
      final quote = content.source as QuoteDto;
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
    onReport: (context, content) {
      showDialog(
        context: context,
        builder: (_) => ReportQuoteDialog(quote: content.source as QuoteDto),
      );
    },
    onTitleTap: (context, content) {
      if (content.routeSlug == null) return;
      context.push('${AuthorDetailScreen.kRouteName}/${content.routeSlug}');
    },
    onLastItemReached: onLastItemReached,
    onRefresh: onRefresh,
  );
}

/// Builds the fact action bundle, porting the exact behavior of SingleFact.
PaintedContentActions buildFactPaintedActions({
  required Future<void> Function() onLastItemReached,
  required Future<void> Function() onRefresh,
}) {
  return PaintedContentActions(
    isFavorite: (ref, content) => ref
        .watch(favoriteFactIdsProvider)
        .contains((content.source as AiFactDto).id),
    onFavoriteToggle: (ref, content) async {
      final fact = content.source as AiFactDto;
      final newValue = !ref.read(favoriteFactIdsProvider).contains(fact.id);
      ref
          .read(favoriteFactIdsProvider.notifier)
          .addOrUpdateViaStatus(fact.id, newValue);
      await DriftFactService.changeFactFavoriteStatus(fact, newValue);
    },
    onShare: (content) async {
      final fact = content.source as AiFactDto;
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
    onReport: (context, content) {
      showDialog(
        context: context,
        builder: (_) => ReportFactDialog(fact: content.source as AiFactDto),
      );
    },
    onTitleTap: null,
    onLastItemReached: onLastItemReached,
    onRefresh: onRefresh,
  );
}
