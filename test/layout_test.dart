import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/thread/thread.dart';
import 'package:quotely_flutter_app/riverpods/backdrop_poster_provider.dart';
import 'package:quotely_flutter_app/riverpods/scene_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _page() => ProviderScope(
  overrides: [
    sceneOfTheDayProvider.overrideWith((ref) async => null),
    fallbackPosterProvider.overrideWith((ref) async => null),
  ],
  child: MaterialApp(
    theme: buildQuotelyTheme(Brightness.light, const AppearanceSettings()),
    home: const ThreadPage(
      title: 'Detail',
      showHeader: false,
      body: SizedBox.expand(key: Key('body')),
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> sized(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_page());
    await tester.pump();
  }

  testWidgets('tablets get a centred reading column, backdrop full-bleed', (
    tester,
  ) async {
    await sized(tester, const Size(1024, 1366));
    final body = tester.getRect(find.byKey(const Key('body')));
    expect(body.width, kThreadMaxWidth);
    expect(body.width, inInclusiveRange(640, 720));
    expect(body.center.dx, 512);
    expect(tester.getSize(find.byType(PageBackdrop)).width, 1024);
  });

  testWidgets('phones keep the full width', (tester) async {
    await sized(tester, const Size(412, 915));
    expect(tester.getSize(find.byKey(const Key('body'))).width, 412);
  });
}
