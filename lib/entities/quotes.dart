import 'package:drift/drift.dart';

class Quotes extends Table {
  TextColumn get id => text()();
  TextColumn get author => text()();
  TextColumn get content => text()();
  TextColumn get tags => text()();
  TextColumn get authorSlug => text()();
  IntColumn get length => integer()();
  BoolColumn get isFavorite => boolean().withDefault(Constant(false))();
  DateTimeColumn get dateAdded => dateTime()();
  DateTimeColumn get dateModified => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
