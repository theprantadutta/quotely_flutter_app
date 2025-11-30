import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/riverpods/daily_inspiration_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../components/quote_of_the_day_screen/single_quote_of_the_component.dart';

class DailyInspirationComponent extends ConsumerWidget {
  const DailyInspirationComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyInspirationProvider = ref.watch(
      fetchTodayDailyInspirationProvider,
    );

    return dailyInspirationProvider.when(
      data: (data) {
        return SingleQuoteOfTheComponent(
          author: data.author,
          content: data.content,
          quoteDate: data.quoteDate,
        );
      },
      error: (err, stack) => const Center(child: Text('Something Went Wrong')),
      loading: () =>
          const Skeletonizer(child: SingleQuoteOfTheComponentSkeletor()),
    );
  }
}
