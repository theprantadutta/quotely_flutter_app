import 'dart:convert';
import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../constants/urls.dart';
import '../database/database.dart';
import '../database/seeded_order.dart';
import '../dtos/author_dto.dart';
import '../dtos/quote_dto.dart';
import '../dtos/quote_response_dto.dart';
import '../service_locator/init_service_locators.dart';
import '../util/profanity.dart';
import 'drift_quote_service.dart';
import 'http_service.dart';
import 'local_first.dart';

/// Everything below the author page's header, offline first.
///
/// - [mostLoved]: the reader's own saves, then the backend's ranking (a saved
///   copy of it offline), then the most quotable local quotes.
/// - [allQuotes]: pages. From the local database once it holds every quote
///   the author has, otherwise from the backend (saved as it goes) with the
///   local copy as the offline fallback.
/// - [related]: authors whose quotes share this one's most telling tags,
///   from the local database only.
class AuthorPageService {
  AuthorPageService._();

  static AppDatabase get _db => getIt.get<AppDatabase>();

  /// The length a quote reads best at, in characters (as on the backend).
  static const idealLength = 90;

  // --- Most loved --------------------------------------------------------

  static Future<List<QuoteDto>> mostLoved(String slug, {int count = 5}) async {
    final saved =
        await (_db.select(_db.quotes)
              ..where(
                (q) => q.authorSlug.equals(slug) & q.isFavorite.equals(true),
              )
              ..orderBy([(q) => OrderingTerm.desc(q.dateModified)])
              ..limit(count))
            .get();

    var ranked = <QuoteDto>[];
    try {
      final url = Uri.parse(
        '$kApiUrl/$kGetMostLovedQuotesByAuthor',
      ).replace(queryParameters: {'authorSlug': slug, 'count': '$count'});
      final response = await LocalFirst.get(url.toString());
      if (response.statusCode == 200 && response.data is String) {
        ranked = QuoteResponseDto.fromJson(
          json.decode(response.data as String) as Map<String, dynamic>,
        ).quotes;
        if (ranked.isNotEmpty) {
          await DriftQuoteService.saveNewQuotesToDatabase(ranked);
        }
      }
    } catch (_) {
      // Offline with no saved copy, or an API without the endpoint.
    }

    if (ranked.isEmpty) {
      final local =
          await (_db.select(_db.quotes)
                ..where((q) => q.authorSlug.equals(slug))
                ..limit(200))
              .get();
      ranked = mostQuotable(QuoteDto.fromQuoteList(local), count);
    }

    return mergeMostLoved(
      saved: QuoteDto.fromQuoteList(saved),
      ranked: ranked,
      count: count,
    );
  }

  /// The reader's saves first, then [ranked], without repeats or quotes
  /// that fail the content check.
  static List<QuoteDto> mergeMostLoved({
    required List<QuoteDto> saved,
    required List<QuoteDto> ranked,
    required int count,
  }) {
    final seen = <String>{};
    return [
      for (final q in [...saved, ...ranked])
        if (isClean(q.content) && seen.add(q.id)) q,
    ].take(count).toList();
  }

  /// The quotes closest to [idealLength], ties broken by id.
  static List<QuoteDto> mostQuotable(List<QuoteDto> quotes, int count) {
    int distance(QuoteDto q) => (q.content.trim().length - idealLength).abs();
    final sorted = [...quotes.where((q) => isClean(q.content))]
      ..sort((a, b) {
        final d = distance(a).compareTo(distance(b));
        return d != 0 ? d : a.id.compareTo(b.id);
      });
    return sorted.take(count).toList();
  }

  // --- All quotes --------------------------------------------------------

  static Future<int> localCount(String slug) async {
    final count = _db.quotes.id.count();
    final row =
        await (_db.selectOnly(_db.quotes)
              ..addColumns([count])
              ..where(_db.quotes.authorSlug.equals(slug)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Whether the local database already has every quote the author has, so
  /// paging can stay on the device.
  static bool localIsComplete({required int local, required int expected}) =>
      local > 0 && local >= expected;

  /// One page from the local database, in the session's shuffled order.
  /// [fetched] counts rows before the content check, for "is there more".
  static Future<({List<QuoteDto> quotes, int fetched})> localPage(
    String slug, {
    required int page,
    required int pageSize,
    required int seed,
    Set<String> skip = const {},
  }) async {
    final rows =
        await (_db.select(_db.quotes)
              ..where(
                (q) => q.authorSlug.equals(slug) & q.id.isNotIn(skip.toList()),
              )
              ..orderBy([(_) => seededOrder(seed)])
              ..limit(pageSize, offset: (page - 1) * pageSize))
            .get();
    return (
      quotes: [
        for (final q in QuoteDto.fromQuoteList(rows))
          if (isClean(q.content)) q,
      ],
      fetched: rows.length,
    );
  }

  /// One page from the backend, saved locally. Throws when offline; the
  /// screen then carries on from [localPage].
  static Future<({List<QuoteDto> quotes, int fetched})> remotePage(
    String slug, {
    required int page,
    required int pageSize,
    required int seed,
  }) async {
    final uri = Uri.parse('$kApiUrl/$kGetAllQuotesByAuthor').replace(
      queryParameters: {
        'authorSlug': slug,
        'pageNumber': '$page',
        'pageSize': '$pageSize',
        'seed': '$seed',
      },
    );
    final response = await HttpService.get(uri.toString());
    if (response.statusCode != 200) {
      throw Exception('Quotes by author failed: ${response.statusCode}');
    }
    final dto = QuoteResponseDto.fromJson(json.decode(response.data));
    await DriftQuoteService.saveNewQuotesToDatabase(dto.quotes);
    return (
      quotes: [
        for (final q in dto.quotes)
          if (isClean(q.content)) q,
      ],
      fetched: dto.quotes.length,
    );
  }

  // --- Related authors ---------------------------------------------------

  /// Up to [limit] authors who share this author's most telling tags: each
  /// tag weighs its share of this author's quotes times how rare it is
  /// overall, so "famous-quotes" counts for little and "stoicism" for a lot.
  static Future<List<AuthorDto>> related(String slug, {int limit = 8}) async {
    final own =
        await (_db.selectOnly(_db.quotes)
              ..addColumns([_db.quotes.tags])
              ..where(_db.quotes.authorSlug.equals(slug)))
            .map((r) => r.read(_db.quotes.tags) ?? '')
            .get();
    if (own.isEmpty) return const [];

    final tagCounts = <String, int>{};
    for (final raw in own) {
      for (final tag in raw.split(',')) {
        final t = tag.trim();
        if (t.isNotEmpty) tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    final topTags =
        (tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .take(5)
            .toList();
    if (topTags.isEmpty) return const [];

    final total = await _count('SELECT COUNT(*) AS n FROM quotes', const []);
    final scores = <String, double>{};
    for (final tag in topTags) {
      final pattern = '%,${tag.key},%';
      final withTag = await _count(
        "SELECT COUNT(*) AS n FROM quotes WHERE (',' || tags || ',') LIKE ?",
        [pattern],
      );
      final weight =
          (tag.value / own.length) *
          math.log((total + 1) / (withTag + 1)).clamp(0.0, 20.0);
      if (weight <= 0) continue;
      final rows = await _db
          .customSelect(
            "SELECT author_slug, COUNT(*) AS n FROM quotes "
            "WHERE author_slug <> ? AND (',' || tags || ',') LIKE ? "
            'GROUP BY author_slug ORDER BY n DESC LIMIT 30',
            variables: [Variable(slug), Variable(pattern)],
            readsFrom: {_db.quotes},
          )
          .get();
      for (final r in rows) {
        final other = r.read<String>('author_slug');
        scores[other] = (scores[other] ?? 0) + weight * r.read<int>('n');
      }
    }
    if (scores.isEmpty) return const [];

    final ranked =
        (scores.entries.toList()..sort((a, b) {
              final d = b.value.compareTo(a.value);
              return d != 0 ? d : a.key.compareTo(b.key);
            }))
            .map((e) => e.key)
            .take(limit * 2)
            .toList();
    final authors = await (_db.select(
      _db.authors,
    )..where((a) => a.slug.isIn(ranked))).get();
    final bySlug = {for (final a in authors) a.slug: a};
    return [
      for (final s in ranked)
        if (bySlug[s] != null) AuthorDto.fromDrift(bySlug[s]!),
    ].take(limit).toList();
  }

  // --- From people you follow -------------------------------------------

  /// The newest local quotes by [slugs], at most [perAuthor] each so one
  /// prolific author doesn't fill the strip, newest first.
  static Future<List<FollowedQuote>> fromFollowed(
    Set<String> slugs, {
    int limit = 12,
    int perAuthor = 2,
  }) async {
    if (slugs.isEmpty) return const [];
    final rows =
        await (_db.select(_db.quotes)
              ..where((q) => q.authorSlug.isIn(slugs))
              ..orderBy([
                (q) => OrderingTerm.desc(q.dateAdded),
                (q) => OrderingTerm.asc(q.id),
              ])
              ..limit(300))
            .get();
    final picked = pickFromFollowed(
      QuoteDto.fromQuoteList(rows),
      limit: limit,
      perAuthor: perAuthor,
    );
    final authors = await (_db.select(
      _db.authors,
    )..where((a) => a.slug.isIn(picked.map((q) => q.authorSlug)))).get();
    final bySlug = {for (final a in authors) a.slug: a};
    return [
      for (final q in picked)
        FollowedQuote(quote: q, imageUrl: bySlug[q.authorSlug]?.imageUrl),
    ];
  }

  /// [newestFirst] trimmed to [perAuthor] per author and [limit] in all,
  /// skipping quotes that fail the content check.
  static List<QuoteDto> pickFromFollowed(
    List<QuoteDto> newestFirst, {
    required int limit,
    required int perAuthor,
  }) {
    final perSlug = <String, int>{};
    final out = <QuoteDto>[];
    for (final q in newestFirst) {
      if (out.length >= limit) break;
      if (!isClean(q.content)) continue;
      final n = perSlug[q.authorSlug] ?? 0;
      if (n >= perAuthor) continue;
      perSlug[q.authorSlug] = n + 1;
      out.add(q);
    }
    return out;
  }

  static Future<int> _count(String sql, List<String> args) async {
    final row = await _db
        .customSelect(
          sql,
          variables: [for (final a in args) Variable(a)],
          readsFrom: {_db.quotes},
        )
        .getSingle();
    return row.read<int>('n');
  }
}

/// A quote in the "From people you follow" strip, with its author's photo.
class FollowedQuote {
  final QuoteDto quote;
  final String? imageUrl;
  const FollowedQuote({required this.quote, this.imageUrl});
}

/// A lifespan or era read out of an author's bio or description:
/// "(1879–1955)" → "1879 – 1955", "(born 1952)" → "Born 1952",
/// "(c. 4 BC – AD 65)" → "c. 4 BC – AD 65", "5th-century BC" → "5th century BC".
/// Null when the text has none: the backend has no dates of its own.
class AuthorLifespan {
  AuthorLifespan._();

  static String? of(AuthorDto author) =>
      parse(author.bio) ?? parse(author.description);

  static final _paren = RegExp(r'\(([^()]{1,80})\)');
  static final _range = RegExp(r'\s*(?:[–—]|-{1,2}|\bto\b)\s*');
  static final _born = RegExp(r'^(?:born|b\.)\s+(.+)$', caseSensitive: false);
  static final _year = RegExp(
    r'(c\.\s*|ca\.\s*|circa\s+)?(?:(AD|CE)\s*)?(\d{1,4})\s*(BC|BCE|AD|CE)?\s*$',
    caseSensitive: false,
  );
  static final _century = RegExp(
    r'\b(\d{1,2})(st|nd|rd|th)[\s-]century(?:\s+(BC|BCE|AD|CE))?',
    caseSensitive: false,
  );

  static String? parse(String text) {
    for (final m in _paren.allMatches(text)) {
      final inner = m.group(1)!.trim();
      final born = _born.firstMatch(inner);
      if (born != null) {
        final y = _readYear(born.group(1)!);
        if (y != null) return 'Born ${y.label}';
        continue;
      }
      final parts = inner.split(_range);
      if (parts.length != 2) continue;
      final a = _readYear(parts[0]);
      final b = _readYear(parts[1]);
      if (a == null || b == null || a.value > b.value) continue;
      if (b.value - a.value > 120) continue;
      return '${a.label} – ${b.label}';
    }
    final c = _century.firstMatch(text);
    if (c != null) {
      final era = c.group(3)?.toUpperCase();
      return '${c.group(1)}${c.group(2)!.toLowerCase()} century'
          '${era == null ? '' : ' $era'}';
    }
    return null;
  }

  /// The year at the end of [s] (month and day before it are ignored),
  /// signed so BC sorts before AD.
  static ({int value, String label})? _readYear(String s) {
    final m = _year.firstMatch(s.trim().replaceAll(RegExp(r'[.,;]+$'), ''));
    if (m == null) return null;
    final digits = m.group(3)!;
    final eraBefore = m.group(2)?.toUpperCase();
    final eraAfter = m.group(4)?.toUpperCase();
    final era = eraAfter ?? eraBefore;
    final bc = era == 'BC' || era == 'BCE';
    // A bare number needs to look like a year: "(5-10)" is not a lifespan.
    if (era == null && digits.length < 3) return null;
    final n = int.parse(digits);
    if (!bc && n > DateTime.now().year) return null;
    final circa = m.group(1) == null ? '' : 'c. ';
    final label = eraBefore != null && eraAfter == null
        ? '$circa$eraBefore $n'
        : '$circa$n${era == null ? '' : ' $era'}';
    return (value: bc ? -n : n, label: label);
  }
}
