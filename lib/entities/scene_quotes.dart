import 'package:drift/drift.dart';

/// A line from a title. Title and character fields are denormalized, exactly
/// as the API returns them, so the offline cache renders a bubble from one
/// row without joins.
class SceneQuotes extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()();
  TextColumn get titleId => text()();
  TextColumn get titleSlug => text().withDefault(const Constant(''))();
  TextColumn get titleName => text()();
  TextColumn get titleType => text()();
  IntColumn get titleYear => integer().nullable()();
  TextColumn get posterUrl => text().nullable()();
  TextColumn get characterId => text()();
  TextColumn get characterName => text()();
  TextColumn get characterAvatarUrl => text().nullable()();
  TextColumn get episodeLabel => text().nullable()();
  IntColumn get season => integer().nullable()();
  IntColumn get episode => integer().nullable()();
  BoolColumn get isSpoiler => boolean().withDefault(const Constant(false))();
  IntColumn get spoilerAfterEpisode => integer().nullable()();
  TextColumn get tags => text().withDefault(const Constant(''))();
  IntColumn get likes => integer().withDefault(const Constant(0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dateAdded => dateTime()();
  DateTimeColumn get dateModified => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
