import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/components/shared/top_navigation_bar.dart';
import 'package:quotely_flutter_app/services/isar_service.dart';

import '../../components/home_screen/home_screen_grid_view/home_screen_quote_grid_view.dart';
import '../../components/home_screen/home_screen_list_view/home_screen_quote_list_view.dart';
import '../../main.dart';

class FavouritesScreen extends StatefulWidget {
  static const kRouteName = '/favourites';
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  @override
  void initState() {
    super.initState();
    final changed = IsarService().watchAllFavouriteQuotes(([]));
    changed.listen((value) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final iconColor = Theme.of(context).iconTheme.color;
    final isGridView = MyApp.of(context).isGridView;
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
                future: IsarService().getAllFavouriteQuotes([]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return isGridView
                        ? const FavoutiesScreenSkeletor(
                            widget: HomeScreenQuoteGridViewSkeltor(),
                          )
                        : const FavoutiesScreenSkeletor(
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
                              'No Favourites added yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'When you like a quote, it\'s going to show up here, this section helps you to read your favourite quotes over and over',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Favourite Quotes',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(
                                  () =>
                                      MyApp.of(context).toggleGridViewEnabled(),
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
                                  () =>
                                      MyApp.of(context).toggleGridViewEnabled(),
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
                      Expanded(
                        child: isGridView
                            ? HomeScreenQuoteGridView(
                                quotes: quotes,
                                quotePageNumber: 1,
                                onLastItemScrolled: () {
                                  return Future.value();
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

class FavoutiesScreenSkeletor extends StatelessWidget {
  final Widget widget;

  const FavoutiesScreenSkeletor({
    super.key,
    required this.widget,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All Favourite Quotes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.view_agenda_outlined,
                  color:
                      isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
                const SizedBox(width: 10),
                Icon(
                  Icons.crop_square,
                  size: 28,
                  color:
                      isDarkTheme ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
        Expanded(child: widget),
      ],
    );
  }
}
