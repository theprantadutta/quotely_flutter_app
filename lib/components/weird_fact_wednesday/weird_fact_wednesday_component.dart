import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../riverpods/weird_fact_wednesday_provider.dart';
import '../shared/neumorphic_notification_fact_card.dart';
import '../shared/something_went_wrong.dart';

class WeirdFactWednesdayComponent extends ConsumerWidget {
  const WeirdFactWednesdayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weirdFactProvider = ref.watch(fetchWeirdFactWednesdayProvider);

    return weirdFactProvider.when(
      data: (data) {
        return NeumorphicNotificationFactCard(
          factDate: data.factDate,
          content: data.content,
          category: data.aiFactCategory,
        );
      },
      error: (err, stack) => SomethingWentWrong(
        title: 'Failed to load weird fact',
        onRetryPressed: () {
          ref.invalidate(fetchWeirdFactWednesdayProvider);
        },
      ),
      loading: () => const NeumorphicNotificationFactCardSkeleton(),
    );
  }
}
