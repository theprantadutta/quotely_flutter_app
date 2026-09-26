import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../components/thread/thread.dart';
import '../../constants/responsive.dart';
import 'bottom_destinations.dart';

/// Tab shell: the current branch above a text-only bottom nav.
class BottomNavigationLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const BottomNavigationLayout({super.key, required this.navigationShell});

  void _onTap(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      // Re-tapping the current tab returns to that tab's root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    return await showQSheet<bool>(
          context,
          builder: (sheet) => QSheetFrame(
            title: 'Leave Quotely?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Your thread will be here when you come back.',
                  style: sheet.qt.body,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: 'Stay',
                        onPressed: () => Navigator.of(sheet).pop(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Leave',
                        height: 52,
                        onPressed: () => Navigator.of(sheet).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // Back on a non-Today tab goes to Today first, like most apps.
        if (navigationShell.currentIndex != 0) {
          _onTap(0);
          return;
        }
        if (await _confirmExit(context)) {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      },
      child: Scaffold(
        backgroundColor: context.q.bg,
        body: navigationShell,
        bottomNavigationBar: ThreadBottomNav(
          currentIndex: navigationShell.currentIndex,
          onTap: _onTap,
        ),
      ),
    );
  }
}

/// Five plain text tabs over a hairline: the active one is ink with a small
/// dot beneath it that slides between items. No pill, no elevation.
class ThreadBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ThreadBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final showIcons = isTablet(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slot = constraints.maxWidth / kTabDestinations.length;
                  final height = showIcons ? 56.0 : 44.0;
                  return SizedBox(
                    height: height,
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: context.reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          left: slot * currentIndex + slot / 2 - 2,
                          width: 4,
                          height: 4,
                          bottom: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: t.acc,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < kTabDestinations.length; i++)
                              Expanded(
                                child: _NavItem(
                                  destination: kTabDestinations[i],
                                  selected: i == currentIndex,
                                  showIcon: showIcons,
                                  onTap: () => onTap(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final TabDestination destination;
  final bool selected;
  final bool showIcon;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.selected,
    required this.showIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final color = selected ? t.ink : t.mute;
    return Tooltip(
      message: destination.tooltip,
      excludeFromSemantics: true,
      child: Semantics(
        selected: selected,
        button: true,
        label: '${destination.label} tab',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showIcon) ...[
                  Icon(destination.icon, size: 20, color: color),
                  const SizedBox(height: 2),
                ],
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: context.qt.label.copyWith(
                    fontSize: 13.5,
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
