import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../riverpods/daily_brain_food_provider.dart';
import '../fact_of_the_day_screen/single_fact_of_the_day_component.dart';

class DailyBrainFoodComponent extends ConsumerWidget {
  const DailyBrainFoodComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyBrainFoodProvider = ref.watch(fetchTodayDailyBrainFoodProvider);

    return dailyBrainFoodProvider.when(
      data: (data) {
        return SingleFactOfTheDayComponent(
          factDate: data.factDate,
          content: data.content,
          category: data.aiFactCategory,
        );
      },
      error: (err, stack) => const Center(
        child: Text('Something Went Wrong'),
      ),
      loading: () => const Skeletonizer(
        child: SingleFactOfTheDayComponentSkeletor(),
      ),
    );
  }
}
