import 'package:flutter/material.dart';

import '../../constants/notification_types.dart';
import '../settings_screen/notifications/switch_settings_layout.dart';

/// The two grouped sections of notification toggles (Quotes / Facts), driven by
/// [kNotificationTypes] so the onboarding screen and the Settings →
/// Notifications screen always show the exact same set, in the same style.
///
/// [values] maps each [NotificationType.prefKey] to its current on/off state.
/// [onChanged] fires with the toggled type and its new value. [enabled] dims
/// and disables the toggles (used by Settings when the master switch is off).
class NotificationTogglesSection extends StatelessWidget {
  final Map<String, bool> values;
  final void Function(NotificationType type, bool value) onChanged;
  final bool enabled;

  const NotificationTogglesSection({
    super.key,
    required this.values,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _group(context, 'Quote Notifications', NotificationGroup.quote),
        const SizedBox(height: 32),
        _group(context, 'Fact Notifications', NotificationGroup.fact),
      ],
    );
  }

  Widget _group(BuildContext context, String title, NotificationGroup group) {
    final types = notificationTypesIn(group);
    final rows = <Widget>[];
    for (var i = 0; i < types.length; i++) {
      final type = types[i];
      if (i > 0) {
        rows.add(const Divider(height: 1, indent: 20, endIndent: 20));
      }
      rows.add(
        SwitchSettingsLayout(
          title: type.title,
          value: values[type.prefKey] ?? true,
          onSwitchChanged: (value) => onChanged(type, value),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, title),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: !enabled,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: _sectionContainer(context, rows),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _sectionContainer(BuildContext context, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      // Transparent Material above the container's colour so the tile ink
      // ripple is visible.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: children),
        ),
      ),
    );
  }
}
