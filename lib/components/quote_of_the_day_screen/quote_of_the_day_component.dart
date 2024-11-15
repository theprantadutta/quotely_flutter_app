import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/quote_of_the_day_screen/single_quote_of_the_component.dart';
import 'package:quotely_flutter_app/riverpods/today_quote_of_the_day_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class QuoteOfTheDayComponent extends ConsumerWidget {
  const QuoteOfTheDayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteOfTheDayProvider = ref.watch(fetchTodayQuoteOfTheDayProvider);

    return quoteOfTheDayProvider.when(
      data: (data) {
        return SingleQuoteOfTheComponent(
          quoteOfTheDayDto: data,
        );
      },
      error: (err, stack) => const Center(
        child: Text('Something Went Wrong'),
      ),
      loading: () => const Skeletonizer(
        child: SingleQuoteOfTheComponentSkeletor(),
      ),
    );
  }
}
