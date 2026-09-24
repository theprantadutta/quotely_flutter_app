import 'package:drift/drift.dart';

/// A character from a [MediaTitles] row. Not called `Characters`: Flutter's
/// widgets library re-exports package:characters' `Characters` class, and the
/// generated row class would collide with it in every screen.
@DataClassName('MediaCharacter')
class MediaCharacters extends Table {
  TextColumn get id => text()();
  TextColumn get titleId => text()();
  TextColumn get name => text()();
  TextColumn get avatarUrl => text().nullable()();
  IntColumn get quoteCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
