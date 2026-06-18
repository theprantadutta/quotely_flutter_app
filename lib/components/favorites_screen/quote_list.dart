import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

import '../../dtos/quote_dto.dart';
import '../../service_locator/init_service_locators.dart';
import '../../services/drift_quote_service.dart';
import '../content_carousel/content_item.dart';
import '../content_carousel/content_mappers.dart';
import '../content_carousel/vertical_content_carousel.dart';
import 'favorites_carousel_states.dart';

/// Favorite quotes, rendered with the same swipeable card carousel the Home
/// and Facts screens use — so favorites look and feel identical to the rest
/// of the app. Cards stream live from Drift, so un-hearting one here removes
/// it from the carousel immediately.
class QuoteList extends StatefulWidget {
  const QuoteList({super.key});

  @override
  State<QuoteList> createState() => _QuoteListState();
}

class _QuoteListState extends State<QuoteList> {
  final _analytics = getIt.get<FirebaseAnalytics>();

  // Favorites don't paginate — the whole favorite set streams from Drift.
  late final ContentActions _actions = buildQuoteContentActions(
    onLastItemReached: () async {},
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: DriftQuoteService.watchAllFavoriteQuotes([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FavoritesSkeletonCard();
        }
        if (snapshot.hasError) {
          _analytics.logEvent(
            name: 'favorites_quotes_load_failed',
            parameters: {'error': snapshot.error.toString()},
          );
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('Something Went Wrong')),
          );
        }
        final quotes = snapshot.data!;
        if (quotes.isEmpty) {
          return const FavoritesEmptyState(
            message:
                'When you like a quote, it\'s going to show up here, this '
                'section helps you to read your Favorite quotes over and over',
          );
        }
        return VerticalContentCarousel(
          items: [
            for (final quote in QuoteDto.fromQuoteList(quotes))
              contentItemFromQuote(quote),
          ],
          actions: _actions,
          isLoadingMore: false,
          hasMoreData: false,
        );
      },
    );
  }
}
