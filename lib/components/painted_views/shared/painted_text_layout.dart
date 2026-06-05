import 'package:flutter/material.dart';

/// Binary-search font autosizing for fixed content boxes (book pages,
/// deck/coverflow cards). Returns the largest font size in [min]..[max]
/// whose laid-out text fits [box]; returns [min] when even that overflows —
/// callers should then fall back to an inner scrollable.
double fitFontSize({
  required String text,
  required Size box,
  required TextStyle baseStyle,
  double max = 22,
  double min = 10,
}) {
  final painter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.left,
  );

  bool fits(double fontSize) {
    painter.text = TextSpan(
      text: text,
      style: baseStyle.copyWith(fontSize: fontSize, height: 1.4),
    );
    painter.layout(maxWidth: box.width);
    return painter.height <= box.height;
  }

  if (fits(max)) return max;
  if (!fits(min)) return min;

  var lo = min, hi = max;
  // 6 iterations narrows to < 0.2pt — plenty for display text.
  for (var i = 0; i < 6; i++) {
    final mid = (lo + hi) / 2;
    if (fits(mid)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// Whether [text] at the chosen size still overflows [box] (callers switch
/// the page/card body to an inner scroll view when true).
bool textOverflows({
  required String text,
  required Size box,
  required TextStyle style,
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style.copyWith(height: 1.4)),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: box.width);
  final overflows = painter.height > box.height;
  painter.dispose();
  return overflows;
}
