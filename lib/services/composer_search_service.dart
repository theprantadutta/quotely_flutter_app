import 'dart:math';

import 'package:drift/drift.dart';

import '../components/thread/thread_message.dart';
import '../constants/default_interests.dart';
import '../database/database.dart';
import '../dtos/media_title_dto.dart';
import '../dtos/quote_dto.dart';
import '../service_locator/init_service_locators.dart';
import 'drift_scene_service.dart';
import 'quote_service.dart';
import '../util/profanity.dart';

/// Answers the Today composer ("Ask for a quote about…").
///
/// TODO(backend): semantic quote search. The API has no search or AI
/// endpoint for quotes yet, so this matches the prompt locally: known tag
/// names go to the regular quotes endpoint (which falls back to the Drift
/// cache offline), media words ("anime", "movie") route to Scenes, and
/// anything else is a keyword match over cached quote text and authors.
class ComposerSearchService {
  ComposerSearchService._();

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
  static Future<List<ThreadMessage>> ask(String prompt, {int limit = 3}) async {
    final results = await _ask(prompt, limit);
    return [
      for (final m in results)
        if (isClean(m.text)) m,
    ];
  }

  static Future<List<ThreadMessage>> _ask(String prompt, int limit) async {
    final tokens = _tokens(prompt);
    if (tokens.isEmpty) return const [];

    final types = {
      for (final w in tokens)
        if (_mediaWords.containsKey(w)) _mediaWords[w]!,
    };
    final wantsScenes =
        types.isNotEmpty || prompt.toLowerCase().contains('scene');
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
