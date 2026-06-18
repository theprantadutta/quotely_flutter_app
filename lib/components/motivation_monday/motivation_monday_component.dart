import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../riverpods/motivation_monday_provider.dart';
import '../content_carousel/content_mappers.dart';
import '../content_carousel/of_the_day_mappers.dart';
import '../content_carousel/single_feature_card.dart';

class MotivationMondayComponent extends ConsumerWidget {
  const MotivationMondayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motivationMondayProvider = ref.watch(fetchMotivationMondayProvider);

    return motivationMondayProvider.when(
      data: (data) {
        return SingleFeatureCard(
          item: contentItemFromMotivationMonday(data),
          actions: buildQuoteContentActions(onLastItemReached: () async {}),
        );
      },
      error: (err, stack) {
        return const Center(child: Text('Something Went Wrong'));
      },
      loading: () => const SingleFeatureCardSkeleton(),
    );
  }
}
