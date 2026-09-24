import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/thread/thread.dart';
import '../constants/notification_types.dart';
import '../constants/shared_preference_keys.dart';
import '../navigation/routes.dart';
import '../services/notification_service.dart';

/// "10 PM" on the hour, "10:30 PM" otherwise. 24-hour locales keep ":00".
String formatMinutes(BuildContext context, int minutes) {
  final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
  final text = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    alwaysUse24HourFormat: use24,
  );
  return minutes % 60 == 0 && !use24 ? text.replaceFirst(':00', '') : text;
}

class SettingsNotificationScreen extends StatefulWidget {
  static const kRouteName = Routes.notifications;
  const SettingsNotificationScreen({super.key});

  @override
  State<SettingsNotificationScreen> createState() =>
      _SettingsNotificationState();
}

class _SettingsNotificationState extends State<SettingsNotificationScreen> {
  final Map<String, bool> _values = {
    kNotificationEnabled: true,
    for (final t in kNotificationTypes) t.prefKey: true,
  };
  SharedPreferences? _prefs;
  bool _quietEnabled = true;
  int _quietStart = NotificationService.defaultQuietStart;
  int _quietEnd = NotificationService.defaultQuietEnd;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final quiet = await NotificationService.quietHours();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      for (final key in _values.keys.toList()) {
        _values[key] = prefs.getBool(key) ?? true;
      }
      _quietEnabled = quiet.enabled;
      _quietStart = quiet.start;
      _quietEnd = quiet.end;
    });
  }

  /// Same semantics as before: the master switch flips every preference and
  /// (un)subscribes every topic; a single row (un)subscribes its own topic.
  Future<void> _set(String key, bool value) async {
    final service = NotificationService();
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (key == kNotificationEnabled) {
      setState(() => _values.updateAll((_, _) => value));
      for (final k in _values.keys) {
        await prefs.setBool(k, value);
      }
      try {
        value
            ? await service.subscribeToAllTopic()
            : await service.unsubscribeFromAllTopic();
      } catch (_) {}
      return;
    }
    setState(() => _values[key] = value);
    await prefs.setBool(key, value);
    final type = kNotificationTypes.firstWhere((t) => t.prefKey == key);
    try {
      if (type.topic != null) {
        value
            ? await service.subscribeToTopic(type.topic!)
            : await service.unsubscribeFromTopic(type.topic!);
      } else if (key == kNotificationFollowedTitles) {
        await service.syncFollowedTitleTopics(value);
      }
    } catch (_) {
      // Offline or FCM not ready; the next launch re-subscribes enabled ones.
    }
  }

  Future<void> _editQuietHours() async {
    await showQSheet(
      context,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) {
          Future<void> pick(bool start) async {
            final current = start ? _quietStart : _quietEnd;
            final picked = await showTimePicker(
              context: sheet,
              initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
            );
            if (picked == null) return;
            final minutes = picked.hour * 60 + picked.minute;
            setState(() => start ? _quietStart = minutes : _quietEnd = minutes);
            setSheet(() {});
            await _prefs?.setInt(
              start ? kQuietHoursStartKey : kQuietHoursEndKey,
              minutes,
            );
          }

          return QSheetFrame(
            title: 'Quiet hours',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'We won’t show notifications on this device during these hours.',
                  style: sheet.qt.body,
                ),
                const SizedBox(height: 12),
                GroupedList(
                  color: sheet.q.bg,
                  children: [
                    GroupedRow(
                      title: 'Quiet hours',
                      trailing: QToggle(
                        value: _quietEnabled,
                        semanticLabel: 'Quiet hours',
                        onChanged: (v) {
                          setState(() => _quietEnabled = v);
                          setSheet(() {});
                          _prefs?.setBool(kQuietHoursEnabledKey, v);
                        },
                      ),
                    ),
                    GroupedRow(
                      title: 'From',
                      trailing: Text(
                        formatMinutes(sheet, _quietStart),
                        style: sheet.qt.rowTitle.copyWith(
                          color: sheet.q.accInk,
                        ),
                      ),
                      onTap: () => pick(true),
                    ),
                    GroupedRow(
                      title: 'To',
                      trailing: Text(
                        formatMinutes(sheet, _quietEnd),
                        style: sheet.qt.rowTitle.copyWith(
                          color: sheet.q.accInk,
                        ),
                      ),
                      onTap: () => pick(false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Done',
                  onPressed: () => Navigator.of(sheet).pop(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    final master = _values[kNotificationEnabled] ?? true;
    final quiet = _quietEnabled
        ? 'Quiet hours ${formatMinutes(context, _quietStart)} – ${formatMinutes(context, _quietEnd)}'
        : 'Quiet hours off';
    return ThreadPage(
      title: 'Notifications',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            decoration: BoxDecoration(
              color: t.accSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    hint: 'Edit quiet hours',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _editQuietHours,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All notifications',
                            style: context.qt.rowTitle.copyWith(
                              fontSize: 17,
                              color: t.accInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$quiet ›',
                            style: context.qt.meta.copyWith(
                              color: t.accInk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                QToggle(
                  value: master,
                  large: true,
                  semanticLabel: 'All notifications',
                  onChanged: (v) => _set(kNotificationEnabled, v),
                ),
              ],
            ),
          ),
          for (final group in NotificationGroup.values) ...[
            const SizedBox(height: 18),
            SectionOverline(group.label),
            IgnorePointer(
              ignoring: !master,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: master ? 1 : 0.5,
                child: GroupedList(
                  children: [
                    for (final type in notificationTypesIn(group))
                      GroupedRow(
                        title: type.title,
                        description: type.schedule,
                        isNew: type.isNew,
                        trailing: QToggle(
                          value: _values[type.prefKey] ?? true,
                          semanticLabel: type.title,
                          onChanged: (v) => _set(type.prefKey, v),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          GroupedList(
            children: [
              GroupedRow(
                title: 'See past messages',
                description: 'Everything we’ve sent you',
                chevron: true,
                onTap: () => context.push(Routes.pastMessages),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
