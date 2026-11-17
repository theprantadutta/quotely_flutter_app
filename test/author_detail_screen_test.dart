import 'package:drift/native.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/constants/shared_preference_keys.dart';
import 'package:quotely_flutter_app/database/database.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/riverpods/get_author_detail_provider.dart';
import 'package:quotely_flutter_app/screens/author_detail_screen.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';
import 'package:quotely_flutter_app/services/drift_author_service.dart';
import 'package:quotely_flutter_app/services/drift_quote_service.dart';
import 'package:quotely_flutter_app/services/notification_service.dart';
import 'package:quotely_flutter_app/state_providers/scene_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAnalytics implements FirebaseAnalytics {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

final _t0 = DateTime.utc(2026, 11, 1);

AuthorDto _author(String slug, String name, {int count = 0}) => AuthorDto(
  id: slug,
  name: name,
  bio:
      'Lucius Annaeus Seneca (c. 4 BC – AD 65) was a Roman Stoic philosopher, '
      'statesman and dramatist. He tutored and later advised the emperor Nero, '
      'wrote letters on how to live well, and left essays on anger, the '
      'shortness of life and the tranquillity of the mind that are still read '
      'for their plain, practical advice about time, fear and friendship.',
  description: 'Stoic philosopher',
  link: '',
  quoteCount: count,
  slug: slug,
  dateAdded: _t0,
  dateModified: _t0,
  imageUrl: null,
);

QuoteDto _q(String id, String content, {String slug = 'seneca'}) => QuoteDto(
  id: id,
  author: slug == 'seneca' ? 'Seneca' : 'Epictetus',
  content: content,
  tags: const ['stoicism'],
  authorSlug: slug,
  length: content.length,
  dateAdded: _t0,
  dateModified: _t0,
);

const _lines = [
  'We suffer more often in imagination than in reality.',
  'Luck is what happens when preparation meets opportunity.',
  'Difficulties strengthen the mind, as labor does the body.',
  'It is not that we have a short time to live, but that we waste a lot of it.',
  'While we teach, we learn.',
  'Begin at once to live, and count each separate day as a separate life.',
  'Associate with people who are likely to improve you.',
  'He who is brave is free.',
];

Widget _app() => ProviderScope(
  overrides: [
    fetchAuthorDetailProvider(
      'seneca',
    ).overrideWith((ref) async => _author('seneca', 'Seneca', count: 8)),
  ],
  child: MaterialApp.router(
    theme: buildQuotelyTheme(Brightness.light, const AppearanceSettings()),
    routerConfig: GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const AuthorDetailScreen(authorSlug: 'seneca'),
        ),
      ],
    ),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late List<String> subscribed;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      kAcceptedLegalVersionKey: kCurrentLegalVersion,
      kNotificationDefaultsKey: 'calm',
    });
    subscribed = [];
    FollowedAuthors.notifications = () =>
        NotificationService(subscribe: (t) async => subscribed.add(t));
    getIt.registerSingleton<FirebaseAnalytics>(_FakeAnalytics());
    getIt.registerSingleton<AppDatabase>(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
    await DriftAuthorService.saveAuthorsToDatabase([
      _author('seneca', 'Seneca', count: 8),
      _author('epictetus', 'Epictetus'),
    ]);
    await DriftQuoteService.saveNewQuotesToDatabase([
      for (var i = 0; i < _lines.length; i++) _q('s$i', _lines[i]),
      _q(
        'e0',
        'No man is free who is not master of himself.',
        slug: 'epictetus',
      ),
      // Most of the library is about other things, so "stoicism" is telling.
      for (var i = 0; i < 20; i++)
        QuoteDto(
          id: 'x$i',
          author: 'Other $i',
          content: 'Another quote number $i about something else entirely.',
          tags: const ['life'],
          authorSlug: 'other-$i',
          length: 50,
          dateAdded: _t0,
          dateModified: _t0,
        ),
    ]);
    // The reader saved the shortest line, which would otherwise rank last.
    await DriftQuoteService.changeQuoteUpdateStatus(_q('s7', _lines[7]), true);
  });

  tearDown(() async {
    FollowedAuthors.notifications = NotificationService.new;
    await getIt.reset(dispose: false);
  });

  testWidgets('offline: bio, lifespan, Most loved, all quotes, related', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 9000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await _settle(tester);

    expect(find.text('Stoic philosopher · c. 4 BC – AD 65'), findsOneWidget);
    expect(find.text('8 quotes'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    expect(find.text('MOST LOVED'), findsOneWidget);
    expect(find.text('ALL QUOTES'), findsOneWidget);
    final allQuotesY = tester.getTopLeft(find.text('ALL QUOTES')).dy;
    // The reader's save leads Most loved.
    expect(
      tester.getTopLeft(find.textContaining(_lines[7])).dy,
      lessThan(allQuotesY),
    );
    // Every quote appears exactly once across both sections.
    for (final line in _lines) {
      expect(find.textContaining(line), findsOneWidget, reason: line);
    }

    expect(find.text('RELATED'), findsOneWidget);
    expect(find.text('Epictetus'), findsOneWidget);

    await tester.tap(find.text('More'));
    await _settle(tester);
    expect(find.text('Less'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Follow'));
    await _settle(tester);
    expect(find.text('✓ Following'), findsOneWidget);
    expect(subscribed, ['author_seneca']);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });
}
