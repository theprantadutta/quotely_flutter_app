import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../components/quote_of_the_day_screen/single_quote_of_the_component.dart';
import '../../riverpods/today_quote_of_the_day_provider.dart';

class QuoteOfTheDayComponent extends ConsumerWidget {
  const QuoteOfTheDayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteOfTheDayProvider = ref.watch(fetchTodayQuoteOfTheDayProvider);

    return quoteOfTheDayProvider.when(
      data: (data) {
        return SingleQuoteOfTheComponent(
          quoteDate: data.quoteDate,
          author: data.author,
          content: data.content,
        );
      },
      error: (err, stack) => const Center(child: Text('Something Went Wrong')),
      loading: () =>
          const Skeletonizer(child: SingleQuoteOfTheComponentSkeletor()),
    );
  }
}
