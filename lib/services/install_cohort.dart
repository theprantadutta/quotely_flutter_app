import 'package:shared_preferences/shared_preferences.dart';

import '../constants/notification_types.dart';
import '../constants/shared_preference_keys.dart';

/// Tells installs that started on 3.4.0 or later ('new') from those that ran
/// an older version first ('existing'). Decided once, on the first launch of
/// 3.4.0, and stored: from then on onboarding writes the same prefs an old
/// install has, so they can't be told apart any other way.
abstract final class InstallCohort {
  static const _new = 'new';
  static const _existing = 'existing';

  /// Keys only an install that has already run can have. Everything here is
  /// written after main() resolves the cohort (through
  /// NotificationService.resolveDefaults, before anything else touches
  /// prefs). Not kNotificationDefaultsKey: 3.2.0+ writes it on every install.
  static List<String> get _priorRunKeys => [
    kOnboardingShownKey,
    kHasSelectedInterestsKey,
    kHasSeenNotificationPrompt,
    kNotificationsInitializedKey,
    kNotificationEnabled,
    for (final t in kNotificationTypes) t.prefKey,
    kAcceptedLegalVersionKey,
    kLegacyAcceptedTermsKey,
    kAppOpenCountKey,
    kActivityLogKey,
    kAppearanceMigratedKey,
    kQuoteWidgetIntroShownKey,
  ];

  /// Stores the cohort if it isn't stored yet. Never changes it.
  static Future<void> resolve(SharedPreferences prefs) async {
    if (prefs.containsKey(kInstallCohortKey)) return;
    final existing = _priorRunKeys.any(prefs.containsKey);
    await prefs.setString(kInstallCohortKey, existing ? _existing : _new);
  }

  /// First launched on 3.4.0 or later.
  static bool isNew(SharedPreferences prefs) =>
      prefs.getString(kInstallCohortKey) == _new;

  /// Ran a version older than 3.4.0.
  static bool isExisting(SharedPreferences prefs) =>
      prefs.getString(kInstallCohortKey) == _existing;
}
