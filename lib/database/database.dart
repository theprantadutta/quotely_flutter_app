import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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

  @override
  int get schemaVersion => 3;

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
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'quotely_database.db',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    );
  }
}
