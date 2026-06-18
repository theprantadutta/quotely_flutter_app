import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/shared/something_went_wrong.dart';

import '../../riverpods/weird_fact_wednesday_provider.dart';
import '../content_carousel/content_mappers.dart';
import '../content_carousel/of_the_day_mappers.dart';
import '../content_carousel/single_feature_card.dart';

class WeirdFactWednesdayComponent extends ConsumerWidget {
  const WeirdFactWednesdayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weirdFactWednesdayProvider = ref.watch(
      fetchWeirdFactWednesdayProvider,
    );

    return weirdFactWednesdayProvider.when(
      data: (data) {
        return SingleFeatureCard(
          item: contentItemFromWeirdFactWednesday(data),
          actions: buildFactContentActions(onLastItemReached: () async {}),
        );
      },
      error: (err, stack) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: SomethingWentWrong(
            onRetryPressed: () => ref.refresh(fetchWeirdFactWednesdayProvider),
          ),
        );
      },
      loading: () => const SingleFeatureCardSkeleton(),
    );
  }
}
