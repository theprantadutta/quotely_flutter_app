import 'package:flutter/widgets.dart';

/// Apple "readable content width" cap. Content is laid out in a column no
/// wider than this and centered, so portrait iPads show the gradient at the
/// sides instead of stretched cards. Wider than every iPhone portrait width,
/// so all helpers below are no-ops on phones.
const double kMaxContentWidth = 600.0;

/// Wider cap for the tab shell on tablets: gives the feed room for the
/// [kMaxFeedCardWidth] card and Authors/Settings a roomier canvas, while
/// still leaving full-bleed gradient at the sides of a 13" iPad.
const double kMaxShellWidth = 840.0;

/// Feed card caps on tablets — one beautifully-proportioned centered card
/// instead of a 600-wide near-full-height stretched one.
const double kMaxFeedCardWidth = 700.0;
const double kMaxFeedCardHeight = 750.0;

/// Dialog width cap (mirrors the report dialogs' proven maxWidth).
const double kMaxDialogWidth = 500.0;

/// Fixed chrome sizes, replacing `screen height * factor` fractions that
/// ballooned on tall tablets and shrank in landscape.
const double kTopBarHeight = 52.0; // was height * 0.06
const double kSeeAllButtonHeight = 46.0; // was height * 0.05
const double kFilterChipRowHeight = 36.0; // was height * 0.038

/// True on iPad / large tablets (standard shortest-side breakpoint).
bool isTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

/// True on a tablet held (or resized to) landscape — short and wide.
bool isTabletLandscape(BuildContext context) =>
    isTablet(context) &&
    MediaQuery.orientationOf(context) == Orientation.landscape;

/// Replacement for `MediaQuery...width * factor` so width-derived sizes
/// can't explode on tablets. Identical to the raw math on phones.
double cappedWidth(BuildContext context, double factor) =>
    (MediaQuery.sizeOf(context).width * factor).clamp(0.0, kMaxContentWidth);

/// Height analog of [cappedWidth]: raw math on phones, clamped to [max] on
/// tall tablets so height-derived sizes can't balloon.
double cappedHeight(
  BuildContext context,
  double factor, {
  double max = kMaxFeedCardHeight,
}) => (MediaQuery.sizeOf(context).height * factor).clamp(0.0, max);

/// Adaptive horizontal gutter: 16 phone, 24 tablet portrait, 32 landscape.
double contentGutter(BuildContext context) {
  if (!isTablet(context)) return 16;
  return isTabletLandscape(context) ? 32 : 24;
}

/// Centers [child] inside a column no wider than [maxWidth]. On phones the
/// screen is already narrower than [maxWidth], so layout is unchanged.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = kMaxContentWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Two-axis sibling of [ResponsiveCenter]: centers [child] inside a box no
/// larger than [maxWidth] x [maxHeight]. Used by the feed carousel pages,
/// their skeletons and the "of the day" cards so the real card and its
/// loading state always share sizing from one place. No-op on phones, where
/// the incoming constraints are already tighter than the caps.
class ResponsiveCardBox extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final double maxHeight;

  const ResponsiveCardBox({
    super.key,
    required this.child,
    this.maxWidth = kMaxFeedCardWidth,
    this.maxHeight = kMaxFeedCardHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: child,
      ),
    );
  }
}
