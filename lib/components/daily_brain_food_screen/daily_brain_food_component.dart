import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../riverpods/daily_brain_food_provider.dart';
import '../content_carousel/content_mappers.dart';
import '../content_carousel/of_the_day_mappers.dart';
import '../content_carousel/single_feature_card.dart';

class DailyBrainFoodComponent extends ConsumerWidget {
  const DailyBrainFoodComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyBrainFoodProvider = ref.watch(fetchTodayDailyBrainFoodProvider);

    return dailyBrainFoodProvider.when(
      data: (data) {
        return SingleFeatureCard(
          item: contentItemFromDailyBrainFood(data),
          actions: buildFactContentActions(onLastItemReached: () async {}),
        );
      },
      error: (err, stack) => const Center(child: Text('Something Went Wrong')),
      loading: () => const SingleFeatureCardSkeleton(),
    );
  }
}
