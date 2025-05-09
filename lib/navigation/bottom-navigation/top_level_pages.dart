import 'package:flutter/material.dart';

import '../../screens/tab_screens/authors_screen.dart';
import '../../screens/tab_screens/favorites_screen.dart';
import '../../screens/tab_screens/facts_screen.dart';
import '../../screens/tab_screens/home_screen.dart';
import '../../screens/tab_screens/settings_screen.dart';

/// Top Level Pages
const List<Widget> kTopLevelPages = [
  HomeScreen(),
  FavoritesScreen(),
  AuthorsScreen(),
  FactsScreen(),
  SettingsScreen(),
];
