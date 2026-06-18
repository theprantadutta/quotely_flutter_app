import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../riverpods/today_quote_of_the_day_provider.dart';
import '../content_carousel/content_mappers.dart';
import '../content_carousel/of_the_day_mappers.dart';
import '../content_carousel/single_feature_card.dart';

class QuoteOfTheDayComponent extends ConsumerWidget {
  const QuoteOfTheDayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteOfTheDayProvider = ref.watch(fetchTodayQuoteOfTheDayProvider);

    return quoteOfTheDayProvider.when(
      data: (data) {
        return SingleFeatureCard(
          item: contentItemFromQuoteOfTheDay(data),
          actions: buildQuoteContentActions(onLastItemReached: () async {}),
        );
      },
      error: (err, stack) => const Center(child: Text('Something Went Wrong')),
      loading: () => const SingleFeatureCardSkeleton(),
    );
  }
}
