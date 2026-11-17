import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../service_locator/init_service_locators.dart';

/// Logs an analytics event through the FirebaseAnalytics registered in getIt.
/// Never throws and never waits: analytics must not break a user action, and
/// in tests (or before the locator is set up) nothing is registered at all.
/// The event is also heard on the device, through [AppEvents].
void logAppEvent(String name, [Map<String, Object> params = const {}]) {
  AppEvents.emit(name, params);
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

/// One analytics event, as the app saw it.
typedef AppEvent = ({String name, Map<String, Object> params});

/// The analytics events, heard on the device. The places that log the events
/// a feature cares about also emit them here, so it can react to what the
/// user did (the starter path ticks off its steps) without Firebase or a
/// network.
abstract final class AppEvents {
  static final _controller = StreamController<AppEvent>.broadcast();

  static Stream<AppEvent> get stream => _controller.stream;

  /// Never throws.
  static void emit(String name, [Map<String, Object> params = const {}]) {
    try {
      if (_controller.hasListener) {
        _controller.add((name: name, params: params));
      }
    } catch (e) {
      debugPrint('Local event $name failed: $e');
    }
  }
}
