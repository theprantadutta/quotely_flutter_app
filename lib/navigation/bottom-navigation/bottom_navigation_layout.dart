import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/constants/responsive.dart';
import 'package:quotely_flutter_app/constants/selectors.dart';
import 'package:quotely_flutter_app/navigation/bottom-navigation/bottom_destinations.dart';

class BottomNavigationLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavigationLayout({super.key, required this.navigationShell});

  // This function handles tapping on the navigation bar items.
  // It tells go_router to switch to the correct branch (tab).
  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      // If the user taps the tab they are already on, go to the initial location
      // of that tab's navigation stack.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final kPrimaryColor = Theme.of(context).primaryColor;
    final tablet = isTablet(context);

    // Gradient container stays full-bleed; tab content is capped to a
    // readable width and centered. Tablets get the wider shell cap so the
    // feed card has room to breathe.
    final content = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimaryColor.withValues(alpha: 0.12), // Soft start
            kPrimaryColor.withValues(alpha: 0.06), // Lighter end
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: ResponsiveCenter(
        maxWidth: tablet ? kMaxShellWidth : kMaxContentWidth,
        child: navigationShell,
      ),
    );

    // Using PopScope is the modern way to handle back button presses.
    // canPop is false, so we can show a custom dialog before exiting.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop =
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit App?'),
                content: const Text('Are you sure you want to close Quotely?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            ) ??
            false;

        if (shouldPop && context.mounted) {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      },
      child: Scaffold(
        body: AnnotatedRegion(
          value: getDefaultSystemUiStyle(isDarkTheme),
          child: tablet
              ? Row(
                  children: [
                    _buildRail(context, kPrimaryColor),
                    Expanded(child: content),
                  ],
                )
              : content,
        ),
        bottomNavigationBar: tablet ? null : _buildBar(context, kPrimaryColor),
      ),
    );
  }

  /// Tablet navigation: a side rail with the same gradient identity as the
  /// phone bottom bar (shadow cast to the right instead of upward).
  Widget _buildRail(BuildContext context, Color kPrimaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: kGetDefaultGradient(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: NavigationRailTheme(
          data: NavigationRailThemeData(
            selectedIconTheme: const IconThemeData(color: Colors.white),
            selectedLabelTextStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kPrimaryColor,
            ),
            unselectedLabelTextStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: NavigationRail(
            backgroundColor: Colors.transparent,
            labelType: NavigationRailLabelType.all,
            groupAlignment: 0.0,
            indicatorColor: kPrimaryColor.withAlpha(230),
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            destinations: buildRailDestinations(),
          ),
        ),
      ),
    );
  }

  /// Phone navigation: the Material 3 bottom bar, unchanged.
  Widget _buildBar(BuildContext context, Color kPrimaryColor) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
          (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? const IconThemeData(color: Colors.white)
              : const IconThemeData(),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: kGetDefaultGradient(context),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: NavigationBar(
          // 1. Make the NavigationBar's own background transparent
          backgroundColor: Colors.transparent,
          // 2. Remove the default shadow to use your custom one from the Container
          elevation: 0,
          onDestinationSelected: _onTap,
          selectedIndex: navigationShell.currentIndex,
          indicatorColor: kPrimaryColor.withAlpha(230),
          destinations: buildBarDestinations(),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final style = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
            if (states.contains(WidgetState.selected)) {
              return style.copyWith(
                color: kPrimaryColor,
                fontWeight: FontWeight.w700,
              );
            }
            return style;
          }),
        ),
      ),
    );
  }
}
