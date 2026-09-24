import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';

part '../generated/state_providers/profile.g.dart';

/// Optional nickname. Its initial fills the You avatar on Today; with no
/// nickname the avatar shows a person icon.
@Riverpod(keepAlive: true)
class Nickname extends _$Nickname {
  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(kNicknameKey);
    state = (value == null || value.trim().isEmpty) ? null : value.trim();
  }

  Future<void> set(String? value) async {
    final clean = value?.trim();
    state = (clean == null || clean.isEmpty) ? null : clean;
    final prefs = await SharedPreferences.getInstance();
    if (state == null) {
      await prefs.remove(kNicknameKey);
    } else {
      await prefs.setString(kNicknameKey, state!);
    }
  }
}
