import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/components/shared/something_went_wrong.dart';
import 'package:quotely_flutter_app/riverpods/all_quote_data_provider.dart';

import '../../components/home_screen/home_screen_grid_view/home_screen_quote_grid_view.dart';
import '../../components/home_screen/home_screen_list_view/home_screen_quote_list_view.dart';
import '../../components/home_screen/home_screen_quote_filters.dart';
import '../../components/home_screen/home_screen_top_bar.dart';
import '../../dtos/quote_dto.dart';
import '../../main.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const kRouteName = '/home';
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int quotePageNumber = 1;
  bool hasMoreData = true;
  bool hasError = false;
  bool isLoadingMore = false;
  List<QuoteDto> quotes = [];

  List<String> allSelectedTags = [];

  @override
  void initState() {
    super.initState();
    _fetchQuotes();
  }

  Future<void> _fetchQuotes() async {
    debugPrint('Fetching Quotes...');
    if (!hasMoreData || isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
      hasError = false;
    });

    try {
      final newQuotes = await ref.read(fetchAllQuotesProvider(
        quotePageNumber,
        10,
        allSelectedTags,
      ).future);
      setState(() {
        hasMoreData = newQuotes.quotes.length == 10;
        quotePageNumber++;
        quotes.addAll(newQuotes.quotes);
        isLoadingMore = false;
      });
    } catch (e) {
      if (kDebugMode) print(e);
      if (mounted) {
        setState(() {
          hasError = true;
          isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGridView = MyApp.of(context).isGridView;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 10,
        ),
        child: Column(
          children: [
            HomeScreenTopBar(
              loading: isLoadingMore,
              isGridView: isGridView,
              onViewChanged: () {
                setState(MyApp.of(context).toggleGridViewEnabled);
              },
            ),
            // Display error message if there's an error
            if (hasError)
              Expanded(
                child: Center(
                  child: SomethingWentWrong(
                    title: 'Failed to get Quotes.',
                    onRetryPressed: _fetchQuotes,
                  ),
                ),
              ),
            HomeScreenQuoteFilters(
              allSelectedTags: allSelectedTags,
              onSelectedTagChange: (String currentTag) async {
                setState(() {
                  if (allSelectedTags.contains(currentTag)) {
                    // Remove the tag if it already exists
                    allSelectedTags.remove(currentTag);
                  } else {
                    // Add the tag if it does not exist
                    allSelectedTags.add(currentTag);
                  }
                  quotePageNumber = 1;
                  quotes = [];
                });

                ref.invalidate(fetchAllQuotesProvider);
                await _fetchQuotes();
              },
            ),
            // Display skeleton loaders when there’s no error and no data
            if (!hasError && quotes.isEmpty)
              isGridView
                  ? const HomeScreenQuoteGridViewSkeltor()
                  : const Expanded(child: HomeScreenQuoteListViewSkeletor()),

            // Display the main content if there are quotes available
            if (!hasError && quotes.isNotEmpty)
              Expanded(
                child: isGridView
                    ? HomeScreenQuoteGridView(
                        quotes: quotes,
                        quotePageNumber: quotePageNumber,
                        onLastItemScrolled: _fetchQuotes,
                      )
                    : HomeScreenQuoteListView(
                        quotes: quotes,
                        quotePageNumber: quotePageNumber,
                        onLastItemScrolled: _fetchQuotes,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
