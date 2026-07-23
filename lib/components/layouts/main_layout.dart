import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../constants/colors.dart';
import '../../constants/responsive.dart';

class MainLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final PreferredSizeWidget? bottom;

  /// When false the body gets the full (bounded) viewport height instead of a
  /// scroll view — for screens whose content is a carousel/Expanded layout
  /// that must derive its size from real constraints, not screen fractions.
  final bool scrollable;

  /// Content width cap. Screens with side-by-side tablet layouts pass
  /// [kMaxShellWidth] for a wider canvas.
  final double maxWidth;

  const MainLayout({
    super.key,
    required this.body,
    required this.title,
    this.bottom,
    this.scrollable = true,
    this.maxWidth = kMaxContentWidth,
  });

  Future<bool> _onBackButtonPressed(BuildContext context) async {
    if (context.canPop()) context.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return BackButtonListener(
      onBackButtonPressed: () => _onBackButtonPressed(context),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: kPrimaryColor.withValues(
            alpha: isDarkTheme ? 0.6 : 0.9,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: MainLayoutAppBar(title: title),
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white, weight: 20),
          ),
          bottom: bottom,
        ),
        // The gradient always covers the whole viewport (it used to live
        // inside the scroll view sized to 90% of screen height, so it could
        // run out under tall content or landscape). Content is capped to a
        // readable width and centered on tablets.
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.1, 0.9],
              colors: [
                kPrimaryColor.withValues(alpha: 0.05),
                kHelperColor.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: scrollable
              ? SingleChildScrollView(
                  child: ResponsiveCenter(maxWidth: maxWidth, child: body),
                )
              : SafeArea(
                  child: ResponsiveCenter(maxWidth: maxWidth, child: body),
                ),
        ),
        // Theme is toggled from Settings → Appearance; the floating debug
        // toggle is disabled everywhere.
        floatingActionButton: null,
      ),
    );
  }
}

class MainLayoutAppBar extends StatelessWidget {
  final String title;

  const MainLayoutAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}
