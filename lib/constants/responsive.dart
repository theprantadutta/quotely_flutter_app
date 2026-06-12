import 'package:flutter/widgets.dart';

/// Apple "readable content width" cap. Content is laid out in a column no
/// wider than this and centered, so portrait iPads show the gradient at the
/// sides instead of stretched cards. Wider than every iPhone portrait width,
/// so all helpers below are no-ops on phones.
const double kMaxContentWidth = 600.0;

/// True on iPad / large tablets (standard shortest-side breakpoint).
bool isTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= 600;

/// Replacement for `MediaQuery...width * factor` so width-derived sizes
/// can't explode on tablets. Identical to the raw math on phones.
double cappedWidth(BuildContext context, double factor) =>
    (MediaQuery.sizeOf(context).width * factor).clamp(0.0, kMaxContentWidth);

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
