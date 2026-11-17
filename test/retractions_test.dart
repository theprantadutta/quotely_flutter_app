import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/constants/shared_preference_keys.dart';
import 'package:quotely_flutter_app/database/database.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';
import 'package:quotely_flutter_app/services/retractions.dart';
import 'package:quotely_flutter_app/services/saved_feed_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _old = DateTime(2025, 1, 1);

Quote _quote(String id, {bool saved = true}) => Quote(
  id: id,
  author: 'Abraham Lincoln',
  content: 'Quote $id',
  tags: '',
  authorSlug: 'abraham-lincoln',
  length: 7,
  isFavorite: saved,
  dateAdded: _old,
  dateModified: _old,
);

Fact _fact(int id, {bool saved = true}) => Fact(
  id: id,
  content: 'Fact $id',
  aiFactCategory: 'Space',
  provider: 'x',
  isFavorite: saved,
  dateAdded: _old,
  dateModified: _old,
);

const _body = '''
{"generatedAt":"2026-11-17T10:00:00Z",
 "quotes":[{"id":"q1","reason":"misattributed","probablyBy":"Mark Twain","replacementId":"r9"},
           {"id":"q2","reason":"not_verified","probablyBy":null,"replacementId":null}],
 "facts":[{"id":"7","reason":"not_accurate"}]}
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parsing and notes', () {
    test('parses the endpoint into keyed retractions', () {
      final map = Retractions.parseResponse(_body)!;
      expect(map.keys, containsAll(['quote:q1', 'quote:q2', 'fact:7']));
      expect(map['quote:q1']!.probablyBy, 'Mark Twain');
      expect(map['quote:q1']!.replacementId, 'r9');
      expect(map['quote:q2']!.probablyBy, isNull);
    });

    test('a body of the wrong shape is ignored', () {
      expect(Retractions.parseResponse('[]'), isNull);
      expect(Retractions.parseResponse('not json'), isNull);
      expect(Retractions.parseResponse('{"quotes":[]}'), isNull);
    });

    test('notes are honest and short', () {
      final map = Retractions.parseResponse(_body)!;
      expect(
        map['quote:q1']!.note(author: 'Abraham Lincoln'),
        'Our checks found this is probably by Mark Twain, not Abraham Lincoln.',
      );
      expect(
        map['quote:q2']!.note(author: 'Abraham Lincoln'),
        'Our checks couldn’t confirm Abraham Lincoln said this.',
      );
      expect(
        map['fact:7']!.note(),
        'Our fact-check found this isn’t accurate.',
      );
    });

    test('stored map survives an encode and decode', () {
      final map = Retractions.parseResponse(_body)!;
      final at = DateTime.utc(2026, 11, 17, 10);
      final back = Retractions.decode(Retractions.encode(map, at));
      expect(back.at, at);
      expect(back.map['quote:q1']!.replacementId, 'r9');
      expect(back.map.length, 3);
      expect(Retractions.decode('garbage').map, isEmpty);
    });
  });

  group('sync against the local database', () {
    late AppDatabase db;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(NativeDatabase.memory());
      getIt.registerSingleton<AppDatabase>(db);
      Retractions.resetForTest();
      Retractions.fetch = () async => _body;
    });

    tearDown(() async {
      await getIt.reset(dispose: false);
      await db.close();
    });

    test(
      'drops unsaved copies, keeps saved ones, and remembers them',
      () async {
        await db.into(db.quotes).insert(_quote('q1')); // saved, hidden
        await db
            .into(db.quotes)
            .insert(_quote('q2', saved: false)); // unsaved, hidden
        await db
            .into(db.quotes)
            .insert(_quote('ok', saved: false)); // untouched
        await db
            .into(db.facts)
            .insert(_fact(7, saved: false)); // unsaved, hidden

        await Retractions.sync(now: DateTime(2026, 11, 17));

        final quoteIds = (await db.select(db.quotes).get())
            .map((q) => q.id)
            .toSet();
        expect(quoteIds, {'q1', 'ok'});
        expect(await db.select(db.facts).get(), isEmpty);
        expect(Retractions.isRetracted('quote:q1'), isTrue);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(kRetractionsKey), contains('quote:q1'));
      },
    );

    test('a failed fetch changes nothing', () async {
      await db.into(db.quotes).insert(_quote('q2', saved: false));
      Retractions.fetch = () async => null;
      await Retractions.sync(now: DateTime(2026, 11, 17));
      expect(await db.select(db.quotes).get(), hasLength(1));
      expect(Retractions.current.value, isEmpty);
    });

    test('maybeSync waits a day between fetches', () async {
      var calls = 0;
      Retractions.fetch = () async {
        calls++;
        return _body;
      };
      await Retractions.maybeSync(now: DateTime(2026, 11, 17, 8));
      await Retractions.maybeSync(now: DateTime(2026, 11, 17, 20));
      await Retractions.maybeSync(now: DateTime(2026, 11, 18, 9));
      expect(calls, 2);
    });
  });

  test('Revisit never features a retracted line', () {
    final today = DateTime(2026, 11, 17);
    SavedEntry entry(String id) => SavedEntry(
      message: ThreadMessage.fromQuote(QuoteDto.fromQuote(_quote(id))),
      savedAt: DateTime(2026, 10, 1),
      fallback: _old,
    );
    final entries = [entry('q1')];
    Retractions.resetForTest();
    expect(SavedFeedService.revisitFor(entries, today)?.key, 'quote:q1');
    Retractions.resetForTest({
      'quote:q1': const Retraction(reason: 'misattributed'),
    });
    expect(SavedFeedService.revisitFor(entries, today), isNull);
    Retractions.resetForTest();
  });
}
