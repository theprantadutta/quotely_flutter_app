import 'package:flutter/material.dart';

const kBottomDestinations = <Widget>[
  NavigationDestination(
    selectedIcon: Icon(Icons.home),
    icon: Icon(Icons.home_outlined),
    label: 'Home',
  ),
  NavigationDestination(
    icon: Icon(Icons.favorite_outline),
    label: 'Favorites',
  ),
  NavigationDestination(
    icon: Icon(Icons.person_2_outlined),
    label: 'Authors',
  ),
  NavigationDestination(
    icon: Icon(Icons.settings_outlined),
    label: 'Settings',
  ),
];
