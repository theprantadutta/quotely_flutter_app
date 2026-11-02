import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../database/database.dart';
import 'home_widget_store.dart';

/// One saved quote, as the "From your saved" widget needs it.
@immutable
class SavedWidgetQuote {
  final String id;
  final String text;
  final String author;
  final DateTime added;

  const SavedWidgetQuote({
    required this.id,
    required this.text,
    required this.author,
    required this.added,
  });

  factory SavedWidgetQuote.fromDrift(Quote q) => SavedWidgetQuote(
    id: q.id,
    text: q.content.trim(),
    author: q.author.trim(),
    added: q.dateAdded,
  );
}

/// Feeds the "From your saved" home-screen widget: one of the person's own
/// saved quotes, a different one each day, over the page with the day's
/// glow. Entirely offline: the saved quotes are local, and so is the glow.
///
/// The widget has to change quote at midnight without the app, so this saves
/// the picks for the next [horizon] days rather than just today's:
/// `saved_days` = `{"start":"yyyy-MM-dd","quotes":[{"t":text,"a":author}…]}`,
/// where quotes[i] is for start + i days (wrapping round past the end), plus
/// `saved_count` (0 shows the "save a quote" hint) and the shared glow days.
/// The pick itself ([pickFor]) lives here only; the widgets just index.
///
/// Keep the keys in sync with SavedQuoteWidgetProvider.kt and
/// SavedQuoteWidget.swift.
class SavedWidgetService {
  SavedWidgetService._();

  static final instance = SavedWidgetService._();

  static const kDays = 'saved_days';
  static const kCount = 'saved_count';

  /// Days of picks saved ahead. A multiple of the glow's five-day cycle.
  static const horizon = HomeWidgetStore.glowHorizon;

  final _updates = SerialWidgetUpdates();

  /// [saved] in a stable order (oldest saved first), so the same list always
  /// gives the same pick for a day, whatever order the database returned.
  @visibleForTesting
  static List<SavedWidgetQuote> ordered(Iterable<SavedWidgetQuote> saved) {
    final list = [
      for (final q in saved)
        if (q.text.isNotEmpty) q,
    ];
    list.sort((a, b) {
      final byDate = a.added.compareTo(b.added);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    return list;
  }

  /// The saved quote for [day]: the list walked one quote per calendar day.
  /// Null when nothing is saved.
  static SavedWidgetQuote? pickFor(
    Iterable<SavedWidgetQuote> saved,
    DateTime day,
  ) {
    final list = ordered(saved);
    if (list.isEmpty) return null;
    return list[HomeWidgetStore.dayNumber(day) % list.length];
  }

  /// What is saved for the widget, from [today] on.
  @visibleForTesting
  static Map<String, Object> payload(
    Iterable<SavedWidgetQuote> saved,
    DateTime today,
  ) {
    final list = ordered(saved);
    final start = DateTime(today.year, today.month, today.day);
    final first = HomeWidgetStore.dayNumber(start);
    return {
      'start': HomeWidgetStore.dayKey(start),
      'quotes': [
        if (list.isNotEmpty)
          for (var i = 0; i < horizon; i++)
            {
              't': list[(first + i) % list.length].text,
              'a': list[(first + i) % list.length].author,
            },
      ],
    };
  }

  /// Saves the picks for [saved] from today and redraws the widget. Runs
  /// one call at a time and skips a call that would save the same thing on
  /// the same day, unless [force]. Never throws.
  Future<void> update(
    List<SavedWidgetQuote> saved, {
    bool force = false,
    DateTime? now,
  }) {
    if (!HomeWidgetStore.supported) return Future<void>.value();
    final today = now ?? DateTime.now();
    final data = payload(saved, today);
    final json = jsonEncode(data);
    return _updates.run(json, force, label: 'SavedWidgetService', () async {
      await HomeWidgetStore.save<String>(kDays, json);
      await HomeWidgetStore.save<int>(kCount, ordered(saved).length);
      await HomeWidgetStore.saveGlowDays(today);
      await HomeWidgetStore.redraw(QuotelyWidgetKind.saved);
    });
  }

  @visibleForTesting
  void debugReset() => _updates.debugReset();
}
