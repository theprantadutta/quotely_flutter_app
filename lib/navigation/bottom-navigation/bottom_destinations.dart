import 'package:flutter/material.dart';

/// Plain data for the five tab destinations, so the same source can build
/// both the phone [NavigationBar] and the tablet [NavigationRail].
class TabDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const TabDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

const kTabDestinations = <TabDestination>[
  TabDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Home',
  ),
  TabDestination(icon: Icons.favorite_outline, label: 'Favorites'),
  TabDestination(icon: Icons.person_2_outlined, label: 'Authors'),
  TabDestination(icon: Icons.fact_check_outlined, label: 'Facts'),
  TabDestination(icon: Icons.settings_outlined, label: 'Settings'),
];

List<NavigationDestination> buildBarDestinations() => [
  for (final d in kTabDestinations)
    NavigationDestination(
      icon: Icon(d.icon),
      selectedIcon: d.selectedIcon != null ? Icon(d.selectedIcon) : null,
      label: d.label,
    ),
];

List<NavigationRailDestination> buildRailDestinations() => [
  for (final d in kTabDestinations)
    NavigationRailDestination(
      icon: Icon(d.icon),
      selectedIcon: d.selectedIcon != null ? Icon(d.selectedIcon) : null,
      label: Text(d.label),
    ),
];
