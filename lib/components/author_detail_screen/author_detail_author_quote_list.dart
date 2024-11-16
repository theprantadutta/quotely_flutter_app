import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';
import 'package:quotely_flutter_app/main.dart';
import 'package:quotely_flutter_app/riverpods/all_quotes_by_author_provider.dart';

import '../../dtos/quote_dto.dart';
import '../home_screen/home_screen_grid_view/home_screen_quote_grid_view.dart';
import '../home_screen/home_screen_list_view/home_screen_quote_list_view.dart';
import '../shared/something_went_wrong.dart';

class AuthorDetailAuthorQuoteList extends ConsumerStatefulWidget {
  final AuthorDto author;

  const AuthorDetailAuthorQuoteList({super.key, required this.author});

  @override
  ConsumerState<AuthorDetailAuthorQuoteList> createState() =>
      _AuthorDetailAuthorQuoteListState();
}

class _AuthorDetailAuthorQuoteListState
    extends ConsumerState<AuthorDetailAuthorQuoteList> {
  int quotePageNumber = 1;
  bool hasMoreData = true;
  bool hasError = false;
  bool isLoadingMore = false;
  List<QuoteDto> quotes = [];

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
      final newQuotes = await ref.read(fetchAllQuotesByAuthorProvider(
        widget.author.slug,
        quotePageNumber,
        10,
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
    final isDarkTheme = MyApp.of(context).isDarkMode;
    final iconColor = Theme.of(context).iconTheme.color;
    return Column(
      children: [
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

        if (!hasError && !isLoadingMore && quotes.isEmpty)
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            width: MediaQuery.sizeOf(context).width * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.hourglass_empty_outlined,
                  size: 80,
                ),
                const SizedBox(height: 10),
                Text(
                  'No Quote Found by ${widget.author.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        // Display skeleton loaders when there’s no error and no data
        if (!hasError && isLoadingMore && quotes.isEmpty)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quotes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.view_agenda_outlined,
                        color: !isGridView
                            ? iconColor
                            : isDarkTheme
                                ? Colors.grey.shade700
                                : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.crop_square,
                        size: 28,
                        color: isGridView
                            ? iconColor
                            : isDarkTheme
                                ? Colors.grey.shade700
                                : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
              isGridView
                  ? const HomeScreenQuoteGridViewSkeltor()
                  : SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.7,
                      child: const HomeScreenQuoteListViewSkeletor(),
                    ),
            ],
          ),

        // Display the main content if there are quotes available
        if (!hasError && !isLoadingMore && quotes.isNotEmpty)
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quotes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(
                          () => MyApp.of(context).toggleGridViewEnabled(),
                        ),
                        child: Icon(
                          Icons.view_agenda_outlined,
                          color: !isGridView
                              ? iconColor
                              : isDarkTheme
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => setState(
                          () => MyApp.of(context).toggleGridViewEnabled(),
                        ),
                        child: Icon(
                          Icons.crop_square,
                          size: 28,
                          color: isGridView
                              ? iconColor
                              : isDarkTheme
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.67,
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
      ],
    );
  }
}
