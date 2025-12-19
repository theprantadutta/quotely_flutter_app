import 'dart:math';

/// Utility class for managing pagination seeds.
///
/// A seed ensures consistent random ordering across paginated requests.
/// Same seed = same order = no duplicate items when navigating pages.
class PaginationSeed {
  PaginationSeed._();

  static int? _currentSeed;

  /// Gets the current session seed, or generates a new one if none exists.
  ///
  /// The seed persists for the entire app session. When the user restarts
  /// the app, a new seed will be generated, giving them fresh random content.
  static int get current {
    _currentSeed ??= _generateSeed();
    return _currentSeed!;
  }

  /// Generates a new seed and discards the old one.
  ///
  /// Call this when you want to refresh the random order, e.g., when the
  /// user explicitly requests new random content via pull-to-refresh.
  static int refresh() {
    _currentSeed = _generateSeed();
    return _currentSeed!;
  }

  /// Resets the seed to null, so the next access to [current] generates a new one.
  static void reset() {
    _currentSeed = null;
  }

  /// Generates a random seed value.
  static int _generateSeed() {
    // Generate a seed between 1 and 999999 (6 digits max)
    return Random().nextInt(999999) + 1;
  }
}
