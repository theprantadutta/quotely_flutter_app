import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Caches procedurally generated paper textures as [ui.Picture]s so painters
/// only ever `drawPicture` per frame instead of regenerating noise.
///
/// Keyed by bucketed size + brightness + tint so minor layout jitter and
/// theme switches reuse / regenerate correctly. Small LRU keeps memory flat.
class PaperTextureCache {
  PaperTextureCache._();

  static final Map<String, ui.Picture> _cache = {};
  static final List<String> _lru = [];
  static const int _capacity = 12;

  /// Debug counter — verify in DevTools that this stays flat during scrolling.
  static int recordCount = 0;

  static ui.Picture of({
    required Size size,
    required Brightness brightness,
    required Color tint,
  }) {
    final key =
        '${(size.width / 8).round()}x${(size.height / 8).round()}'
        '-${brightness.name}-${tint.toARGB32()}';

    final cached = _cache[key];
    if (cached != null) {
      _lru.remove(key);
      _lru.add(key);
      return cached;
    }

    final picture = _record(size, brightness, tint);
    _cache[key] = picture;
    _lru.add(key);
    recordCount++;

    if (_lru.length > _capacity) {
      final evicted = _lru.removeAt(0);
      _cache.remove(evicted)?.dispose();
    }
    return picture;
  }

  static ui.Picture _record(Size size, Brightness brightness, Color tint) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Offset.zero & size;

    final isDark = brightness == Brightness.dark;
    final base = Color.lerp(
      isDark ? const Color(0xFF2B2722) : const Color(0xFFF6F0E1),
      tint,
      0.06,
    )!;
    final speckle = isDark ? const Color(0xFFD8CDB8) : const Color(0xFF4A3B28);

    // 1. Base with a subtle vertical falloff
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [base, Color.lerp(base, Colors.black, 0.04)!],
        ).createShader(rect),
    );

    // Seeded so every cache entry of the same size looks identical
    final rnd = Random(42);

    // 2. Speckle noise
    final speckleCount = (size.width * size.height / 3500).round();
    final specklePaint = Paint();
    for (var i = 0; i < speckleCount; i++) {
      specklePaint.color = speckle.withValues(
        alpha: 0.02 + rnd.nextDouble() * 0.03,
      );
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        0.3 + rnd.nextDouble() * 0.7,
        specklePaint,
      );
    }

    // 3. Horizontal grain lines
    final grainPaint = Paint()
      ..color = speckle.withValues(alpha: 0.015)
      ..strokeWidth = 1;
    for (var i = 0; i < 25; i++) {
      final y = rnd.nextDouble() * size.height;
      canvas.drawLine(
        Offset(0, y + rnd.nextDouble() * 4 - 2),
        Offset(size.width, y + rnd.nextDouble() * 4 - 2),
        grainPaint,
      );
    }

    // 4. Large soft blotches (aged-paper patina)
    final blotchPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    for (var i = 0; i < 6; i++) {
      blotchPaint.color = speckle.withValues(alpha: 0.02);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        20 + rnd.nextDouble() * 50,
        blotchPaint,
      );
    }

    // 5. Vignette
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.1,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.05),
          ],
        ).createShader(rect),
    );

    return recorder.endRecording();
  }
}
