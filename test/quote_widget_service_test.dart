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

  group('the small square', () {
    test('shows a quote whole only up to 60 characters', () {
      final sixty = 'a' * 60;
      expect(QuoteWidgetService.shortLine('  $sixty  '), sixty);
      expect(QuoteWidgetService.shortLine('${sixty}b'), isNull);
      expect(QuoteWidgetService.shortLine('   '), isNull);
    });

    test('its eyebrow is the quote\'s day, in any time zone', () {
      expect(
        QuoteWidgetService.eyebrow(DateTime.utc(2026, 11, 17)),
        'TUE · NOV 17',
      );
      expect(
        QuoteWidgetService.eyebrow(DateTime.utc(2026, 11, 17).toLocal()),
        'TUE · NOV 17',
      );
    });
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
