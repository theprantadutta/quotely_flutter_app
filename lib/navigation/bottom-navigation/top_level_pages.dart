import 'package:flutter/material.dart';

import '../../screens/tab_screens/favourites_screen.dart';
import '../../screens/tab_screens/home_screen.dart';
import '../../screens/tab_screens/quote_of_the_day_screen.dart';
import '../../screens/tab_screens/settings_screen.dart';

/// Top Level Pages
const List<Widget> kTopLevelPages = [
  HomeScreen(),
  FavouritesScreen(),
  QuoteOfTheDayScreen(),
  SettingsScreen(),
];
