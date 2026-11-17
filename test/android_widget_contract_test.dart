// The contract between the Dart side and the Android home-screen widgets
// (android/app/src/main/kotlin/com/pranta/quotely/widget/): the receiver
// class names Dart updates and pins, the keys it saves, and the tap URLs.
// The widgets are native, so nothing else would notice if one side drifted.
//
// Reads the Kotlin sources and the manifest as text; run from the project
// root, as `flutter test` does.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/components/quote_widget_bridge.dart';
import 'package:quotely_flutter_app/services/home_widget_store.dart';

const _widgetDir = 'android/app/src/main/kotlin/com/pranta/quotely/widget';
const _manifest = 'android/app/src/main/AndroidManifest.xml';

/// The `res/xml/<name>_widget_info.xml` of each kind.
const _xmlName = {
  QuotelyWidgetKind.qotd: 'qotd',
  QuotelyWidgetKind.saved: 'saved',
  QuotelyWidgetKind.scene: 'scene',
  QuotelyWidgetKind.minimal: 'minimal',
  QuotelyWidgetKind.square: 'square',
};

/// Every Kotlin source of the widgets, by file name.
Map<String, String> _kotlinSources() => {
  for (final f in Directory(_widgetDir).listSync().whereType<File>())
    if (f.path.endsWith('.kt')) f.uri.pathSegments.last: f.readAsStringSync(),
};

/// The text of the Dart services, where the widget keys are saved.
String _dartServices() => [
  for (final f in Directory('lib/services').listSync().whereType<File>())
    if (f.path.endsWith('.dart')) f.readAsStringSync(),
].join('\n');

void main() {
  final kotlin = _kotlinSources();
  final manifest = File(_manifest).readAsStringSync();

  for (final kind in QuotelyWidgetKind.values) {
    group('${kind.label} (${kind.androidClass})', () {
      final file = '${kind.androidClass}.kt';
      final source = kotlin[file] ?? '';

      test('is a receiver in the manifest under the name Dart uses', () {
        expect(
          manifest,
          contains('android:name=".widget.${kind.androidClass}"'),
        );
        expect(
          kind.androidProvider,
          'com.pranta.quotely.widget.${kind.androidClass}',
        );
      });

      test('is a Glance widget receiver in $file', () {
        expect(source, isNotEmpty, reason: '$file is missing');
        expect(
          source,
          matches(
            RegExp('class ${kind.androidClass}\\s*:\\s*ArtWidgetReceiver<'),
          ),
        );
        expect(source, contains('override val kind = "${kind.id}"'));
      });

      test('opens the app with a URL Dart attributes to it', () {
        final match = RegExp(
          r'override val launchUri = "([^"]+)"',
        ).firstMatch(source);
        expect(match, isNotNull, reason: 'no launchUri in $file');
        final uri = Uri.parse(match!.group(1)!);
        expect(uri.scheme, 'quotely');
        expect(uri.queryParameters.containsKey('homeWidget'), isTrue);
        expect(uri.queryParameters['kind'], kind.id);
        expect(widgetKindOf(uri), kind);
      });
    });
  }

  test('every key the widgets read is one the app saves', () {
    final services = _dartServices();
    final keys = <String>{
      for (final source in kotlin.values)
        for (final m in RegExp(
          r'const val KEY_\w+ = "([^"]+)"',
        ).allMatches(source))
          m.group(1)!,
    };
    expect(
      keys,
      containsAll(<String>[
        'qotd_text',
        'qotd_author',
        'qotd_poster',
        'qotd_short',
        'qotd_eyebrow',
        'saved_days',
        'saved_count',
        'scene_eyebrow',
        'scene_text',
        'scene_character',
        'scene_title',
        'scene_poster',
        'glow_days',
        'widget_events',
      ]),
    );
    for (final key in keys) {
      expect(services, contains("'$key'"), reason: '$key is not saved by Dart');
    }
  });

  test('every kind has its widget xml in the manifest', () {
    for (final kind in QuotelyWidgetKind.values) {
      final name = _xmlName[kind]!;
      expect(
        File(
          'android/app/src/main/res/xml/${name}_widget_info.xml',
        ).existsSync(),
        isTrue,
        reason: '${kind.id}: xml/${name}_widget_info.xml is missing',
      );
      final receiver = RegExp(
        'android:name="\\.widget\\.${kind.androidClass}"[\\s\\S]*?</receiver>',
      ).firstMatch(manifest)?.group(0);
      expect(receiver, contains('@xml/${name}_widget_info'));
    }
  });

  test(
    'Minimal quote: its background setting is a launcher configure activity',
    () {
      final xml = File(
        'android/app/src/main/res/xml/minimal_widget_info.xml',
      ).readAsStringSync();
      final activity = RegExp(
        r'android:configure="com\.pranta\.quotely\.widget\.(\w+)"',
      ).firstMatch(xml)!.group(1)!;
      expect(kotlin['$activity.kt'], contains('class $activity'));
      expect(manifest, contains('android:name=".widget.$activity"'));
      expect(
        manifest,
        contains('android.appwidget.action.APPWIDGET_CONFIGURE'),
      );
      // Placed straight away on Android 12+, and changeable afterwards.
      expect(xml, contains('reconfigurable|configuration_optional'));
    },
  );

  test('the widget xml points at layouts that exist', () {
    for (final name in _xmlName.values) {
      final xml = File(
        'android/app/src/main/res/xml/${name}_widget_info.xml',
      ).readAsStringSync();
      final preview = RegExp(
        r'android:previewLayout="@layout/(\w+)"',
      ).firstMatch(xml)!.group(1)!;
      expect(
        File('android/app/src/main/res/layout/$preview.xml').existsSync(),
        isTrue,
        reason: '$name: layout/$preview.xml is missing',
      );
      // Glance's own loading layout until the first composition.
      expect(
        xml,
        contains(
          'android:initialLayout="@layout/glance_default_loading_layout"',
        ),
      );
    }
  });
}
