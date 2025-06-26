import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/fact_of_the_day_screen/single_fact_of_the_day_component.dart';
import 'package:quotely_flutter_app/components/shared/something_went_wrong.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../riverpods/weird_fact_wednesday_provider.dart';

class WeirdFactWednesdayComponent extends ConsumerWidget {
  const WeirdFactWednesdayComponent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteOfTheDayProvider = ref.watch(fetchWeirdFactWednesdayProvider);

    return quoteOfTheDayProvider.when(
      data: (data) {
        return SingleFactOfTheDayComponent(
          factDate: data.factDate,
          content: data.content,
          category: data.aiFactCategory,
        );
      },
      error: (err, stack) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: SomethingWentWrong(
            onRetryPressed: () => ref.refresh(fetchWeirdFactWednesdayProvider),
          ),
        );
      },
      loading: () => const Skeletonizer(
        child: SingleFactOfTheDayComponentSkeletor(),
      ),
    );
  }
}
