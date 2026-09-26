import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Wikimedia (and many hosts) throttle image requests without a descriptive
/// User-Agent, which is what used to 429 the author portraits.
const Map<String, String> kImageHeaders = {
  'User-Agent':
      'QuotelyApp/1.0 (https://github.com/prantadutta; prantadutta1997@gmail.com)',
};

/// "NM" from "Nelson Mandela", "D" from "Dory".
String initialsOf(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty && RegExp(r'[A-Za-z0-9]').hasMatch(p[0]))
      .toList();
  if (parts.isEmpty) return name.isEmpty ? '?' : name[0].toUpperCase();
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// The 135° `ph`/`surf` stripe used for every image placeholder: loading,
/// missing and failed images all look the same.
class StripePainter extends CustomPainter {
  final Color stripe;
  final Color base;

  const StripePainter({required this.stripe, required this.base});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 3.2;
    // 3px stripe every 6px, running bottom-left → top-right.
    for (double x = -size.height; x < size.width; x += 6.4) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StripePainter old) =>
      old.stripe != stripe || old.base != base;
}

/// Striped placeholder filling its parent, with optional centered initials.
class ImageFallback extends StatelessWidget {
  final String? initials;
  final double fontSize;

  const ImageFallback({super.key, this.initials, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    return CustomPaint(
      painter: StripePainter(stripe: t.ph, base: t.surf),
      child: initials == null
          ? const SizedBox.expand()
          : Center(
              child: Text(
                initials!,
                style: context.qt.label.copyWith(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: t.mute,
                ),
              ),
            ),
    );
  }
}

/// Network image that falls back to [ImageFallback] while loading and on
/// error. Decodes at the drawn size (portraits are often 2000px+).
class QNetworkImage extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final String? initials;
  final double initialsSize;

  const QNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.initials,
    this.initialsSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = ImageFallback(initials: initials, fontSize: initialsSize);
    if (url == null || url!.isEmpty) {
      return SizedBox(width: width, height: height, child: fallback);
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      httpHeaders: kImageHeaders,
      memCacheWidth: (width * dpr).ceil(),
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
      fadeInDuration: const Duration(milliseconds: 180),
    );
  }
}

/// Circular avatar: photo, or initials on the stripe with a 1px `line` ring.
class QAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;

  /// Shared-element tag, e.g. the author slug, for list → detail flights.
  final Object? heroTag;

  const QAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 34,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.q;
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: t.line),
      ),
      child: ClipOval(
        child: QNetworkImage(
          url: imageUrl,
          width: size,
          height: size,
          initials: initialsOf(name),
          initialsSize: (size * 0.3).clamp(9, 26),
        ),
      ),
    );
    if (heroTag != null) avatar = Hero(tag: heroTag!, child: avatar);
    return Semantics(label: name, image: true, child: avatar);
  }
}

/// Poster with the design's radius per size (14 large, 8 small, 5 in chips).
class QPoster extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final double radius;

  const QPoster({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.q.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: QNetworkImage(url: url, width: width, height: height),
      ),
    );
  }
}

/// The app's own avatar ("Quotely" as a sender): the app icon, round.
class BrandAvatar extends StatelessWidget {
  final double size;

  const BrandAvatar({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/app/avatar-256.png',
      width: size,
      height: size,
      cacheWidth: 128,
      semanticLabel: 'Quotely',
    );
  }
}

/// The app icon (About, notifications primer). One logo in both themes:
/// it is the icon people tap, so it stays the same.
class BrandIcon extends StatelessWidget {
  final double size;
  final double radius;

  const BrandIcon({super.key, required this.size, this.radius = 10});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        'assets/brand/app/logo-512.png',
        width: size,
        height: size,
        cacheWidth: 256,
        semanticLabel: 'Quotely',
      ),
    );
  }
}
