import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

import '../../dtos/quote_dto.dart';
import '../../main.dart';
import '../../screens/tab_screens/favorites_screen.dart';
import '../../service_locator/init_service_locators.dart';
import '../../services/drift_quote_service.dart';
import '../home_screen/home_screen_grid_view/home_screen_quote_grid_view.dart';
import '../home_screen/home_screen_list_view/home_screen_quote_list_view.dart';

class QuoteList extends StatefulWidget {
  const QuoteList({super.key});

  @override
  State<QuoteList> createState() => _QuoteListState();
}

class _QuoteListState extends State<QuoteList> {
  // Assuming getIt is available for service location
  final _analytics = getIt.get<FirebaseAnalytics>();

  // --- UX & Analytics Improvement ---
  // This function now explicitly sets the view mode and logs the corresponding event.
  void _setViewMode(bool isGridView) {
    final quotelyApp = QuotelyApp.of(context);
    // Only toggle if the view is actually changing
    if (quotelyApp.isGridView != isGridView) {
      quotelyApp.toggleGridViewEnabled();

      // Log a specific event for this screen
      _analytics.logEvent(
        name: 'favorites_quotes_view_changed',
        parameters: {'view_mode': isGridView ? 'grid' : 'list'},
      );
      // Rebuild the widget to reflect the change
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).iconTheme.color;
    final isGridView = QuotelyApp.of(context).isGridView;
    return Column(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.05,
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Favorite Quotes',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Row(
                children: [
                  // --- Improved list view button ---
                  GestureDetector(
                    onTap: () => _setViewMode(false), // Set to list view
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
                  // --- Improved grid view button ---
                  GestureDetector(
                    onTap: () => _setViewMode(true), // Set to grid view
                    child: Icon(
                      Icons
                          .grid_view_rounded, // Using a more distinct grid icon
                      size: 24, // Adjusted size to match the other icon better
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
                // --- Analytics Event for Errors ---
                _analytics.logEvent(
                  name: 'favorites_quotes_load_failed',
                  parameters: {'error': snapshot.error.toString()},
                );
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Something Went Wrong')),
                );
              }
              final quotes = snapshot.data!;
              if (quotes.isEmpty) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_empty_outlined, size: 80),
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
                          style: TextStyle(fontSize: 15),
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
