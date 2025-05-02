import 'package:drift/drift.dart';

class Facts extends Table {
  IntColumn get id => integer()();
  TextColumn get content => text()();
  TextColumn get aiFactCategory => text()();
  TextColumn get provider => text()();
  BoolColumn get isFavorite => boolean().withDefault(Constant(false))();
  DateTimeColumn get dateAdded => dateTime()();
  DateTimeColumn get dateModified => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
