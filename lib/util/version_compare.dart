/// Compares dotted numeric versions like "1.4.0" and "1.10.2".
/// Returns true when [latest] is strictly newer than [current].
/// Non-numeric segments and build metadata (e.g. "+14") are ignored safely.
bool isNewerVersion({required String current, required String latest}) {
  List<int> parse(String version) {
    return version
        .split('+')
        .first
        .split('.')
        .map((segment) => int.tryParse(segment.trim()) ?? 0)
        .toList();
  }

  final currentParts = parse(current);
  final latestParts = parse(latest);
  final length =
      currentParts.length > latestParts.length
          ? currentParts.length
          : latestParts.length;

  for (var i = 0; i < length; i++) {
    final currentPart = i < currentParts.length ? currentParts[i] : 0;
    final latestPart = i < latestParts.length ? latestParts[i] : 0;
    if (latestPart > currentPart) return true;
    if (latestPart < currentPart) return false;
  }

  return false;
}
