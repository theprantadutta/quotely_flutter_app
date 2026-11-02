import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../service_locator/init_service_locators.dart';

/// Logs an analytics event through the FirebaseAnalytics registered in getIt.
/// Never throws and never waits: analytics must not break a user action, and
/// in tests (or before the locator is set up) nothing is registered at all.
void logAppEvent(String name, [Map<String, Object> params = const {}]) {
  try {
    if (!getIt.isRegistered<FirebaseAnalytics>()) return;
    getIt
        .get<FirebaseAnalytics>()
        .logEvent(name: name, parameters: params)
        .catchError((Object e) => debugPrint('Analytics $name failed: $e'));
  } catch (e) {
    debugPrint('Analytics $name failed: $e');
  }
}
