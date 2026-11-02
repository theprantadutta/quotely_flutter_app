import 'dart:io' show Platform;
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_analytics.dart';
import 'report_outbox.dart';

/// The kinds the backend's Report/Submit takes.
enum UserReportKind {
  contentFlag('content_flag'),
  feedback('feedback'),
  bug('bug');

  const UserReportKind(this.wire);
  final String wire;
}

/// Limits shared with the backend (UserReportRules). The sheets enforce
/// them, so the server never has a reason to reject what the user typed.
abstract final class UserReportLimits {
  static const message = 4000;
  static const correction = 1000;
  static const email = 254;
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Empty is fine (the email is optional); otherwise it must look like one.
bool isValidOptionalEmail(String value) {
  final v = value.trim();
  return v.isEmpty || (v.length <= UserReportLimits.email && _email.hasMatch(v));
}

/// A random RFC 4122 v4 UUID: the report's idempotency key.
String newClientId([Random? random]) {
  final r = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// The route the user was on, for the report's context. Null outside a router.
String? currentScreen(BuildContext context) {
  try {
    return GoRouter.maybeOf(
      context,
    )?.routerDelegate.currentConfiguration.uri.path;
  } catch (_) {
    return null;
  }
}

/// App version, platform, OS version, device model and locale. Each field
/// is best effort: a plugin that fails (or a test) just leaves it out.
Future<Map<String, String>> collectDeviceContext() async {
  final out = <String, String>{};
  try {
    final info = await PackageInfo.fromPlatform();
    out['appVersion'] = info.buildNumber.isEmpty
        ? info.version
        : '${info.version}+${info.buildNumber}';
  } catch (_) {}
  try {
    out['locale'] = PlatformDispatcher.instance.locale.toLanguageTag();
  } catch (_) {}
  if (kIsWeb) {
    out['platform'] = 'web';
    return out;
  }
  try {
    out['platform'] = Platform.operatingSystem;
    final device = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final a = await device.androidInfo;
      out['osVersion'] = 'Android ${a.version.release} (SDK ${a.version.sdkInt})';
      out['deviceModel'] = '${a.manufacturer} ${a.model}';
    } else if (Platform.isIOS) {
      final i = await device.iosInfo;
      out['osVersion'] = '${i.systemName} ${i.systemVersion}';
      out['deviceModel'] = i.utsname.machine;
    } else {
      out['osVersion'] = Platform.operatingSystemVersion;
    }
  } catch (_) {}
  return out;
}

/// Builds and queues reports. Everything goes through the [ReportOutbox]:
/// saved locally first, sent when online.
abstract final class UserReports {
  /// Device context collector. Replaceable in tests.
  @visibleForTesting
  static Future<Map<String, String>> Function() deviceContext =
      collectDeviceContext;

  /// Queues a flag on a quote, fact or scene line. [contentType] is
  /// `quote`, `fact` or `scene`.
  static Future<void> flagContent({
    required String contentType,
    required String contentId,
    required String reason,
    String? contentSnapshot,
    String? message,
    String? correction,
    String? contactEmail,
    String? screen,
  }) => _queue(
    kind: UserReportKind.contentFlag,
    includeDevice: true,
    screen: screen,
    fields: {
      'contentType': contentType,
      'contentId': contentId,
      'reason': reason,
      'contentSnapshot': contentSnapshot,
      'message': message,
      'correction': correction,
      'contactEmail': contactEmail,
    },
  );

  /// Queues feedback or a bug report.
  static Future<void> sendFeedback({
    required UserReportKind kind,
    required String message,
    String? contactEmail,
    bool includeDevice = true,
    String? screen,
  }) {
    assert(kind != UserReportKind.contentFlag);
    return _queue(
      kind: kind,
      includeDevice: includeDevice,
      screen: screen,
      fields: {'message': message, 'contactEmail': contactEmail},
    );
  }

  static Future<void> _queue({
    required UserReportKind kind,
    required bool includeDevice,
    required Map<String, String?> fields,
    String? screen,
  }) async {
    final payload = <String, dynamic>{
      'clientId': newClientId(),
      'kind': kind.wire,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    fields.forEach((k, v) {
      final t = v?.trim();
      if (t != null && t.isNotEmpty) payload[k] = t;
    });
    if (includeDevice) {
      try {
        payload.addAll(await deviceContext());
      } catch (_) {}
      if (screen != null && screen.isNotEmpty) payload['screen'] = screen;
    }
    await ReportOutbox.instance.enqueue(payload);
    logAppEvent('feedback_sent', {'kind': kind.wire});
  }
}
