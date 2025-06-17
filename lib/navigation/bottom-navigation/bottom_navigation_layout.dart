// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:go_router/go_router.dart';
// import 'package:quotely_flutter_app/navigation/bottom-navigation/bottom_destinations.dart';

// import '../../constants/selectors.dart';
// import 'awesome_bottom_bar/top_level_page_view.dart';
// import 'top_level_pages.dart';

// class BottomNavigationLayout extends StatefulWidget {
//   final StatefulNavigationShell navigationShell;

//   const BottomNavigationLayout({
//     super.key,
//     required this.navigationShell,
//   });

//   @override
//   State<BottomNavigationLayout> createState() => _BottomNavigationLayoutState();

//   // ignore: library_private_types_in_public_api
//   static _BottomNavigationLayoutState of(BuildContext context) =>
//       context.findAncestorStateOfType<_BottomNavigationLayoutState>()!;
// }

// class _BottomNavigationLayoutState extends State<BottomNavigationLayout> {
//   int selectedIndex = 0;
//   late PageController pageController;

//   @override
//   void initState() {
//     super.initState();
//     pageController = PageController(
//       initialPage: selectedIndex,
//     );
//   }

//   @override
//   void dispose() {
//     pageController.dispose();
//     super.dispose();
//   }

//   void _updateCurrentPageIndex(int index) {
//     setState(() {
//       selectedIndex = index;
//     });
//     pageController.animateToPage(
//       index,
//       duration: const Duration(milliseconds: 400),
//       curve: Curves.easeInOut,
//     );
//   }

//   // void _handlePageViewChanged(int currentPageIndex) {
//   //   setState(() {
//   //     selectedIndex = currentPageIndex;
//   //   });
//   // }

//   gotoPage(int index) {
//     if (index < kTopLevelPages.length && index >= 0) {
//       _updateCurrentPageIndex(index);
//       // _handleIconPress(index);
//     }
//   }

//   gotoNextPage() {
//     if (selectedIndex != kTopLevelPages.length - 1) {
//       _updateCurrentPageIndex(selectedIndex + 1);
//       // _handleIconPress(selectedIndex + 1);
//     }
//   }

//   gotoPreviousPage() {
//     if (selectedIndex != 0) {
//       _updateCurrentPageIndex(selectedIndex - 1);
//       // _handleIconPress(selectedIndex - 1);
//     }
//   }

//   Future<bool> _onWillPop(BuildContext context) async {
//     return (await showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Are you sure?'),
//             content: const Text('Do you want to exit the app?'),
//             actions: <Widget>[
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 child: const Text('No'),
//               ),
//               TextButton(
//                 onPressed: () =>
//                     // Exit the app
//                     SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
//                 // FlutterExitApp.exitApp(),
//                 child: const Text('Yes'),
//               ),
//             ],
//           ),
//         )) ??
//         true;
//   }

//   Future<bool> _onBackButtonPressed() async {
//     debugPrint('Back button Pressed');
//     if (selectedIndex == 0) {
//       // Exit the app
//       debugPrint('Existing the app as we are on top level page');
//       return await _onWillPop(context);
//     } else {
//       // Go back
//       debugPrint('Going back to previous page');
//       gotoPreviousPage();
//       return true;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
//     final kPrimaryColor = Theme.of(context).primaryColor;
//     return BackButtonListener(
//       onBackButtonPressed: _onBackButtonPressed,
//       child: Scaffold(
//         extendBodyBehindAppBar: false,
//         resizeToAvoidBottomInset: false,
//         body: AnnotatedRegion(
//           value: getDefaultSystemUiStyle(isDarkTheme),
//           child: Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//                 colors: [
//                   kPrimaryColor.withValues(alpha: 0.12), // Soft start
//                   kPrimaryColor.withValues(alpha: 0.06), // Lighter end
//                 ],
//                 stops: const [0.0, 1.0],
//               ),
//             ),
//             child: TopLevelPageView(
//               pageController: pageController,
//               onPageChanged: _updateCurrentPageIndex,
//             ),
//           ),
//         ),
//         extendBody: false,
//         bottomNavigationBar: NavigationBarTheme(
//           data: NavigationBarThemeData(
//             labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
//               (Set<WidgetState> states) => states.contains(WidgetState.selected)
//                   ? TextStyle(
//                       color: kPrimaryColor,
//                       fontWeight: FontWeight.w700,
//                       fontSize: 13,
//                     )
//                   : const TextStyle(
//                       fontSize: 13,
//                     ),
//             ),
//             iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
//               (Set<WidgetState> states) => states.contains(WidgetState.selected)
//                   ? const IconThemeData(
//                       color: Colors.white,
//                     )
//                   : const IconThemeData(),
//             ),
//           ),
//           child: NavigationBar(
//             onDestinationSelected: _updateCurrentPageIndex,
//             indicatorColor: kPrimaryColor.withValues(alpha: 0.9),
//             surfaceTintColor: kPrimaryColor,
//             selectedIndex: selectedIndex,
//             destinations: kBottomDestinations,
//             labelTextStyle: WidgetStateTextStyle.resolveWith(
//               (states) {
//                 return states.contains(WidgetState.selected)
//                     ? TextStyle(
//                         color: kPrimaryColor,
//                         fontWeight: FontWeight.w700,
//                         fontSize: 12,
//                       )
//                     : TextStyle(
//                         fontSize: 12,
//                       );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/constants/selectors.dart';
import 'package:quotely_flutter_app/navigation/bottom-navigation/bottom_destinations.dart';

class BottomNavigationLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavigationLayout({
    super.key,
    required this.navigationShell,
  });

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

    // Using PopScope is the modern way to handle back button presses.
    // canPop is false, so we can show a custom dialog before exiting.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await showDialog(
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
          child: Container(
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
            child: navigationShell,
          ),
        ),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
              (Set<WidgetState> states) => states.contains(WidgetState.selected)
                  ? const IconThemeData(
                      color: Colors.white,
                    )
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
              destinations: kBottomDestinations,
              labelTextStyle: WidgetStateProperty.resolveWith(
                (states) {
                  final style =
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
                  if (states.contains(WidgetState.selected)) {
                    return style.copyWith(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w700,
                    );
                  }
                  return style;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
