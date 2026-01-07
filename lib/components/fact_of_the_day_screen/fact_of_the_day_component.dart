import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../riverpods/today_fact_of_the_day_provider.dart';
import '../shared/neumorphic_notification_fact_card.dart';
import '../shared/something_went_wrong.dart';

class FactOfTheDayComponent extends ConsumerWidget {
  const FactOfTheDayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factOfTheDayProvider = ref.watch(fetchTodayFactOfTheDayProvider);

    return factOfTheDayProvider.when(
      data: (data) {
        return NeumorphicNotificationFactCard(
          factDate: data.factDate,
          content: data.content,
          category: data.aiFactCategory,
        );
      },
      error: (err, stack) => SomethingWentWrong(
        title: 'Failed to load fact',
        onRetryPressed: () {
          ref.invalidate(fetchTodayFactOfTheDayProvider);
        },
      ),
      loading: () => const NeumorphicNotificationFactCardSkeleton(),
    );
  }
}
