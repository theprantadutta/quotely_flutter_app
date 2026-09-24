import 'package:drift/drift.dart';

/// A movie, show, anime, game or cartoon that scenes come from.
class MediaTitles extends Table {
  TextColumn get id => text()();
  TextColumn get slug => text()();
  TextColumn get name => text()();

  /// movie | tv | anime | game | cartoon
  TextColumn get type => text()();
  IntColumn get yearStart => integer().nullable()();
  IntColumn get yearEnd => integer().nullable()();

  /// Comma-separated, like Quotes.tags.
  TextColumn get genres => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get posterUrl => text().nullable()();
  IntColumn get quoteCount => integer().withDefault(const Constant(0))();
  IntColumn get popularity => integer().withDefault(const Constant(0))();
  DateTimeColumn get dateAdded => dateTime()();
  DateTimeColumn get dateModified => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
