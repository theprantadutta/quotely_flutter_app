import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dtos/motivation_monday_dto.dart';
import '../../riverpods/all_motivation_monday_provider.dart';
import '../content_carousel/content_item.dart';
import '../content_carousel/content_mappers.dart';
import '../content_carousel/of_the_day_mappers.dart';
import '../content_carousel/vertical_content_carousel.dart';

class MotivationMondayListComponent extends ConsumerStatefulWidget {
  const MotivationMondayListComponent({super.key});

  @override
  ConsumerState<MotivationMondayListComponent> createState() =>
      _MotivationMondayListComponentState();
}

class _MotivationMondayListComponentState
    extends ConsumerState<MotivationMondayListComponent> {
  int pageNumber = 1;
  int pageSize = 10;
  bool hasMoreData = true;
  bool _loadingMore = false;
  List<MotivationMondayDto> quotes = [];

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
      items: [
        for (final quote in quotes) contentItemFromMotivationMonday(quote),
      ],
      actions: _actions,
      isLoadingMore: isLoadingMore,
      hasMoreData: hasMoreData,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quoteProvider = ref.watch(
      fetchAllMotivationMondayProvider(pageNumber, pageSize),
    );

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.87,
      width: double.infinity,
      child: quoteProvider.when(
        skipLoadingOnRefresh: false,
        data: (data) {
          final quotesFromDb = data.motivationMondayWithQuotes;
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
