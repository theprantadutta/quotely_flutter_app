/// Calendar days from [now]'s local date to [releaseDate]'s date. Both are
/// read as plain dates, so the time of day and DST changes don't matter.
/// null when there is no date.
int? daysUntilRelease(DateTime? releaseDate, DateTime now) {
  if (releaseDate == null) return null;
  final release = DateTime.utc(
    releaseDate.year,
    releaseDate.month,
    releaseDate.day,
  );
  final today = DateTime.utc(now.year, now.month, now.day);
  return release.difference(today).inDays;
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// The eyebrow on a Coming soon card, from the release date and the local
/// date (never from a cached `daysUntil`, which goes stale):
/// 0 "Out today", 1 "Tomorrow", 2–6 "Out Friday", 7+ "In 29 days".
/// No date, or a date already past, reads "Trending".
String countdownLabel(DateTime? releaseDate, DateTime now) {
  final days = daysUntilRelease(releaseDate, now);
  if (days == null || days < 0) return 'Trending';
  if (days == 0) return 'Out today';
  if (days == 1) return 'Tomorrow';
  if (days < 7) return 'Out ${_weekdays[releaseDate!.weekday - 1]}';
  return 'In $days days';
}
