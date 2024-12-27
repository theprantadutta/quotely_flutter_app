int compareVersion(String v1, String v2) {
  List<int> parseVersion(String version) {
    return version.split('.').map(int.parse).toList();
  }

  final v1Parts = parseVersion(v1);
  final v2Parts = parseVersion(v2);

  final maxLength =
      v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

  for (var i = 0; i < maxLength; i++) {
    final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
    final v2Part = i < v2Parts.length ? v2Parts[i] : 0;

    if (v1Part < v2Part) return -1;
    if (v1Part > v2Part) return 1;
  }

  return 0;
}
