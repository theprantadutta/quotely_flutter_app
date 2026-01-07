import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../riverpods/daily_inspiration_provider.dart';
import '../shared/neumorphic_notification_quote_card.dart';
import '../shared/something_went_wrong.dart';

class DailyInspirationComponent extends ConsumerWidget {
  const DailyInspirationComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyInspirationProvider = ref.watch(
      fetchTodayDailyInspirationProvider,
    );

    return dailyInspirationProvider.when(
      data: (data) {
        return NeumorphicNotificationQuoteCard(
          author: data.author,
          content: data.content,
          quoteDate: data.quoteDate,
        );
      },
      error: (err, stack) => SomethingWentWrong(
        title: 'Failed to load inspiration',
        onRetryPressed: () {
          ref.invalidate(fetchTodayDailyInspirationProvider);
        },
      ),
      loading: () => const NeumorphicNotificationQuoteCardSkeleton(),
    );
  }
}
