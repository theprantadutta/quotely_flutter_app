import 'package:drift/drift.dart';

/// A user-made group of saved items ("Morning boost"). Local only.
@DataClassName('QuoteCollection')
class Collections extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Membership of a quote, scene or fact in a [Collections] row. [itemId] is
/// the item's own id (quote/scene ids are strings, fact ids are stringified).
class CollectionItems extends Table {
  IntColumn get collectionId => integer()();

  /// quote | scene | fact
  TextColumn get itemType => text()();
  TextColumn get itemId => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {collectionId, itemType, itemId};
}
