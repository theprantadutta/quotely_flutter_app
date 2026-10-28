import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/dtos/media_title_dto.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/dtos/scene_quote_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: buildQuotelyTheme(Brightness.light, const AppearanceSettings()),
    home: Scaffold(body: child),
  ),
);

final _d = DateTime.utc(2026);

final _quote = QuoteDto(
  id: 'q',
  author: 'Nelson Mandela',
  content: 'It always seems impossible until it’s done.',
  tags: const ['hope'],
  authorSlug: 'nelson-mandela',
  length: 44,
  dateAdded: _d,
  dateModified: _d,
);

/// Labels of every node in the tree, in traversal order.
List<String> _labels(WidgetTester tester) {
  final out = <String>[];
  void visit(SemanticsNode n) {
    if (n.label.isNotEmpty) out.add(n.label);
    n.visitChildren((c) {
      visit(c);
      return true;
    });
  }

  final owner = tester.renderObject(find.byType(Scaffold)).owner!;
  visit(owner.semanticsOwner!.rootSemanticsNode!);
  return out;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a feed entry reads the line, then who said it', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Row(
          children: [
            Expanded(
              child: SpotlightEntry(
                message: ThreadMessage.fromQuote(_quote),
                eyebrow: 'Quote of the day',
              ),
            ),
            SpotlightRail(
              message: ThreadMessage.fromQuote(_quote),
              onAsk: () {},
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    final labels = _labels(tester);
    final line = labels.indexOf(_quote.content);
    final who = labels.indexWhere((l) => l.startsWith('Nelson Mandela'));
    expect(line, isNot(-1), reason: '$labels');
    expect(who, greaterThan(line), reason: '$labels');
    // Said once, not prefixed to the line.
    expect(labels.where((l) => l.contains('Nelson Mandela:')), isEmpty);

    expect(find.bySemanticsLabel(RegExp(r'^Nelson Mandela')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(RegExp(r'^Nelson Mandela')))
          .flagsCollection
          .isButton,
      isTrue,
    );
    for (final action in ['Save', 'Share', 'More', 'Ask']) {
      expect(find.bySemanticsLabel(action), findsOneWidget, reason: action);
    }

    // ActivityService batches its write behind a short timer.
    await tester.pump(const Duration(seconds: 3));
    handle.dispose();
  });

  testWidgets('a hidden spoiler is not read out', (tester) async {
    final handle = tester.ensureSemantics();
    final scene = SceneQuoteDto(
      id: 's',
      content: 'Bruce Willis was dead the whole time.',
      titleId: 't',
      titleName: 'A Film',
      titleType: MediaType.movie,
      titleYear: 1999,
      characterId: 'c',
      characterName: 'Someone',
      tags: const [],
      isSpoiler: true,
      dateAdded: _d,
      dateModified: _d,
    );
    await tester.pumpWidget(
      _host(SpotlightEntry(message: ThreadMessage.fromScene(scene))),
    );
    await tester.pump();

    final labels = _labels(tester);
    expect(labels.where((l) => l.contains('Bruce Willis')), isEmpty);
    expect(find.bySemanticsLabel('Tap to reveal spoiler'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    handle.dispose();
  });
}
