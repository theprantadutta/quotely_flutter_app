import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/services/quote_widget_service.dart';

void main() {
  test('the widget date is the day the API sent, in any time zone', () {
    // The API sends UTC midnight; west of UTC that is still the previous
    // evening locally, which must not shift the day.
    expect(
      QuoteWidgetService.dateKey(DateTime.utc(2026, 10, 28)),
      '2026-10-28',
    );
    expect(
      QuoteWidgetService.dateKey(DateTime.utc(2026, 10, 28).toLocal()),
      '2026-10-28',
    );
  });

  group('coverRect', () {
    test('crops a tall poster to the middle band of a wide target', () {
      final r = QuoteWidgetService.coverRect(
        const Size(200, 300),
        const Size(480, 320),
      );
      expect(r.width, 200);
      expect(r.height, closeTo(133.33, 0.01));
      expect(r.top, closeTo(83.33, 0.01));
      expect(r.left, 0);
    });

    test('crops a wide source to the middle of a square target', () {
      final r = QuoteWidgetService.coverRect(
        const Size(400, 100),
        const Size(50, 50),
      );
      expect(r, const Rect.fromLTWH(150, 0, 100, 100));
    });
  });
}
