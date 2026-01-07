import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../riverpods/motivation_monday_provider.dart';
import '../shared/neumorphic_notification_quote_card.dart';
import '../shared/something_went_wrong.dart';

class MotivationMondayComponent extends ConsumerWidget {
  const MotivationMondayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motivationMondayProvider = ref.watch(fetchMotivationMondayProvider);

    return motivationMondayProvider.when(
      data: (data) {
        return NeumorphicNotificationQuoteCard(
          author: data.author,
          content: data.content,
          quoteDate: data.quoteDate,
        );
      },
      error: (err, stack) => SomethingWentWrong(
        title: 'Failed to load motivation',
        onRetryPressed: () {
          ref.invalidate(fetchMotivationMondayProvider);
        },
      ),
      loading: () => const NeumorphicNotificationQuoteCardSkeleton(),
    );
  }
}
