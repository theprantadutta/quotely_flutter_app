import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../service_locator/init_service_locators.dart';
import 'home_widget_store.dart';

/// Analytics for the home-screen widgets. Every call is fire-and-forget and
/// never throws.
///
/// - `widget_placed` / `widget_removed` {widget_kind}: on Android the
///   providers' onEnabled / onDisabled append `placed:<kind>` or
///   `removed:<kind>` to [kEvents] (comma separated) in home_widget's
///   storage, and [flushPlacements] logs and clears them the next time the
///   app runs. iOS has no such callbacks, so [flushPlacements] compares the
///   kinds WidgetKit reports as installed with the ones seen last time.
/// - `widget_opened` {widget_kind}: the app was opened from a widget.
/// - `widget_add_tapped` {widget_kind, source}: "Add widget" in the app.
class WidgetAnalytics {
  WidgetAnalytics._();

  /// Written natively by the Android providers; keep in sync with WidgetArt.kt.
  static const kEvents = 'widget_events';

  /// iOS: the widget kinds installed when last checked.
  static const kInstalledKinds = 'home-widget-installed-kinds';

  static void log(String name, Map<String, Object> params) {
    try {
      if (!getIt.isRegistered<FirebaseAnalytics>()) return;
      unawaited(
        getIt
            .get<FirebaseAnalytics>()
            .logEvent(name: name, parameters: params)
            .catchError((Object _) {}),
      );
    } catch (_) {
      // Analytics must never break the app.
    }
  }

  static void opened(QuotelyWidgetKind kind) =>
      log('widget_opened', {'widget_kind': kind.id});

  static void addTapped(QuotelyWidgetKind kind, String source) =>
      log('widget_add_tapped', {'widget_kind': kind.id, 'source': source});

  /// The (event, kind) pairs in [raw], oldest first; unknown entries are
  /// skipped.
  @visibleForTesting
  static List<(String, QuotelyWidgetKind)> parseEvents(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final out = <(String, QuotelyWidgetKind)>[];
    for (final entry in raw.split(',')) {
      final parts = entry.trim().split(':');
      if (parts.length != 2) continue;
      final kind = QuotelyWidgetKind.fromId(parts[1]);
      if (kind == null) continue;
      if (parts[0] == 'placed') out.add(('widget_placed', kind));
      if (parts[0] == 'removed') out.add(('widget_removed', kind));
    }
    return out;
  }

  /// The placements and removals between [before] and [now], as events.
  @visibleForTesting
  static List<(String, QuotelyWidgetKind)> diffInstalled(
    Set<QuotelyWidgetKind> before,
    Set<QuotelyWidgetKind> now,
  ) => [
    for (final k in QuotelyWidgetKind.values)
      if (now.contains(k) && !before.contains(k)) ('widget_placed', k),
    for (final k in QuotelyWidgetKind.values)
      if (before.contains(k) && !now.contains(k)) ('widget_removed', k),
  ];

  /// Logs the placements and removals since the last run. Never throws.
  static Future<void> flushPlacements() async {
    if (!HomeWidgetStore.supported) return;
    try {
      await HomeWidgetStore.ready();
      final events = defaultTargetPlatform == TargetPlatform.iOS
          ? await _iOSEvents()
          : await _androidEvents();
      for (final (name, kind) in events) {
        log(name, {'widget_kind': kind.id});
      }
    } catch (e) {
      debugPrint('WidgetAnalytics: flush failed: $e');
    }
  }

  static Future<List<(String, QuotelyWidgetKind)>> _androidEvents() async {
    final raw = await HomeWidgetStore.read<String>(kEvents);
    if (raw == null || raw.isEmpty) return const [];
    await HomeWidgetStore.save<String>(kEvents, null);
    return parseEvents(raw);
  }

  static Future<List<(String, QuotelyWidgetKind)>> _iOSEvents() async {
    final installed = await HomeWidget.getInstalledWidgets();
    final now = <QuotelyWidgetKind>{
      for (final w in installed)
        ?QuotelyWidgetKind.fromInstalled(iOSKind: w.iOSKind),
    };
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(kInstalledKinds);
    await prefs.setStringList(kInstalledKinds, [for (final k in now) k.id]);
    // The first check only records the baseline.
    if (saved == null) return const [];
    final before = <QuotelyWidgetKind>{
      for (final id in saved) ?QuotelyWidgetKind.fromId(id),
    };
    return diffInstalled(before, now);
  }
}
