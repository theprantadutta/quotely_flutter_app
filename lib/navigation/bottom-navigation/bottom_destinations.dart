import 'package:flutter/material.dart';

/// The five tabs, in branch order.
class TabDestination {
  final String label;
  final String tooltip;

  /// Shown above the label on tablets only; phones are text-only per design.
  final IconData icon;

  const TabDestination(this.label, this.tooltip, this.icon);
}

const kTabDestinations = <TabDestination>[
  TabDestination('Today', 'Today’s thread', Icons.chat_bubble_outline_rounded),
  TabDestination('Scenes', 'Lines from screen', Icons.movie_outlined),
  TabDestination('Saved', 'Saved things', Icons.favorite_border_rounded),
  TabDestination(
    'People',
    'Authors and characters',
    Icons.people_outline_rounded,
  ),
  TabDestination('Facts', 'True or false', Icons.lightbulb_outline_rounded),
];
