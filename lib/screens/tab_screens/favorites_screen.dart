import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';

import '../../components/favorites_screen/facts_list.dart';
import '../../components/favorites_screen/quote_list.dart';
import '../../components/shared/top_navigation_bar.dart';

class FavoritesScreen extends StatefulWidget {
  static const kRouteName = '/favorites';
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // --- Analytics Instance ---
  // Fetched using your service locator
  final _analytics = getIt.get<FirebaseAnalytics>();

  bool showQuotes = true;
  // Note: Your AnimationController wasn't being used, so I've removed it
  // and the 'with SingleTickerProviderStateMixin' for a cleaner implementation.

  void _toggleView(bool displayQuotes) {
    // Prevent unnecessary state changes if the view is already active
    if (showQuotes == displayQuotes) return;

    setState(() {
      showQuotes = displayQuotes;
    });

    // --- Analytics Event ---
    // Log an event when the user switches views.
    final viewName = displayQuotes ? 'quotes' : 'facts';
    _analytics.logEvent(
      name: 'favorites_view_changed',
      parameters: {'view_name': viewName},
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          children: [
            const TopNavigationBar(title: 'Favorites'),
            _buildTabBar(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: showQuotes
                    ? QuoteList(key: const ValueKey('QuoteList'))
                    : FactsList(key: const ValueKey('FactsList')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
      child: Center(
        child: Container(
          width: 200,
          height: 35, // Slightly increased height for better touch target
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: showQuotes ? 0 : 100,
                child: Container(
                  width: 100,
                  height: 35,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _toggleView(true),
                      // Use a transparent container to make the whole area tappable
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: showQuotes
                                  ? onPrimaryColor
                                  : onSurfaceColor,
                              fontWeight: FontWeight.w600,
                            ),
                            child: const Text('Quotes'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _toggleView(false),
                      child: Container(
                        color: Colors.transparent,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              color: !showQuotes
                                  ? onPrimaryColor
                                  : onSurfaceColor,
                              fontWeight: FontWeight.w600,
                            ),
                            child: const Text('Facts'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// The FavoritesScreenSkeletor seems fine, it's a simple layout
// wrapper and doesn't require any analytics logging itself.
class FavoritesScreenSkeletor extends StatelessWidget {
  final Widget widget;

  const FavoritesScreenSkeletor({super.key, required this.widget});

  @override
  Widget build(BuildContext context) {
    return Column(children: [Expanded(child: widget)]);
  }
}
