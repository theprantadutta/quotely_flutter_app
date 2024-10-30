import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/navigation/bottom-navigation/awesome_bottom_bar/awesome_bottom_bar_fancy.dart';

import '../../constants/selectors.dart';
import 'awesome_bottom_bar/top_level_page_view.dart';
import 'top_level_pages.dart';

class BottomNavigationLayout extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavigationLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  State<BottomNavigationLayout> createState() => _BottomNavigationLayoutState();

  // ignore: library_private_types_in_public_api
  static _BottomNavigationLayoutState of(BuildContext context) =>
      context.findAncestorStateOfType<_BottomNavigationLayoutState>()!;
}

class _BottomNavigationLayoutState extends State<BottomNavigationLayout> {
  int selectedIndex = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: selectedIndex,
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _updateCurrentPageIndex(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _handlePageViewChanged(int currentPageIndex) {
    setState(() {
      selectedIndex = currentPageIndex;
    });
  }

  gotoPage(int index) {
    if (index < kTopLevelPages.length && index >= 0) {
      _updateCurrentPageIndex(index);
      // _handleIconPress(index);
    }
  }

  gotoNextPage() {
    if (selectedIndex != kTopLevelPages.length - 1) {
      _updateCurrentPageIndex(selectedIndex + 1);
      // _handleIconPress(selectedIndex + 1);
    }
  }

  gotoPreviousPage() {
    if (selectedIndex != 0) {
      _updateCurrentPageIndex(selectedIndex - 1);
      // _handleIconPress(selectedIndex - 1);
    }
  }

  Future<bool> _onWillPop(BuildContext context) async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit the app?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () =>
                    // Exit the app
                    SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
                // FlutterExitApp.exitApp(),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        true;
  }

  Future<bool> _onBackButtonPressed() async {
    debugPrint('Back button Pressed');
    if (selectedIndex == 0) {
      // Exit the app
      debugPrint('Existing the app as we are on top level page');
      return await _onWillPop(context);
    } else {
      // Go back
      debugPrint('Going back to previous page');
      gotoPreviousPage();
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final kPrimaryColor = Theme.of(context).primaryColor;
    return BackButtonListener(
      onBackButtonPressed: _onBackButtonPressed,
      child: Scaffold(
        extendBodyBehindAppBar: false,
        resizeToAvoidBottomInset: false,
        body: AnnotatedRegion(
          value: getDefaultSystemUiStyle(isDarkTheme),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kPrimaryColor.withOpacity(0.12), // Soft start
                  kPrimaryColor.withOpacity(0.06), // Lighter end
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: TopLevelPageView(
              pageController: pageController,
              onPageChanged: _handlePageViewChanged,
            ),
          ),
        ),
        extendBody: false,
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        bottomNavigationBar: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: kPrimaryColor.withOpacity(0.1),
            primaryColor: kPrimaryColor,
            // fontFamily: GoogleFonts.ubuntu().fontFamily,
          ),
          child: FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kPrimaryColor.withOpacity(0.15), // Soft start
                    kPrimaryColor.withOpacity(0.1), // Light middle
                    kPrimaryColor.withOpacity(0.05), // Very subtle end
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                // borderRadius: const BorderRadius.only(
                //   topLeft: Radius.circular(15),
                //   topRight: Radius.circular(15),
                // ),
              ),
              child: AwesomeBottomBarFancy(
                selectedIndex: selectedIndex,
                updateCurrentPageIndex: _updateCurrentPageIndex,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
