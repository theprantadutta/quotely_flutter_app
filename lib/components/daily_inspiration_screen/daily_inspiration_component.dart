import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/riverpods/daily_inspiration_provider.dart';

import '../content_carousel/content_mappers.dart';
import '../content_carousel/of_the_day_mappers.dart';
import '../content_carousel/single_feature_card.dart';

class DailyInspirationComponent extends ConsumerWidget {
  const DailyInspirationComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyInspirationProvider = ref.watch(
      fetchTodayDailyInspirationProvider,
    );

    return dailyInspirationProvider.when(
      data: (data) {
        return SingleFeatureCard(
          item: contentItemFromDailyInspiration(data),
          actions: buildQuoteContentActions(onLastItemReached: () async {}),
        );
      },
      error: (err, stack) => const Center(child: Text('Something Went Wrong')),
      loading: () => const SingleFeatureCardSkeleton(),
    );
  }
}
