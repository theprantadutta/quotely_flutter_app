import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../riverpods/motivation_monday_provider.dart';
import '../quote_of_the_day_screen/single_quote_of_the_component.dart';

class MotivationMondayComponent extends ConsumerWidget {
  const MotivationMondayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteOfTheDayProvider = ref.watch(fetchMotivationMondayProvider);

    return quoteOfTheDayProvider.when(
      data: (data) {
        return SingleQuoteOfTheComponent(
          author: data.author,
          content: data.content,
          quoteDate: data.quoteDate,
        );
      },
      error: (err, stack) {
        return const Center(child: Text('Something Went Wrong'));
      },
      loading: () =>
          const Skeletonizer(child: SingleQuoteOfTheComponentSkeletor()),
    );
  }
}
