import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/notification_keys.dart';
import '../constants/shared_preference_keys.dart';
import '../dtos/media_title_dto.dart';
import '../services/notification_service.dart';

part '../generated/state_providers/scene_state.g.dart';

/// Ids of saved scene lines, mirroring FavoriteQuoteIds. Seeded from Drift
/// at startup (see TodayScreen), updated optimistically on toggle.
@Riverpod(keepAlive: true)
class FavoriteSceneIds extends _$FavoriteSceneIds {
  @override
  Set<String> build() => const {};

  void setAll(Iterable<String> ids) => state = {...ids};

  void setStatus(String id, bool favorite) {
    state = favorite ? {...state, id} : ({...state}..remove(id));
  }
}

/// Spoiler shield (default on). Persisted.
@Riverpod(keepAlive: true)
class SpoilerShield extends _$SpoilerShield {
  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(kSpoilerShieldKey) ?? true;
  }

  Future<void> set(bool on) async {
    state = on;
    await (await SharedPreferences.getInstance()).setBool(
      kSpoilerShieldKey,
      on,
    );
  }

  Future<void> toggle() => set(!state);
}

/// Spoilers revealed this session. Not persisted on purpose: a reveal is a
/// one-off decision, the shield is the setting.
@Riverpod(keepAlive: true)
class RevealedSpoilers extends _$RevealedSpoilers {
  @override
  Set<String> build() => const {};

  void reveal(String sceneQuoteId) => state = {...state, sceneQuoteId};
}

/// "I've watched up to episode N", per title id. Spoilers at or below N are
/// shown without the blur.
@Riverpod(keepAlive: true)
class WatchedUpTo extends _$WatchedUpTo {
  @override
  Map<String, int> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kWatchedUpToKey);
    if (raw == null) return;
    state = (json.decode(raw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    );
  }

  Future<void> set(String titleId, int? episode) async {
    final next = {...state};
    if (episode == null) {
      next.remove(titleId);
    } else {
      next[titleId] = episode;
    }
    state = next;
    await (await SharedPreferences.getInstance()).setString(
      kWatchedUpToKey,
      json.encode(next),
    );
  }
}

/// Followed titles: id → slug. Following subscribes to the `title_<slug>`
/// FCM topic when "New from titles you follow" is on, and powers the
/// "From titles you follow" section on Scenes.
@Riverpod(keepAlive: true)
class FollowedTitles extends _$FollowedTitles {
  @override
  Map<String, String> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kFollowedTitleSlugsKey);
    if (raw == null) return;
    state = (json.decode(raw) as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as String),
    );
  }

  bool isFollowing(String titleId) => state.containsKey(titleId);

  Future<void> toggle(MediaTitleDto title) async {
    final following = state.containsKey(title.id);
    final next = {...state};
    if (following) {
      next.remove(title.id);
    } else {
      next[title.id] = title.slug;
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kFollowedTitleSlugsKey, json.encode(next));
    await prefs.setStringList(kFollowedTitlesKey, next.keys.toList());

    // Topic sync is best effort (offline, FCM not ready): Settings re-syncs.
    final notify = prefs.getBool(kNotificationFollowedTitles) ?? true;
    final enabled = prefs.getBool(kNotificationEnabled) ?? true;
    try {
      final topic = '$kNotificationTitleTopicPrefix${title.slug}';
      if (!following && notify && enabled) {
        await NotificationService().subscribeToTopic(topic);
      } else if (following) {
        await NotificationService().unsubscribeFromTopic(topic);
      }
    } catch (_) {}
  }
}

/// Interests → SCREEN picks (media type names). Drive which types appear in
/// Today's scenes and are preselected on Scenes. Empty means "all types".
@Riverpod(keepAlive: true)
class ScreenInterests extends _$ScreenInterests {
  Future<void>? _loading;

  @override
  List<MediaType> build() {
    _loading = _load();
    return const [];
  }

  Future<void> get ready => _loading ?? Future.value();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = [
      for (final name in prefs.getStringList(kScreenInterestsKey) ?? const [])
        MediaTypeX.parse(name),
    ];
  }

  Future<void> save(List<MediaType> types) async {
    state = List.unmodifiable(types);
    await (await SharedPreferences.getInstance()).setStringList(
      kScreenInterestsKey,
      [for (final t in types) t.name],
    );
  }
}

/// Followed author slugs (local only). Shown first in the People stories.
@Riverpod(keepAlive: true)
class FollowedAuthors extends _$FollowedAuthors {
  @override
  Set<String> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = {...prefs.getStringList(kFollowedAuthorsKey) ?? const []};
  }

  Future<void> toggle(String slug) async {
    state = state.contains(slug)
        ? ({...state}..remove(slug))
        : {...state, slug};
    await (await SharedPreferences.getInstance()).setStringList(
      kFollowedAuthorsKey,
      state.toList(),
    );
  }
}
