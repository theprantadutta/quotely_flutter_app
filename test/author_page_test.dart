import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/database/database.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';
import 'package:quotely_flutter_app/services/author_page_service.dart';
import 'package:quotely_flutter_app/services/drift_author_service.dart';
import 'package:quotely_flutter_app/services/drift_quote_service.dart';
import 'package:quotely_flutter_app/services/retractions.dart';

final _t0 = DateTime.utc(2026, 11, 1);

QuoteDto _q(
  String id, {
  String slug = 'seneca',
  String author = 'Seneca',
  String content = 'Luck is what happens when preparation meets opportunity.',
  List<String> tags = const ['wisdom'],
  int day = 0,
  bool favorite = false,
}) => QuoteDto(
  id: id,
  author: author,
  content: content,
  tags: tags,
  authorSlug: slug,
  length: content.length,
  isFavorite: favorite,
  dateAdded: _t0.add(Duration(days: day)),
  dateModified: _t0.add(Duration(days: day)),
);

AuthorDto _author(String slug, String name, {String bio = ''}) => AuthorDto(
  id: slug,
  name: name,
  bio: bio,
  description: '',
  link: '',
  quoteCount: 0,
  slug: slug,
  dateAdded: _t0,
  dateModified: _t0,
  imageUrl: 'https://img/$slug.jpg',
);

void main() {
  group('AuthorLifespan', () {
    for (final (text, expected) in [
      ('Albert Einstein (1879–1955) was a physicist.', '1879 – 1955'),
      ('Ada Lovelace (1815 - 1852), mathematician', '1815 – 1852'),
      (
        'Albert Einstein (March 14, 1879 – April 18, 1955) was...',
        '1879 – 1955',
      ),
      ('Seneca (c. 4 BC – AD 65) was a Stoic.', 'c. 4 BC – AD 65'),
      ('Marcus Aurelius (121 to 180) was emperor.', '121 – 180'),
      ('Taylor Swift (born 1989) is a singer.', 'Born 1989'),
      ('Laozi was a 6th-century BC Chinese philosopher.', '6th century BC'),
      ('Rumi was a 13th century Persian poet.', '13th century'),
    ]) {
      test(text, () => expect(AuthorLifespan.parse(text), expected));
    }

    for (final text in [
      'No dates here at all.',
      'Wrote 5-10 books (5 - 10).',
      'A reversed range (1955–1879).',
      'Too long a life (1200–1900).',
      'Lived far ahead (2100–2190).',
      '(Greek philosopher - stoic)',
    ]) {
      test('none in "$text"', () => expect(AuthorLifespan.parse(text), null));
    }

    test('reads the bio first, then the description', () {
      final a = AuthorDto(
        id: 'x',
        name: 'X',
        bio: 'A writer.',
        description: 'Poet (1907–1973)',
        link: '',
        quoteCount: 1,
        slug: 'x',
        dateAdded: _t0,
        dateModified: _t0,
        imageUrl: null,
      );
      expect(AuthorLifespan.of(a), '1907 – 1973');
    });
  });

  group('Most loved', () {
    test('saves first, then the ranking, no repeats, no unclean text', () {
      final merged = AuthorPageService.mergeMostLoved(
        saved: [_q('s1'), _q('r1')],
        ranked: [
          _q('r1'),
          _q('bad', content: 'Sure! Here is {json}'),
          _q('r2'),
        ],
        count: 5,
      );
      expect(merged.map((q) => q.id), ['s1', 'r1', 'r2']);
    });

    test('leaves out a saved quote the checks retracted', () {
      Retractions.resetForTest({
        'quote:s1': const Retraction(reason: 'misattributed'),
      });
      addTearDown(Retractions.resetForTest);
      final merged = AuthorPageService.mergeMostLoved(
        saved: [_q('s1'), _q('s2')],
        ranked: [_q('r1')],
        count: 5,
      );
      expect(merged.map((q) => q.id), ['s2', 'r1']);
    });

    test('keeps to the count', () {
      final merged = AuthorPageService.mergeMostLoved(
        saved: [_q('a'), _q('b')],
        ranked: [_q('c'), _q('d')],
        count: 3,
      );
      expect(merged.map((q) => q.id), ['a', 'b', 'c']);
    });

    test('offline fallback prefers the most quotable length', () {
      final picked = AuthorPageService.mostQuotable([
        _q('long', content: List.filled(30, 'Time heals all.').join(' ')),
        _q(
          'ideal',
          content:
              'We suffer more often in imagination than in reality, said the old Stoic.',
        ),
        _q('short', content: 'Begin at once to live.'),
      ], 2);
      expect(picked.map((q) => q.id), ['ideal', 'short']);
    });
  });

  test('local paging is used only once every quote is on the device', () {
    expect(AuthorPageService.localIsComplete(local: 0, expected: 0), false);
    expect(AuthorPageService.localIsComplete(local: 3, expected: 40), false);
    expect(AuthorPageService.localIsComplete(local: 40, expected: 40), true);
    // A stale count on the author row must not force the network forever.
    expect(AuthorPageService.localIsComplete(local: 12, expected: 0), true);
  });

  test('From people you follow keeps to two per author, newest first', () {
    final picked = AuthorPageService.pickFromFollowed(
      [
        _q('a3', slug: 'a', day: 3),
        _q('a2', slug: 'a', day: 2),
        _q('b2', slug: 'b', day: 2),
        _q('a1', slug: 'a', day: 1),
        _q('b1', slug: 'b', day: 1, content: '**broken** {x}'),
        _q('b0', slug: 'b', day: 0),
      ],
      limit: 10,
      perAuthor: 2,
    );
    expect(picked.map((q) => q.id), ['a3', 'a2', 'b2', 'b0']);
  });

  group('local database', () {
    setUp(() {
      getIt.registerSingleton<AppDatabase>(
        AppDatabase.forTesting(NativeDatabase.memory()),
      );
    });
    tearDown(() async {
      await getIt.get<AppDatabase>().close();
      await getIt.reset(dispose: false);
    });

    test('pages an author locally, skipping what is shown', () async {
      await DriftQuoteService.saveNewQuotesToDatabase([
        for (var i = 0; i < 5; i++) _q('s$i'),
        _q('other', slug: 'rumi'),
      ]);
      expect(await AuthorPageService.localCount('seneca'), 5);

      final first = await AuthorPageService.localPage(
        'seneca',
        page: 1,
        pageSize: 3,
        seed: 7,
      );
      final second = await AuthorPageService.localPage(
        'seneca',
        page: 2,
        pageSize: 3,
        seed: 7,
      );
      expect(first.fetched, 3);
      expect(second.fetched, 2);
      expect(
        {...first.quotes.map((q) => q.id), ...second.quotes.map((q) => q.id)},
        {for (var i = 0; i < 5; i++) 's$i'},
      );

      final rest = await AuthorPageService.localPage(
        'seneca',
        page: 1,
        pageSize: 100,
        seed: 7,
        skip: {'s0', 's1'},
      );
      expect(rest.quotes.map((q) => q.id).toSet(), {'s2', 's3', 's4'});
    });

    test(
      'related authors share the telling tags, not the common ones',
      () async {
        await DriftAuthorService.saveAuthorsToDatabase([
          _author('seneca', 'Seneca'),
          _author('epictetus', 'Epictetus'),
          _author('oprah', 'Oprah Winfrey'),
          _author('ghost', 'Ghost Writer'),
        ]);
        await DriftQuoteService.saveNewQuotesToDatabase([
          for (var i = 0; i < 4; i++)
            _q('s$i', tags: ['stoicism', 'famous-quotes']),
          for (var i = 0; i < 3; i++)
            _q('e$i', slug: 'epictetus', tags: ['stoicism']),
          for (var i = 0; i < 6; i++)
            _q('o$i', slug: 'oprah', tags: ['famous-quotes']),
          // As in the real library, "famous-quotes" is on almost everything.
          for (var i = 0; i < 40; i++)
            _q('f$i', slug: 'filler$i', tags: ['famous-quotes']),
          // Quotes by an author the device has no row for are left out.
          _q('g0', slug: 'nobody', tags: ['stoicism']),
        ]);

        final related = await AuthorPageService.related('seneca');
        expect(related.map((a) => a.slug).first, 'epictetus');
        expect(related.map((a) => a.slug), isNot(contains('seneca')));
        expect(related.map((a) => a.slug), isNot(contains('nobody')));
      },
    );

    test('From people you follow reads followed authors with photos', () async {
      await DriftAuthorService.saveAuthorsToDatabase([
        _author('seneca', 'Seneca'),
      ]);
      await DriftQuoteService.saveNewQuotesToDatabase([
        _q('old', day: 0),
        _q('new', day: 5),
        _q('not-followed', slug: 'rumi', day: 9),
      ]);

      final items = await AuthorPageService.fromFollowed({'seneca'});
      expect(items.map((i) => i.quote.id), ['new', 'old']);
      expect(items.first.imageUrl, 'https://img/seneca.jpg');
      expect(await AuthorPageService.fromFollowed(const {}), isEmpty);
    });
  });
}
