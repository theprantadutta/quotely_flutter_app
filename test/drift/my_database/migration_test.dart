import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quotely_flutter_app/database/database.dart';

import 'generated/schema.dart';

/// Seconds since the epoch: how drift stores DateTime columns here.
int _s(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  group('every old schema upgrades to the current one', () {
    for (final from in GeneratedHelper.versions) {
      if (from == 4) continue;
      test('v$from → v4', () async {
        final schema = await verifier.schemaAt(from);
        final db = AppDatabase.forTesting(schema.newConnection());
        await verifier.migrateAndValidate(db, 4);
        await db.close();
      });
    }
  });

  group('v3 → v4 folds collections into Saved', () {
    final hearted = DateTime(2026, 3, 1, 9);
    final collected = DateTime(2026, 5, 2, 18, 30);
    final later = DateTime(2026, 6, 10);
    final modified = DateTime(2026, 1, 5);

    late AppDatabase db;

    setUp(() async {
      final schema = await verifier.schemaAt(3);
      final raw = schema.rawDatabase;
      void quote(String id, {required bool fav}) => raw.execute(
        'INSERT INTO quotes (id, author, content, tags, author_slug, length, '
        'is_favorite, date_added, date_modified) '
        "VALUES (?, 'A', 'Line $id', '', 'a', 6, ?, ?, ?)",
        [id, fav ? 1 : 0, _s(modified), _s(modified)],
      );
      void fact(int id, {required bool fav}) => raw.execute(
        'INSERT INTO facts (id, content, ai_fact_category, provider, '
        'is_favorite, date_added, date_modified) '
        "VALUES (?, 'Fact $id', 'Space', 'x', ?, ?, ?)",
        [id, fav ? 1 : 0, _s(modified), _s(modified)],
      );
      void scene(String id, {required bool fav}) => raw.execute(
        'INSERT INTO scene_quotes (id, content, title_id, title_name, '
        'title_type, character_id, character_name, is_favorite, date_added, '
        'date_modified) '
        "VALUES (?, 'Scene $id', 't', 'Show', 'series', 'c', 'Cee', ?, ?, ?)",
        [id, fav ? 1 : 0, _s(modified), _s(modified)],
      );

      quote('saved', fav: true); // hearted, and in a collection
      quote('collected', fav: false); // only in collections (twice)
      quote('plain', fav: false); // neither
      quote('hearted', fav: true); // hearted, no collection
      fact(7, fav: false); // only in a collection
      scene('s1', fav: false); // only in a collection

      raw.execute(
        "INSERT INTO collections (id, name, created_at) VALUES (1, 'Morning', ?)",
        [_s(hearted)],
      );
      raw.execute(
        "INSERT INTO collections (id, name, created_at) VALUES (2, 'Work', ?)",
        [_s(hearted)],
      );
      void item(int c, String type, String id, DateTime at) => raw.execute(
        'INSERT INTO collection_items (collection_id, item_type, item_id, '
        'added_at) VALUES (?, ?, ?, ?)',
        [c, type, id, _s(at)],
      );
      item(1, 'quote', 'saved', collected);
      item(1, 'quote', 'collected', later);
      item(2, 'quote', 'collected', collected); // the earlier one wins
      item(1, 'fact', '7', collected);
      item(2, 'scene', 's1', collected);
      item(2, 'quote', 'gone', collected); // its quote no longer exists

      db = AppDatabase.forTesting(schema.newConnection());
      await verifier.migrateAndValidate(db, 4);
    });

    tearDown(() => db.close());

    Future<Quote> q(String id) =>
        (db.select(db.quotes)..where((t) => t.id.equals(id))).getSingle();

    test(
      'collected-only items become saved, dated when first collected',
      () async {
        final c = await q('collected');
        expect(c.isFavorite, isTrue);
        expect(c.savedAt, collected);

        final f = await (db.select(
          db.facts,
        )..where((t) => t.id.equals(7))).getSingle();
        expect(f.isFavorite, isTrue);
        expect(f.savedAt, collected);

        final s = await (db.select(
          db.sceneQuotes,
        )..where((t) => t.id.equals('s1'))).getSingle();
        expect(s.isFavorite, isTrue);
        expect(s.savedAt, collected);
      },
    );

    test('already-saved items stay saved, undated', () async {
      for (final id in ['saved', 'hearted']) {
        final row = await q(id);
        expect(row.isFavorite, isTrue, reason: id);
        expect(row.savedAt, isNull, reason: id);
      }
    });

    test('items in no collection are untouched', () async {
      final row = await q('plain');
      expect(row.isFavorite, isFalse);
      expect(row.savedAt, isNull);
    });

    test('no collection or membership is lost', () async {
      expect(await db.select(db.collections).get(), hasLength(2));
      expect(await db.select(db.collectionItems).get(), hasLength(6));
    });
  });
}
