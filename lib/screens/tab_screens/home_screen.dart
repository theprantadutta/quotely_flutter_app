import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/riverpods/all_quote_data_provider.dart';

import '../../components/home_screen/home_screen_grid_view/home_screen_quote_grid_view.dart';
import '../../components/home_screen/home_screen_list_view/home_screen_quote_list_view.dart';
import '../../components/home_screen/home_screen_quote_filters.dart';
import '../../components/home_screen/home_screen_top_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const kRouteName = '/home';
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isGridView = true;

  @override
  Widget build(BuildContext context) {
    final allQuoteProvider = ref.watch(fetchAllQuotesProvider(1, 10));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 15,
        ),
        child: Column(
          children: [
            HomeScreenTopBar(
              isGridView: isGridView,
              onViewChanged: () => setState(
                () => isGridView = !isGridView,
              ),
            ),
            const HomeScreenQuoteFilters(),
            isGridView
                ? allQuoteProvider.when(
                    data: (data) => HomeScreenQuoteGridView(
                      quotes: data.quotes,
                    ),
                    error: (err, stack) => const Center(
                      child: Text('Something Went Wrong'),
                    ),
                    loading: () => const HomeScreenQuoteGridViewSkeltor(),
                  )
                : allQuoteProvider.when(
                    data: (data) => HomeScreenQuoteListView(
                      quotes: data.quotes,
                    ),
                    error: (err, stack) => const Center(
                      child: Text('Something Went Wrong'),
                    ),
                    loading: () => const HomeScreenQuoteListViewSkeletor(),
                  )
          ],
        ),
      ),
    );
  }
}
