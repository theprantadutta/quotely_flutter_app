import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Circular avatar that shows the network image when available, otherwise a
/// colorful monogram. The fallback gradient is derived deterministically from
/// the [name], so an author without a photo always gets the same vibrant
/// initials badge instead of a flat grey circle.
///
/// Wrapped in a [Hero] (tag: [name]) so the avatar animates between the authors
/// list and the author-detail screen.
class CircleAvatarWithFallback extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const CircleAvatarWithFallback({
    super.key,
    this.imageUrl,
    required this.name,
    required this.radius,
  });

  /// Wikimedia (and many hosts) throttle/deny image requests that arrive
  /// without a descriptive User-Agent — that's what caused the 429s. Send one.
  static const Map<String, String> _imageHeaders = {
    'User-Agent':
        'QuotelyApp/1.0 (https://github.com/prantadutta; prantadutta1997@gmail.com)',
  };

  /// On-brand gradient pairs for monogram fallbacks. Chosen for good contrast
  /// against white initials in both light and dark themes.
  static const List<List<Color>> _palettes = [
    [Color(0xFF2E86DE), Color(0xFF54A0FF)], // blue
    [Color(0xFF10AC84), Color(0xFF1DD1A1)], // green
    [Color(0xFF8E44AD), Color(0xFFB983FF)], // purple
    [Color(0xFFEE5253), Color(0xFFFF6B6B)], // red
    [Color(0xFFF39C12), Color(0xFFFECA57)], // amber
    [Color(0xFF00838F), Color(0xFF22A6B3)], // teal
    [Color(0xFFEA2027), Color(0xFFFF793F)], // orange
    [Color(0xFF5352ED), Color(0xFF7D5FFF)], // indigo
  ];

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.elementAt(1).substring(0, 1))
        .toUpperCase();
  }

  List<Color> _gradientFor(String name) =>
      _palettes[name.hashCode.abs() % _palettes.length];

  Widget _monogram() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientFor(name),
        ),
      ),
      child: Text(
        _getInitials(name),
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Target decode size in real device pixels. Rounded up so the bitmap is
  /// never smaller than the circle it fills.
  int _decodePixels(BuildContext context) =>
      (radius * 2 * MediaQuery.devicePixelRatioOf(context)).ceil();

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Hero(
      tag: name,
      child: hasImage
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                httpHeaders: _imageHeaders,
                // Decode to the size actually drawn rather than the size the
                // source happens to be. Author photos are backfilled from
                // Wikipedia and run to 2000px+, which Image.network decoded in
                // full to paint a circle this wide - a ~100x memory difference
                // per avatar, and the authors list holds many at once.
                // Multiplied by devicePixelRatio so the circle stays sharp.
                memCacheWidth: _decodePixels(context),
                memCacheHeight: _decodePixels(context),
                // Show the monogram until the photo is ready (no grey flash)…
                placeholder: (context, url) => _monogram(),
                // …and keep it if the photo fails (e.g. 429/404).
                errorWidget: (context, url, error) => _monogram(),
              ),
            )
          : _monogram(),
    );
  }
}
