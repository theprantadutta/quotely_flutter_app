import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../components/thread/thread_message.dart';
import '../database/database.dart';
import '../dtos/ai_fact_dto.dart';
import '../dtos/quote_dto.dart';
import '../dtos/scene_quote_dto.dart';
import '../service_locator/init_service_locators.dart';
import 'drift_collection_service.dart';
import 'home_widget_store.dart';
import 'saved_widget_service.dart';

/// One saved thing in the Saved notebook.
@immutable
class SavedEntry {
  final ThreadMessage message;

  /// When it was saved; null for things saved before the app recorded it.
  final DateTime? savedAt;

  /// Orders the undated ones among themselves (the row's last change).
  final DateTime fallback;

  const SavedEntry({
    required this.message,
    required this.savedAt,
    required this.fallback,
  });

  String get key => message.key;

  factory SavedEntry.fromQuote(Quote q) => SavedEntry(
    message: ThreadMessage.fromQuote(QuoteDto.fromQuote(q)),
    savedAt: q.savedAt,
    fallback: q.dateModified,
  );

  factory SavedEntry.fromScene(SceneQuote s) => SavedEntry(
    message: ThreadMessage.fromScene(SceneQuoteDto.fromDrift(s)),
    savedAt: s.savedAt,
    fallback: s.dateModified,
  );

  factory SavedEntry.fromFact(Fact f) => SavedEntry(
    message: ThreadMessage.fromFact(AiFactDto.fromDrift(f)),
    savedAt: f.savedAt,
    fallback: f.dateModified,
  );
}

/// What the Saved feed shows: either everything, one kind, or one
/// collection. The chips pick exactly one.
@immutable
class SavedFilter {
  final MessageKind? kind;
  final int? collectionId;

  const SavedFilter._() : kind = null, collectionId = null;

  static const all = SavedFilter._();
  const SavedFilter.kind(MessageKind this.kind) : collectionId = null;
  const SavedFilter.collection(int this.collectionId) : kind = null;

  bool get isAll => kind == null && collectionId == null;

  @override
  bool operator ==(Object other) =>
      other is SavedFilter &&
      other.kind == kind &&
      other.collectionId == collectionId;

  @override
  int get hashCode => Object.hash(kind, collectionId);
}

/// A run of entries under one "Saved Tuesday" header.
@immutable
class SavedGroup {
  final String label;
  final List<SavedEntry> entries;
  const SavedGroup(this.label, this.entries);
}

/// Everything the Saved screen needs, in one snapshot.
@immutable
class SavedFeed {
  /// Newest first ([SavedFeedService.sorted]).
  final List<SavedEntry> entries;
  final List<CollectionSummary> collections;

  /// `type:itemId` → collection ids.
  final Map<String, Set<int>> memberships;

  const SavedFeed({
    required this.entries,
    this.collections = const [],
    this.memberships = const {},
  });

  int count(MessageKind kind) =>
      entries.where((e) => e.message.kind == kind).length;

  /// The names of the collections [entry] is tagged with, in chip order.
  List<String> tagsOf(SavedEntry entry) {
    final ids = memberships[entry.key];
    if (ids == null || ids.isEmpty) return const [];
    return [
      for (final c in collections)
        if (ids.contains(c.id)) c.name,
    ];
  }
}

/// The Saved notebook: one chronological feed of saved quotes, scenes and
/// facts, with collections as tags. Reads are local (Drift); the ordering,
/// filtering, date headers and the daily "Revisit" pick are pure functions
/// so they can be tested without a database.
class SavedFeedService {
  SavedFeedService._();

  /// How long ago something must have been saved to come back as Revisit.
  static const revisitAfter = Duration(days: 7);

  /// The feed, updated whenever a save, unsave or tag changes.
  static Stream<SavedFeed> watch() {
    final db = getIt.get<AppDatabase>();
    List<Quote>? quotes;
    List<SceneQuote>? scenes;
    List<Fact>? facts;
    List<CollectionSummary>? collections;
    Map<String, Set<int>>? memberships;
    final subs = <StreamSubscription<dynamic>>[];
    late final StreamController<SavedFeed> controller;

    void emit() {
      if (quotes == null ||
          scenes == null ||
          facts == null ||
          collections == null ||
          memberships == null) {
        return;
      }
      controller.add(
        SavedFeed(
          entries: sorted([
            ...quotes!.map(SavedEntry.fromQuote),
            ...scenes!.map(SavedEntry.fromScene),
            ...facts!.map(SavedEntry.fromFact),
          ]),
          collections: collections!,
          memberships: memberships!,
        ),
      );
    }

    controller = StreamController<SavedFeed>(
      onListen: () {
        subs.addAll([
          (db.select(
            db.quotes,
          )..where((q) => q.isFavorite.equals(true))).watch().listen((r) {
            quotes = r;
            emit();
          }, onError: controller.addError),
          (db.select(
            db.sceneQuotes,
          )..where((q) => q.isFavorite.equals(true))).watch().listen((r) {
            scenes = r;
            emit();
          }, onError: controller.addError),
          (db.select(
            db.facts,
          )..where((f) => f.isFavorite.equals(true))).watch().listen((r) {
            facts = r;
            emit();
          }, onError: controller.addError),
          DriftCollectionService.watchCollections().listen((r) {
            collections = r;
            emit();
          }, onError: controller.addError),
          DriftCollectionService.watchMemberships().listen((r) {
            memberships = r;
            emit();
          }, onError: controller.addError),
        ]);
      },
      // All at once, not one after another, so none outlives the screen.
      onCancel: () => Future.wait([for (final s in subs) s.cancel()]),
    );
    return controller.stream;
  }

  /// Newest saved first. Things saved before saved times were recorded go
  /// last, most recently changed first; ties break on the key so the order
  /// never shuffles between rebuilds.
  static List<SavedEntry> sorted(Iterable<SavedEntry> entries) {
    final list = entries.toList();
    list.sort((a, b) {
      final sa = a.savedAt, sb = b.savedAt;
      if (sa != null && sb != null) {
        final c = sb.compareTo(sa);
        if (c != 0) return c;
      } else if (sa != null) {
        return -1;
      } else if (sb != null) {
        return 1;
      } else {
        final c = b.fallback.compareTo(a.fallback);
        if (c != 0) return c;
      }
      return a.key.compareTo(b.key);
    });
    return list;
  }

  /// [feed]'s entries through [filter] and a free-text [query] (matched,
  /// case-insensitively, against the line, who said it and its source).
  static List<SavedEntry> apply(
    SavedFeed feed,
    SavedFilter filter, {
    String query = '',
  }) {
    final q = query.trim().toLowerCase();
    return [
      for (final e in feed.entries)
        if ((filter.kind == null || e.message.kind == filter.kind) &&
            (filter.collectionId == null ||
                (feed.memberships[e.key]?.contains(filter.collectionId) ??
                    false)) &&
            (q.isEmpty || _matches(e.message, q)))
          e,
    ];
  }

  static bool _matches(ThreadMessage m, String q) =>
      m.text.toLowerCase().contains(q) ||
      m.sender.toLowerCase().contains(q) ||
      m.sourceLine.toLowerCase().contains(q);

  /// Sorted [entries] cut into journal sections: a day each for the last
  /// week ("Saved today", "Saved yesterday", "Saved Tuesday"), then a week
  /// each for the last two months ("Saved the week of Sep 8"), then a month
  /// each ("Saved in March", "Saved in March 2025"). Undated entries close
  /// the feed under "Saved earlier".
  static List<SavedGroup> group(List<SavedEntry> entries, DateTime now) {
    final groups = <SavedGroup>[];
    String? currentKey;
    for (final e in entries) {
      final (key, label) = _section(e.savedAt, now);
      if (key != currentKey) {
        groups.add(SavedGroup(label, []));
        currentKey = key;
      }
      groups.last.entries.add(e);
    }
    return groups;
  }

  static (String, String) _section(DateTime? savedAt, DateTime now) {
    if (savedAt == null) return ('earlier', 'Saved earlier');
    final at = savedAt.toLocal();
    final days = HomeWidgetStore.dayNumber(now) - HomeWidgetStore.dayNumber(at);
    if (days <= 0) return ('d0', 'Saved today');
    if (days == 1) return ('d1', 'Saved yesterday');
    if (days < 7) return ('d$days', 'Saved ${DateFormat('EEEE').format(at)}');
    if (days < 56) {
      final monday = DateTime(at.year, at.month, at.day - (at.weekday - 1));
      return (
        'w${HomeWidgetStore.dayNumber(monday)}',
        'Saved the week of ${DateFormat('MMM d').format(monday)}',
      );
    }
    final month = at.year == now.year
        ? DateFormat('MMMM').format(at)
        : DateFormat('MMMM y').format(at);
    return ('m${at.year}-${at.month}', 'Saved in $month');
  }

  /// Today's "Revisit": one thing saved at least [revisitAfter] ago (or
  /// before saved times were recorded), a different one each day. It walks
  /// the pool one entry per calendar day with the "From your saved"
  /// widget's own pick ([SavedWidgetService.pickFor]), so it's stable
  /// through the day and independent of the database's row order. Spoiler
  /// scenes stay out: the top of the screen is no place to spoil a show.
  static SavedEntry? revisitFor(Iterable<SavedEntry> entries, DateTime today) {
    final cutoff = today.subtract(revisitAfter);
    final byKey = <String, SavedEntry>{};
    final pool = <SavedWidgetQuote>[];
    for (final e in entries) {
      final at = e.savedAt;
      if (at != null && at.isAfter(cutoff)) continue;
      if (e.message.scene?.isSpoiler ?? false) continue;
      byKey[e.key] = e;
      pool.add(
        SavedWidgetQuote(
          id: e.key,
          text: e.message.text.trim(),
          author: e.message.sender,
          added: at ?? e.fallback,
        ),
      );
    }
    final pick = SavedWidgetService.pickFor(pool, today);
    return pick == null ? null : byKey[pick.id];
  }

  /// "From your saved, 3 weeks ago" (or "…, a while ago" when undated).
  static String revisitLabel(SavedEntry entry, DateTime today) {
    final at = entry.savedAt;
    if (at == null) return 'From your saved, a while ago';
    final days =
        HomeWidgetStore.dayNumber(today) - HomeWidgetStore.dayNumber(at);
    return 'From your saved, ${_ago(days)}';
  }

  static String _ago(int days) {
    if (days < 14) return days <= 7 ? 'a week ago' : '$days days ago';
    if (days < 60) return '${days ~/ 7} weeks ago';
    if (days < 365) {
      final months = days ~/ 30;
      return months <= 1 ? 'a month ago' : '$months months ago';
    }
    final years = days ~/ 365;
    return years == 1 ? 'a year ago' : '$years years ago';
  }
}
