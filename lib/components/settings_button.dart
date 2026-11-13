import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../navigation/routes.dart';
import 'thread/thread.dart';

/// The way to Settings (appearance, notifications, widgets, the offline
/// library, feedback, support, and the streak at the top) from every tab: a
/// gear drawn like the search button beside it. It sits at the right end of
/// each tab's header; use this one widget everywhere so the tabs can't drift.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  /// Read by screen readers; tests find the button by it.
  static const semanticLabel = 'Settings';

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      icon: Icons.settings_outlined,
      semanticLabel: semanticLabel,
      onTap: () => context.push(Routes.you),
    );
  }
}
