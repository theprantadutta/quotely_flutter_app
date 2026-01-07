import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../riverpods/today_quote_of_the_day_provider.dart';
import '../shared/neumorphic_notification_quote_card.dart';
import '../shared/something_went_wrong.dart';

class QuoteOfTheDayComponent extends ConsumerWidget {
  const QuoteOfTheDayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteOfTheDayProvider = ref.watch(fetchTodayQuoteOfTheDayProvider);

    return quoteOfTheDayProvider.when(
      data: (data) {
        return NeumorphicNotificationQuoteCard(
          quoteDate: data.quoteDate,
          author: data.author,
          content: data.content,
        );
      },
      error: (err, stack) => SomethingWentWrong(
        title: 'Failed to load quote',
        onRetryPressed: () {
          ref.invalidate(fetchTodayQuoteOfTheDayProvider);
        },
      ),
      loading: () => const NeumorphicNotificationQuoteCardSkeleton(),
    );
  }
}
