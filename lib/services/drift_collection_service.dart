import 'package:drift/drift.dart';

import '../database/database.dart';
import '../dtos/ai_fact_dto.dart';
import '../dtos/quote_dto.dart';
import '../service_locator/init_service_locators.dart';

/// quote | scene | fact, as stored in CollectionItems.itemType.
enum CollectionItemType { quote, scene, fact }

/// A collection with how many items it holds.
class CollectionSummary {
  final int id;
  final String name;
  final int count;
  const CollectionSummary(this.id, this.name, this.count);
}

/// Local-only "Saved → Collections" storage.
class DriftCollectionService {
  DriftCollectionService._();

  static AppDatabase get _db => getIt.get<AppDatabase>();

  static Stream<List<CollectionSummary>> watchCollections() {
    final c = _db.collections;
    final i = _db.collectionItems;
    final count = i.itemId.count();
    final query =
        _db.select(c).join([leftOuterJoin(i, i.collectionId.equalsExp(c.id))])
          ..addColumns([count])
          ..groupBy([c.id])
          ..orderBy([OrderingTerm.asc(c.createdAt)]);
    return query.watch().map(
      (rows) => [
        for (final r in rows)
          CollectionSummary(
            r.readTable(c).id,
            r.readTable(c).name,
            r.read(count) ?? 0,
          ),
      ],
    );
  }

  static Future<int> create(String name) => _db
      .into(_db.collections)
      .insert(
        CollectionsCompanion.insert(
          name: name.trim(),
          createdAt: DateTime.now(),
        ),
      );

  static Future<void> rename(int id, String name) =>
      (_db.update(_db.collections)..where((c) => c.id.equals(id))).write(
        CollectionsCompanion(name: Value(name.trim())),
      );

  static Future<void> delete(int id) async {
    await (_db.delete(
      _db.collectionItems,
    )..where((i) => i.collectionId.equals(id))).go();
    await (_db.delete(_db.collections)..where((c) => c.id.equals(id))).go();
  }

  static Future<void> add(
    int collectionId,
    CollectionItemType type,
    String id,
  ) => _db
      .into(_db.collectionItems)
      .insert(
        CollectionItemsCompanion.insert(
          collectionId: collectionId,
          itemType: type.name,
          itemId: id,
          addedAt: DateTime.now(),
        ),
        mode: InsertMode.insertOrIgnore,
      );

  static Future<void> remove(
    int collectionId,
    CollectionItemType type,
    String id,
  ) =>
      (_db.delete(_db.collectionItems)..where(
            (i) =>
                i.collectionId.equals(collectionId) &
                i.itemType.equals(type.name) &
                i.itemId.equals(id),
          ))
          .go();

  /// Which collections already contain this item (for the picker's checks).
  static Future<Set<int>> collectionsContaining(
    CollectionItemType type,
    String id,
  ) async {
    final rows = await (_db.select(
      _db.collectionItems,
    )..where((i) => i.itemType.equals(type.name) & i.itemId.equals(id))).get();
    return {for (final r in rows) r.collectionId};
  }

  /// Item ids of one type in a collection, newest first.
  static Stream<List<String>> watchItemIds(
    int collectionId,
    CollectionItemType type,
  ) {
    final query = _db.select(_db.collectionItems)
      ..where(
        (i) =>
            i.collectionId.equals(collectionId) & i.itemType.equals(type.name),
      )
      ..orderBy([(i) => OrderingTerm.desc(i.addedAt)]);
    return query.watch().map((rows) => [for (final r in rows) r.itemId]);
  }

  static Future<List<QuoteDto>> quotesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(
      _db.quotes,
    )..where((q) => q.id.isIn(ids))).get();
    final byId = {for (final r in rows) r.id: QuoteDto.fromQuote(r)};
    return [for (final id in ids) ?byId[id]];
  }

  static Future<List<AiFactDto>> factsByIds(List<String> ids) async {
    final ints = [for (final id in ids) ?int.tryParse(id)];
    if (ints.isEmpty) return const [];
    final rows = await (_db.select(
      _db.facts,
    )..where((f) => f.id.isIn(ints))).get();
    final byId = {for (final r in rows) r.id: AiFactDto.fromDrift(r)};
    return [for (final id in ints) ?byId[id]];
  }
}
