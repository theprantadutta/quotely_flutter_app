import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

import '../components/thread/thread_message.dart';
import '../constants/default_interests.dart';
import '../database/database.dart';
import '../dtos/media_title_dto.dart';
import '../dtos/quote_dto.dart';
import '../service_locator/init_service_locators.dart';
import 'ask_service.dart';
import 'drift_scene_service.dart';
import 'quote_service.dart';
import '../util/profanity.dart';

/// Answers the Today composer ("Ask for a quote about…").
///
/// Online, the question goes to the backend's Ask endpoint ([AskService]),
/// which understands it ("something to get me through a breakup") and
/// answers with quotes, sometimes a fact. Offline, on any error, or when
/// the server finds nothing, it falls back silently to the local search:
/// known tag names go to the regular quotes endpoint (which falls back to
/// the Drift cache offline), media words ("anime", "movie") route to
/// Scenes, and anything else is a keyword match over cached quote text and
/// authors. Questions about scenes go straight to the local search, since
/// the server answers with quotes only.
class ComposerSearchService {
  ComposerSearchService._();

  /// Longer than the HTTP timeout; a last guard so the sheet never hangs.
  static const serverTimeout = Duration(seconds: 25);

  static const _stopWords = {
    'a',
    'an',
    'the',
    'about',
    'quote',
    'quotes',
    'line',
    'lines',
    'for',
    'me',
    'some',
    'on',
    'of',
    'from',
    'give',
    'show',
    'something',
    'any',
    'and',
    'or',
    'to',
    'in',
    'with',
    'is',
    'it',
    'that',
    'this',
    'my',
    'i',
    'want',
    'need',
    'please',
    'by',
    'say',
    'says',
    'said',
    'like',
    'one',
  };

  static const Map<String, MediaType> _mediaWords = {
    'movie': MediaType.movie,
    'movies': MediaType.movie,
    'film': MediaType.movie,
    'films': MediaType.movie,
    'tv': MediaType.tv,
    'show': MediaType.tv,
    'shows': MediaType.tv,
    'series': MediaType.tv,
    'sitcom': MediaType.tv,
    'anime': MediaType.anime,
    'manga': MediaType.anime,
    'game': MediaType.game,
    'games': MediaType.game,
    'gaming': MediaType.game,
    'videogame': MediaType.game,
    'cartoon': MediaType.cartoon,
    'cartoons': MediaType.cartoon,
    'animated': MediaType.cartoon,
  };

  static List<String> _tokens(String prompt) => prompt
      .toLowerCase()
      .replaceAll(RegExp(r"[^a-z0-9\s'-]"), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 1 && !_stopWords.contains(w))
      .toList();

  /// Up to [limit] messages answering [prompt]. Never throws; an empty list
  /// means nothing matched.
  ///
  /// [useServer]: false keeps it on the device (search-as-you-type, where
  /// every keystroke pause would otherwise be a new question to the server).
  static Future<List<ThreadMessage>> ask(
    String prompt, {
    int limit = 3,
    bool useServer = true,
  }) => askWith(
    prompt,
    limit: limit,
    server: useServer && !_wantsScenes(prompt) ? _server : null,
    local: _ask,
  );

  /// [ask] with its two sources passed in: [server] first when given, then
  /// [local] if the server fails, times out or has nothing clean.
  @visibleForTesting
  static Future<List<ThreadMessage>> askWith(
    String prompt, {
    required int limit,
    Future<List<ThreadMessage>> Function(String prompt, int limit)? server,
    required Future<List<ThreadMessage>> Function(String prompt, int limit)
    local,
    Duration timeout = serverTimeout,
  }) async {
    if (server != null) {
      try {
        final answers = await server(prompt, limit).timeout(timeout);
        final clean = [
          for (final m in answers)
            if (isClean(m.text)) m,
        ];
        if (clean.isNotEmpty) return clean.take(limit).toList();
      } catch (e) {
        debugPrint('ComposerSearchService: server ask failed, local search: $e');
      }
    }
    try {
      final results = await local(prompt, limit);
      return [
        for (final m in results)
          if (isClean(m.text)) m,
      ];
    } catch (_) {
      return const [];
    }
  }

  /// The backend's answer: its quotes, with one fact in the last place when
  /// a fact category matched and there is room for more than one message.
  static Future<List<ThreadMessage>> _server(String prompt, int limit) async {
    final answer = await AskService.answer(prompt, limit: limit);
    final fact = limit > 1 && answer.facts.isNotEmpty ? answer.facts.first : null;
    return [
      for (final q in answer.quotes.take(fact == null ? limit : limit - 1))
        ThreadMessage.fromQuote(q),
      if (fact != null) ThreadMessage.fromFact(fact),
    ];
  }

  static bool _wantsScenes(String prompt) =>
      prompt.toLowerCase().contains('scene') ||
      _tokens(prompt).any(_mediaWords.containsKey);

  static Future<List<ThreadMessage>> _ask(String prompt, int limit) async {
    final tokens = _tokens(prompt);
    if (tokens.isEmpty) return const [];

    final types = {
      for (final w in tokens)
        if (_mediaWords.containsKey(w)) _mediaWords[w]!,
    };
    final wantsScenes = _wantsScenes(prompt);
    final topical = tokens.where((w) => !_mediaWords.containsKey(w)).toList();

    try {
      if (wantsScenes) {
        final scenes = await _scenes(topical, types, limit);
        if (scenes.isNotEmpty) return scenes;
      }
      final quotes = await _quotes(topical.isEmpty ? tokens : topical, limit);
      if (quotes.isNotEmpty) return quotes;
      // A topic with no quote match can still have a scene line.
      if (!wantsScenes) return await _scenes(topical, types, limit);
    } catch (_) {
      // Fall through to "nothing found".
    }
    return const [];
  }

  static Future<List<ThreadMessage>> _scenes(
    List<String> words,
    Set<MediaType> types,
    int limit,
  ) async {
    final all = await DriftSceneService.getAll();
    final pool = types.isEmpty
        ? all
        : all.where((q) => types.contains(q.titleType)).toList();
    int score(q) {
      final hay = [
        q.content,
        q.tags.join(' '),
        q.titleName,
        q.characterName,
      ].join(' ').toLowerCase();
      return words.where(hay.contains).length;
    }

    final ranked = [
      for (final q in pool)
        if (words.isEmpty || score(q) > 0) q,
    ]..shuffle(Random());
    ranked.sort((a, b) => score(b).compareTo(score(a)));
    return [
      for (final q in ranked.where((q) => !q.isSpoiler).take(limit))
        ThreadMessage.fromScene(q),
    ];
  }

  static Future<List<ThreadMessage>> _quotes(
    List<String> words,
    int limit,
  ) async {
    // 1. Known topics → the real quotes endpoint, filtered by tag.
    final vocabulary = {
      for (final t in kDefaultInterestOptions) t.toLowerCase(): t,
    };
    final phrase = words.join(' ');
    final tags = <String>{
      if (vocabulary.containsKey(phrase)) vocabulary[phrase]!,
      for (final w in words)
        if (vocabulary.containsKey(w)) vocabulary[w]!,
    };
    if (tags.isNotEmpty) {
      final res = await QuoteService.getAllQuotesFromDatabase(
        pageNumber: 1,
        pageSize: limit,
        tags: tags.toList(),
        seed: Random().nextInt(999999) + 1,
      );
      if (res.quotes.isNotEmpty) {
        return [
          for (final q in res.quotes.take(limit)) ThreadMessage.fromQuote(q),
        ];
      }
    }

    // 2. Keyword match over cached quote text, tags and authors.
    final db = getIt.get<AppDatabase>();
    final query = db.select(db.quotes)
      ..where((q) {
        Expression<bool> any = const Constant(false);
        for (final w in words) {
          any =
              any |
              q.content.like('%$w%') |
              q.tags.like('%$w%') |
              q.author.like('%$w%');
        }
        return any;
      })
      ..limit(60);
    final rows = await query.get();
    int score(Quote q) {
      final hay = '${q.content} ${q.tags} ${q.author}'.toLowerCase();
      return words.where(hay.contains).length;
    }

    rows.shuffle(Random());
    rows.sort((a, b) => score(b).compareTo(score(a)));
    return [
      for (final q in rows.take(limit))
        ThreadMessage.fromQuote(QuoteDto.fromQuote(q)),
    ];
  }
}
