import 'package:drift/drift.dart';

import '../database/database.dart';
import '../service_locator/init_service_locators.dart';

/// quote | scene | fact, as stored in CollectionItems.itemType.
enum CollectionItemType { quote, scene, fact }

/// A collection with how many saved items it holds.
class CollectionSummary {
  final int id;
  final String name;
  final int count;
  const CollectionSummary(this.id, this.name, this.count);
}

/// Local-only collections: optional tags on saved items.
class DriftCollectionService {
  DriftCollectionService._();

  static AppDatabase get _db => getIt.get<AppDatabase>();

  /// Collections in the order they were made, each with how many *saved*
  /// items it holds. Collections are tags on saved items: an unsaved item
  /// keeps its tags (saving it again brings them back) but isn't counted.
  static Stream<List<CollectionSummary>> watchCollections() {
    return _db
        .customSelect(
          '''
          SELECT c.id, c.name, (
            SELECT COUNT(*) FROM collection_items ci
            WHERE ci.collection_id = c.id AND (
              (ci.item_type = 'quote' AND EXISTS (
                SELECT 1 FROM quotes q
                WHERE q.id = ci.item_id AND q.is_favorite = 1))
              OR (ci.item_type = 'scene' AND EXISTS (
                SELECT 1 FROM scene_quotes s
                WHERE s.id = ci.item_id AND s.is_favorite = 1))
              OR (ci.item_type = 'fact' AND EXISTS (
                SELECT 1 FROM facts f
                WHERE CAST(f.id AS TEXT) = ci.item_id AND f.is_favorite = 1))
            )
          ) AS saved_count
          FROM collections c
          ORDER BY c.created_at, c.id
          ''',
          readsFrom: {
            _db.collections,
            _db.collectionItems,
            _db.quotes,
            _db.sceneQuotes,
            _db.facts,
          },
        )
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              CollectionSummary(
                r.read<int>('id'),
                r.read<String>('name'),
                r.read<int>('saved_count'),
              ),
          ],
        );
  }

  /// Every item's collections, keyed `type:itemId` (the same as
  /// `ThreadMessage.key`), so the Saved feed can filter and label by tag.
  static Stream<Map<String, Set<int>>> watchMemberships() {
    return _db.select(_db.collectionItems).watch().map((rows) {
      final map = <String, Set<int>>{};
      for (final r in rows) {
        (map['${r.itemType}:${r.itemId}'] ??= {}).add(r.collectionId);
      }
      return map;
    });
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
}
