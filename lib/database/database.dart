import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../entities/authors.dart';
import '../entities/collections.dart';
import '../entities/facts.dart';
import '../entities/media_characters.dart';
import '../entities/media_titles.dart';
import '../entities/quotes.dart';
import '../entities/scene_quotes.dart';
import '../entities/tags.dart';

part '../generated/database/database.g.dart';

@DriftDatabase(
  tables: [
    Quotes,
    Facts,
    Tags,
    Authors,
    MediaTitles,
    MediaCharacters,
    SceneQuotes,
    Collections,
    CollectionItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For tests: an in-memory (or other) executor instead of the app file.
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Migration from version 1 to 2
        await m.createTable(tags); // Creates the new Tags table
        await m.createTable(authors); // Creates the new Authors table
      }
      if (from < 3) {
        // Thread redesign: Scenes cache + local collections.
        await m.createTable(mediaTitles);
        await m.createTable(mediaCharacters);
        await m.createTable(sceneQuotes);
        await m.createTable(collections);
        await m.createTable(collectionItems);
        await m.addColumn(facts, facts.falseVariant);
      }
      if (from < 4) {
        // Saved as a notebook: record when things are saved, and fold
        // collections into Saved as tags on saved items.
        await m.addColumn(quotes, quotes.savedAt);
        await m.addColumn(facts, facts.savedAt);
        // Before v3, the step above just created scene_quotes with it.
        if (from >= 3) await m.addColumn(sceneQuotes, sceneQuotes.savedAt);
        await _foldCollectionsIntoSaved();
      }
    },
  );

  /// Collections used to hold anything, saved or not; now they are tags on
  /// saved items. Anything in a collection that isn't saved becomes saved,
  /// with the time it was first collected as its saved time, so no
  /// collected item drops out of sight (or gets pruned with the unsaved
  /// library rows). Items already saved keep a null saved time: when they
  /// were hearted was never recorded. Safe to run more than once.
  Future<void> _foldCollectionsIntoSaved() async {
    for (final (table, type, id) in const [
      ('quotes', 'quote', 'quotes.id'),
      ('scene_quotes', 'scene', 'scene_quotes.id'),
      // Fact ids are ints; collection_items stores them as text.
      ('facts', 'fact', 'CAST(facts.id AS TEXT)'),
    ]) {
      await customStatement('''
        UPDATE $table
        SET is_favorite = 1,
            saved_at = (
              SELECT MIN(ci.added_at) FROM collection_items ci
              WHERE ci.item_type = '$type' AND ci.item_id = $id
            )
        WHERE is_favorite = 0
          AND $id IN (
            SELECT item_id FROM collection_items WHERE item_type = '$type'
          )
      ''');
    }
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'quotely_database.db',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    );
  }
}
