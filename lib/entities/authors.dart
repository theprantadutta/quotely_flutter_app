import 'package:drift/drift.dart';

class Authors extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get bio => text()();
  TextColumn get description => text()();
  TextColumn get link => text()();
  IntColumn get quoteCount => integer()();
  TextColumn get slug => text()();
  TextColumn? get imageUrl => text().nullable()();
  DateTimeColumn get dateAdded => dateTime()();
  DateTimeColumn get dateModified => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
