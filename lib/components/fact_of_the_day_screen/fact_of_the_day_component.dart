import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/shared/something_went_wrong.dart';

import '../../riverpods/today_fact_of_the_day_provider.dart';
import '../content_carousel/content_mappers.dart';
import '../content_carousel/of_the_day_mappers.dart';
import '../content_carousel/single_feature_card.dart';

class FactOfTheDayComponent extends ConsumerWidget {
  const FactOfTheDayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factOfTheDayProvider = ref.watch(fetchTodayFactOfTheDayProvider);

    return factOfTheDayProvider.when(
      data: (data) {
        return SingleFeatureCard(
          item: contentItemFromFactOfTheDay(data),
          actions: buildFactContentActions(onLastItemReached: () async {}),
        );
      },
      error: (err, stack) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: SomethingWentWrong(
          onRetryPressed: () => ref.refresh(fetchTodayFactOfTheDayProvider),
        ),
      ),
      loading: () => const SingleFeatureCardSkeleton(),
    );
  }
}
