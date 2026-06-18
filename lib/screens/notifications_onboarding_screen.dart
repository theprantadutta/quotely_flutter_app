import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/notifications_screen/notification_toggles_section.dart';
import '../constants/notification_keys.dart';
import '../constants/notification_types.dart';
import '../constants/responsive.dart';
import '../constants/shared_preference_keys.dart';
import '../notifications/push_notification.dart';
import '../services/notification_service.dart';
import 'tab_screens/home_screen.dart';

/// Post-interests notification primer. Explains the daily quote/fact alerts,
/// lets the user choose which kinds they want (all on by default), and requests
/// the OS notification permission — so permission is asked here once, with
/// context, instead of silently from the Home screen.
class NotificationsOnboardingScreen extends StatefulWidget {
  static const kRouteName = '/notifications-onboarding';

  const NotificationsOnboardingScreen({super.key});

  @override
  State<NotificationsOnboardingScreen> createState() =>
      _NotificationsOnboardingScreenState();
}

class _NotificationsOnboardingScreenState
    extends State<NotificationsOnboardingScreen> {
  /// prefKey -> on/off. Seeded from storage, defaulting to all-on.
  final Map<String, bool> _values = {
    for (final type in kNotificationTypes) type.prefKey: true,
  };

  SharedPreferences? _prefs;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // This screen can be the launch destination (existing users on update, or a
    // returning user who hasn't passed it yet), so it must clear the splash.
    FlutterNativeSplash.remove();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      for (final type in kNotificationTypes) {
        _values[type.prefKey] = prefs.getBool(type.prefKey) ?? true;
      }
    });
  }

  void _onChanged(NotificationType type, bool value) {
    setState(() => _values[type.prefKey] = value);
  }

  Future<void> _complete({required bool requestPermission}) async {
    if (_saving) return;
    setState(() => _saving = true);

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final service = NotificationService();
    final anySelected = _values.values.any((v) => v);

    // Persist + sync each type's topic subscription to its toggle. A full sync
    // (subscribe on / unsubscribe off) so existing users who turn something off
    // here are actually unsubscribed.
    for (final type in kNotificationTypes) {
      final enabled = _values[type.prefKey] ?? true;
      await prefs.setBool(type.prefKey, enabled);
      if (enabled) {
        await service.subscribeToTopic(type.topic);
      } else {
        await service.unsubscribeFromTopic(type.topic);
      }
    }

    // Master switch + the umbrella "all" topic, mirroring Settings semantics.
    await prefs.setBool(kNotificationEnabled, anySelected);
    if (anySelected) {
      await service.subscribeToTopic(kNotificationAllTopic);
    } else {
      await service.unsubscribeFromTopic(kNotificationAllTopic);
    }

    // Mark prefs seeded so Home's startup job won't reset them, and mark this
    // primer as seen so it isn't shown again.
    await prefs.setBool(kNotificationsInitializedKey, true);
    await prefs.setBool(kHasSeenNotificationPrompt, true);

    if (requestPermission) {
      await PushNotifications.requestPermissions();
    }

    if (!mounted) return;
    context.go(HomeScreen.kRouteName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ResponsiveCenter(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(theme: theme),
                      const SizedBox(height: 28),
                      NotificationTogglesSection(
                        values: _values,
                        onChanged: _onChanged,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Not sure? Keep them on — you can change these '
                              'anytime in Settings.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
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
              _BottomBar(
                saving: _saving,
                onAllow: () => _complete(requestPermission: true),
                onSkip: () => _complete(requestPermission: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ThemeData theme;

  const _Header({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.notifications_active_rounded,
            color: theme.colorScheme.primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Stay inspired',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get a daily quote and a fascinating fact delivered right to you. '
          'Choose what you\'d like to hear about.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  const _BottomBar({
    required this.saving,
    required this.onAllow,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving ? null : onAllow,
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Allow notifications'),
            ),
          ),
          TextButton(
            onPressed: saving ? null : onSkip,
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }
}
