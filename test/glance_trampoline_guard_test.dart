// The manifest disables Glance's list-adapter trampolines (see the comment
// there): they crash when started without Glance's intent, and only a click
// inside a lazy list ever routes through them. This keeps that true.
//
// Reads the Kotlin sources and the manifest as text; run from the project
// root, as `flutter test` does.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _kotlinDir = 'android/app/src/main/kotlin';
const _manifest = 'android/app/src/main/AndroidManifest.xml';

void main() {
  final manifest = File(_manifest).readAsStringSync();
  final kotlin = [
    for (final f in Directory(_kotlinDir).listSync(recursive: true))
      if (f is File && f.path.endsWith('.kt')) f,
  ];

  for (final name in [
    'InvisibleActionTrampolineActivity',
    'ActionTrampolineActivity',
  ]) {
    test('$name is disabled in the manifest', () {
      final block = RegExp(
        r'<activity\s+android:name="androidx\.glance\.appwidget\.action\.'
        '$name"'
        r'[^>]*>',
      ).firstMatch(manifest)?.group(0);
      expect(block, isNotNull);
      expect(block, contains('android:enabled="false"'));
      expect(block, contains('tools:replace="android:enabled"'));
    });
  }

  test('no widget uses a Glance lazy list (it would need the trampolines)', () {
    expect(kotlin, isNotEmpty);
    for (final f in kotlin) {
      final source = f.readAsStringSync();
      expect(
        source,
        isNot(contains('androidx.glance.appwidget.lazy')),
        reason:
            '${f.path} uses a Glance lazy list: re-enable the trampolines in '
            'AndroidManifest.xml, or taps on its items will do nothing.',
      );
    }
  });
}
