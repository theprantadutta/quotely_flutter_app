import 'package:flutter/material.dart';

import '../../components/home_screen/home_screen_quote_filters.dart';
import '../../components/home_screen/home_screen_quote_grid_view.dart';
import '../../components/home_screen/home_screen_quote_list_view.dart';
import '../../components/home_screen/home_screen_top_bar.dart';

class HomeScreen extends StatefulWidget {
  static const kRouteName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isGridView = true;

  @override
  Widget build(BuildContext context) {
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
            HomeScreenQuoteFilters(),
            isGridView ? HomeScreenQuoteGridView() : HomeScreenQuoteListView(),
          ],
        ),
      ),
    );
  }
}
