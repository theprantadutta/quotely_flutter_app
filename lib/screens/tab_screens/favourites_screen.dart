import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/shared/top_navigation_bar.dart';
import 'package:quotely_flutter_app/services/isar_service.dart';

import '../../components/home_screen/home_screen_grid_view/home_screen_quote_grid_view.dart';
import '../../components/home_screen/home_screen_list_view/home_screen_quote_list_view.dart';
import '../../components/home_screen/home_screen_quote_filters.dart';

class FavouritesScreen extends StatefulWidget {
  static const kRouteName = '/favourites';
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  bool isGridView = true;
  List<String> allSelectedTags = [];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 10,
        ),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const TopNavigationBar(title: 'Favourites'),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.765,
              child: FutureBuilder(
                future: IsarService().getAllFavouriteQuotes(allSelectedTags),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return isGridView
                        ? const HomeScreenQuoteGridViewSkeltor()
                        : const HomeScreenQuoteListViewSkeletor();
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
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.hourglass_empty_outlined,
                            size: 60,
                          ),
                          SizedBox(width: 20),
                          Text('No Favourites added yet.'),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
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
                          });
                        },
                      ),
                      // Display the main content if there are quotes available
                      Expanded(
                        child: isGridView
                            ? ListView.builder(
                                itemCount: quotes.length,
                                itemBuilder: (context, index) {
                                  if (index < quotes.length) {
                                    return HomeScreenQuoteGridView(
                                      quotes: quotes,
                                      quotePageNumber: 1,
                                      onLastItemScrolled: () {
                                        return Future.value();
                                      },
                                    );
                                  } else {
                                    return const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                },
                              )
                            : HomeScreenQuoteListView(
                                quotes: quotes,
                                quotePageNumber: 1,
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
        ),
      ),
    );
  }
}
