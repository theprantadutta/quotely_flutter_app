import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/shared_preference_keys.dart';

part '../generated/state_providers/recent_people.g.dart';

enum PersonKind { author, character }

/// Someone the user opened recently, for the People story row.
class RecentPerson {
  final PersonKind kind;

  /// Author slug, or character id.
  final String id;
  final String name;
  final String? imageUrl;

  /// Characters open their title page.
  final String? titleId;

  const RecentPerson({
    required this.kind,
    required this.id,
    required this.name,
    this.imageUrl,
    this.titleId,
  });

  Map<String, dynamic> toJson() => {
    'k': kind.name,
    'id': id,
    'n': name,
    'i': imageUrl,
    't': titleId,
  };

  factory RecentPerson.fromJson(Map<String, dynamic> j) => RecentPerson(
    kind: PersonKind.values.byName(j['k'] as String),
    id: j['id'] as String,
    name: j['n'] as String,
    imageUrl: j['i'] as String?,
    titleId: j['t'] as String?,
  );
}

@Riverpod(keepAlive: true)
class RecentPeople extends _$RecentPeople {
  static const _max = 12;

  @override
  List<RecentPerson> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(kRecentPeopleKey);
    if (raw == null) return;
    try {
      state = [
        for (final j in json.decode(raw) as List)
          RecentPerson.fromJson(j as Map<String, dynamic>),
      ];
    } catch (_) {
      await prefs.remove(kRecentPeopleKey);
    }
  }

  Future<void> add(RecentPerson person) async {
    state = [
      person,
      ...state.where((p) => !(p.kind == person.kind && p.id == person.id)),
    ].take(_max).toList();
    await (await SharedPreferences.getInstance()).setString(
      kRecentPeopleKey,
      json.encode([for (final p in state) p.toJson()]),
    );
  }
}
