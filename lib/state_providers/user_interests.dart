import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';

part '../generated/state_providers/user_interests.g.dart';

/// The user's chosen interests (a merged list of quote tags + fact
/// categories). Used as the base filter on the Home & Facts screens.
///
/// Self-loads from SharedPreferences on first build; [save] persists changes
/// and flips the "has selected interests" gate used by the router.
@Riverpod(keepAlive: true)
class UserInterests extends _$UserInterests {
  /// Hard cap on how many interests a user can pick.
  static const int maxInterests = 50;

  Future<void>? _loadFuture;

  @override
  List<String> build() {
    _loadFuture = _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(kInterestsKey) ?? const [];
  }

  /// Completes once interests have been read from storage. Screens await this
  /// before their first fetch so it's filtered correctly (and doesn't fetch
  /// unfiltered first, then refetch — which caused a skeleton flash).
  Future<void> get ready => _loadFuture ?? Future.value();

  /// Persists [interests] (capped at [maxInterests]) and marks the picker as
  /// completed so the onboarding gate lets the user through.
  Future<void> save(List<String> interests) async {
    final capped = interests.take(maxInterests).toList();
    state = capped;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(kInterestsKey, capped);
    await prefs.setBool(kHasSelectedInterestsKey, true);
  }
}
