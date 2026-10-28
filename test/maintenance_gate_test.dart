import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/maintenance_gate.dart';
import 'package:quotely_flutter_app/dtos/application_info_dto.dart';
import 'package:quotely_flutter_app/riverpods/application_info_provider.dart';
import 'package:quotely_flutter_app/riverpods/scene_providers.dart';
import 'package:quotely_flutter_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

ApplicationInfoDto _info({required bool maintenance}) => ApplicationInfoDto(
  id: 'x',
  maintenanceBreak: maintenance,
  currentVersion: '3.0.1',
  appUpdateUrl: '',
);

/// The gate over a stand-in app, with settings from [info] and no network
/// (the poster backdrop falls back to the glow).
Widget _host(Future<ApplicationInfoDto?> Function() info) => ProviderScope(
  overrides: [
    fetchApplicationInfoProvider.overrideWith((ref) => info()),
    sceneOfTheDayProvider.overrideWith((ref) async => null),
  ],
  child: MaterialApp(
    theme: buildQuotelyTheme(Brightness.light, const AppearanceSettings()),
    builder: (context, child) => MaintenanceGate(child: child!),
    home: const Scaffold(body: Text('the app')),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('covers the app while maintenance is on', (tester) async {
    await tester.pumpWidget(_host(() async => _info(maintenance: true)));
    await tester.pumpAndSettle();

    expect(find.text("We'll be right back."), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
    expect(find.text('Read what you saved'), findsOneWidget);
  });

  testWidgets('stays out of the way when maintenance is off', (tester) async {
    await tester.pumpWidget(_host(() async => _info(maintenance: false)));
    await tester.pumpAndSettle();

    expect(find.text('the app'), findsOneWidget);
    expect(find.text("We'll be right back."), findsNothing);
  });

  testWidgets('never blocks the app when settings fail to load', (tester) async {
    await tester.pumpWidget(_host(() async => null));
    await tester.pumpAndSettle();

    expect(find.text("We'll be right back."), findsNothing);
  });

  testWidgets('Check again re-reads the setting and releases the app', (
    tester,
  ) async {
    var maintenance = true;
    await tester.pumpWidget(
      _host(() async => _info(maintenance: maintenance)),
    );
    await tester.pumpAndSettle();
    expect(find.text("We'll be right back."), findsOneWidget);

    maintenance = false;
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();

    expect(find.text("We'll be right back."), findsNothing);
  });
}
