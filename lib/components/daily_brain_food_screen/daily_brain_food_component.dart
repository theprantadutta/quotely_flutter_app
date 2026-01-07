import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../riverpods/daily_brain_food_provider.dart';
import '../shared/neumorphic_notification_fact_card.dart';
import '../shared/something_went_wrong.dart';

class DailyBrainFoodComponent extends ConsumerWidget {
  const DailyBrainFoodComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyBrainFoodProvider = ref.watch(fetchTodayDailyBrainFoodProvider);

    return dailyBrainFoodProvider.when(
      data: (data) {
        return NeumorphicNotificationFactCard(
          factDate: data.factDate,
          content: data.content,
          category: data.aiFactCategory,
        );
      },
      error: (err, stack) => SomethingWentWrong(
        title: 'Failed to load brain food',
        onRetryPressed: () {
          ref.invalidate(fetchTodayDailyBrainFoodProvider);
        },
      ),
      loading: () => const NeumorphicNotificationFactCardSkeleton(),
    );
  }
}
