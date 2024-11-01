import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../components/home_screen/home_screen_quote_single_filter.dart';
import '../../riverpods/all_tag_data_provider.dart';

class HomeScreenQuoteFilters extends ConsumerWidget {
  const HomeScreenQuoteFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsProvider = ref.watch(FetchAllTagsProvider(1, 10));
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      height: MediaQuery.sizeOf(context).height * 0.038,
      child: tagsProvider.when(
        data: (data) {
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: data.tags.length,
            itemBuilder: (context, index) => HomeScreenQuoteSingleFilter(
              index: index,
              title: data.tags[index].name,
            ),
          );
        },
        error: (err, stack) => const Center(
          child: Text('Something Went wrong'),
        ),
        loading: () => Skeletonizer(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemBuilder: (context, index) => HomeScreenQuoteSingleFilter(
              index: index,
              title: 'Index',
            ),
          ),
        ),
      ),
    );
  }
}
