import 'package:flutter/material.dart';

import '../../dtos/quote_dto.dart';
import '../../main.dart';
import '../../screens/tab_screens/favorites_screen.dart';
import '../../services/drift_quote_service.dart';
import '../home_screen/home_screen_grid_view/home_screen_quote_grid_view.dart';
import '../home_screen/home_screen_list_view/home_screen_quote_list_view.dart';

class QuoteList extends StatefulWidget {
  const QuoteList({super.key});

  @override
  State<QuoteList> createState() => _QuoteListState();
}

class _QuoteListState extends State<QuoteList> {
  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).iconTheme.color;
    final isGridView = MyApp.of(context).isGridView;
    return Column(
      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: MediaQuery.sizeOf(context).height * 0.05,
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Favorite Quotes',
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
        ),
        Expanded(
          child: StreamBuilder(
            stream: DriftQuoteService.watchAllFavoriteQuotes([]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return isGridView
                    ? const FavoritesScreenSkeletor(
                        widget: HomeScreenQuoteGridViewSkeletor(),
                      )
                    : const FavoritesScreenSkeletor(
                        widget: HomeScreenQuoteListViewSkeletor(),
                      );
              }
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('Something Went Wrong'),
                  ),
                );
              }
              final quotes = snapshot.data!;
              if (quotes.isEmpty) {
                return SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.8,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hourglass_empty_outlined,
                          size: 80,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'No Favorites added yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'When you like a quote, it\'s going to show up here, this section helps you to read your Favorite quotes over and over',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: isGridView
                        ? HomeScreenQuoteGridView(
                            quotes: QuoteDto.fromQuoteList(quotes),
                            quotePageNumber: 1,
                            onLastItemScrolled: () {
                              return Future.value();
                            },
                          )
                        : HomeScreenQuoteListView(
                            quotes: QuoteDto.fromQuoteList(quotes),
                            // quotePageNumber: 1,
                            onLastItemScrolled: () {
                              return Future.value();
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
