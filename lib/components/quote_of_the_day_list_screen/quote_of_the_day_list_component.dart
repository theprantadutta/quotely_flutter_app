import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/quote_of_the_day_dto.dart';
import 'package:quotely_flutter_app/riverpods/all_quote_of_the_day_provider.dart';

import '../content_carousel/content_item.dart';
import '../content_carousel/content_mappers.dart';
import '../content_carousel/of_the_day_mappers.dart';
import '../content_carousel/vertical_content_carousel.dart';

class QuoteOfTheDayListComponent extends ConsumerStatefulWidget {
  const QuoteOfTheDayListComponent({super.key});

  @override
  ConsumerState<QuoteOfTheDayListComponent> createState() =>
      _QuoteOfTheDayListComponentState();
}

class _QuoteOfTheDayListComponentState
    extends ConsumerState<QuoteOfTheDayListComponent> {
  int pageNumber = 1;
  int pageSize = 10;
  bool hasMoreData = true;
  bool _loadingMore = false;
  List<QuoteOfTheDayDto> quotes = [];

  late final ContentActions _actions = buildQuoteContentActions(
    onLastItemReached: _loadMore,
  );

  Future<void> _loadMore() async {
    if (!hasMoreData || _loadingMore) return;
    _loadingMore = true;
    setState(() => pageNumber++);
  }

  Widget _buildCarousel({required bool isLoadingMore}) {
    return VerticalContentCarousel(
      items: [for (final quote in quotes) contentItemFromQuoteOfTheDay(quote)],
      actions: _actions,
      isLoadingMore: isLoadingMore,
      hasMoreData: hasMoreData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quoteProvider = ref.watch(
      fetchAllQuoteOfTheDayProvider(pageNumber, pageSize),
    );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.87,
      width: double.infinity,
      child: quoteProvider.when(
        skipLoadingOnRefresh: false,
        data: (data) {
          final quotesFromDb = data.quoteOfTheDayWithQuotes;
          if (quotesFromDb.length < pageSize) {
            hasMoreData = false;
          }
          for (var quote in quotesFromDb) {
            if (!quotes.any((n) => n.quoteId == quote.quoteId)) {
              quotes.add(quote);
            }
          }
          _loadingMore = false;
          return _buildCarousel(isLoadingMore: false);
        },
        error: (error, stackTrace) =>
            const Center(child: Text('Something Went Wrong')),
        loading: () => _buildCarousel(isLoadingMore: true),
      ),
    );
  }
}
