import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/thread/thread.dart';
import '../constants/notification_keys.dart';
import '../constants/notification_types.dart';
import '../constants/shared_preference_keys.dart';
import '../navigation/routes.dart';
import '../notifications/push_notification.dart';
import '../services/notification_service.dart';

/// "When should we text you?" Choose notification kinds (all on by
/// default), then ask the OS for permission with that context.
class NotificationsOnboardingScreen extends StatefulWidget {
  static const kRouteName = Routes.notificationsOnboarding;

  const NotificationsOnboardingScreen({super.key});

  @override
  State<NotificationsOnboardingScreen> createState() =>
      _NotificationsOnboardingScreenState();
}

class _NotificationsOnboardingScreenState
    extends State<NotificationsOnboardingScreen> {
  final Map<String, bool> _values = {
    for (final type in kNotificationTypes) type.prefKey: true,
  };

  SharedPreferences? _prefs;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Can be the launch destination, so it must clear the splash.
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

  Future<void> _complete({required bool requestPermission}) async {
    if (_saving) return;
    setState(() => _saving = true);

    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final selection = Map<String, bool>.from(_values);
    final anySelected = selection.values.any((v) => v);

    // The OS dialog first, so the user acts on it immediately.
    if (requestPermission) await PushNotifications.requestPermissions();

    // Awaited: two of these gate routing (see the router's redirect).
    for (final type in kNotificationTypes) {
      await prefs.setBool(type.prefKey, selection[type.prefKey] ?? true);
    }
    await prefs.setBool(kNotificationEnabled, anySelected);
    await prefs.setBool(kNotificationsInitializedKey, true);
    await prefs.setBool(kHasSeenNotificationPrompt, true);

    // One FCM round trip per topic: detached, it outlives this screen.
    unawaited(_syncTopics(selection, anySelected));

    if (!mounted) return;
    context.go(Routes.today);
  }

  /// Subscribes on, unsubscribes off. Static and argument-only because it
  /// runs after the screen is gone. Failures are repaired on next launch.
  static Future<void> _syncTopics(
    Map<String, bool> selection,
    bool anySelected,
  ) async {
    final service = NotificationService();
    try {
      for (final type in kNotificationTypes) {
        if (type.topic == null) continue;
        final enabled = selection[type.prefKey] ?? true;
        enabled
            ? await service.subscribeToTopic(type.topic!)
            : await service.unsubscribeFromTopic(type.topic!);
      }
      anySelected
          ? await service.subscribeToTopic(kNotificationAllTopic)
          : await service.unsubscribeFromTopic(kNotificationAllTopic);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final types = kNotificationTypes.where((t) => t.inPrimer).toList();
    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: ThreadColumn(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  children: [
                    Text(
                      'Step 3 of 3',
                      style: context.qt.label.copyWith(
                        color: t.accInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Semantics(
                      header: true,
                      child: Text(
                        'When should we text you?',
                        style: context.qt.titleScreen,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _PreviewNotification(),
                    const SizedBox(height: 16),
                    GroupedList(
                      children: [
                        for (final type in types)
                          GroupedRow(
                            title: type.title,
                            description: type.primerDescription,
                            isNew: type.isNew,
                            trailing: QToggle(
                              value: _values[type.prefKey] ?? true,
                              semanticLabel: type.title,
                              onChanged: (v) =>
                                  setState(() => _values[type.prefKey] = v),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: 'Allow notifications',
                      loading: _saving,
                      onPressed: () => _complete(requestPermission: true),
                    ),
                    const SizedBox(height: 4),
                    QTextButton(
                      label: 'Not now',
                      onPressed: _saving
                          ? null
                          : () => _complete(requestPermission: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a quote-of-the-day notification looks like. The one card in the
/// design with a shadow.
class _PreviewNotification extends StatelessWidget {
  const _PreviewNotification();

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return Semantics(
      label:
          'Example notification: Nelson Mandela, It always seems impossible until it’s done.',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.surf,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandIcon(size: 36, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'QUOTELY',
                          style: context.qt.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      Text('now', style: context.qt.caption),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('Nelson Mandela', style: context.qt.rowTitle),
                  Text(
                    'It always seems impossible until it’s done.',
                    style: context.qt.meta,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
