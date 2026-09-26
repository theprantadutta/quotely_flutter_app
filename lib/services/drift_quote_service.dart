import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';

import '../database/database.dart';
import '../database/seeded_order.dart';

class DriftQuoteService {
  DriftQuoteService._();

  static Future<bool> isFavoriteQuote(String quoteId) async {
    final database = getIt.get<AppDatabase>();
    final existingQuote = await (database.select(
      database.quotes,
    )..where((x) => (x.id.equals(quoteId)))).getSingleOrNull();
    return existingQuote == null ? false : existingQuote.isFavorite;
  }

  static Future<bool> changeQuoteUpdateStatus(
    QuoteDto quote,
    bool isFavorite,
  ) async {
    try {
      final database = getIt.get<AppDatabase>();

      await database
          .into(database.quotes)
          .insertOnConflictUpdate(
            QuotesCompanion(
              id: Value(quote.id),
              author: Value(quote.author),
              content: Value(quote.content),
              tags: Value(quote.tags.join(',')),
              authorSlug: Value(quote.authorSlug),
              length: Value(quote.length),
              isFavorite: Value(isFavorite), // This is what we're updating
              dateAdded: Value(quote.dateAdded),
              dateModified: Value(DateTime.now()), // Update modified time
            ),
          );

      return true;
    } catch (e) {
      if (kDebugMode) print(e);
      return false;
    }
  }

  static Stream<List<Quote>> watchAllFavoriteQuotes(List<String> tags) {
    final db = getIt.get<AppDatabase>();
    final query = db.select(db.quotes);

    // Always filter by isFavorite
    query.where((tbl) => tbl.isFavorite.equals(true));

    // Add tag conditions only if tags exist
    if (tags.isNotEmpty) {
      query.where(
        (tbl) =>
            tags.map((tag) => tbl.tags.like('%$tag%')).reduce((a, b) => a | b),
      );
    }

    return query.watch();
  }

  static Future<List<Quote>> getAllFavoriteQuotes(List<String> tags) async {
    final db = getIt.get<AppDatabase>();
    final query = db.select(db.quotes)
      ..where((tbl) => tbl.isFavorite.equals(true));

    if (tags.isNotEmpty) {
      query.where((tbl) {
        // Start with a false condition
        Expression<bool> condition = const Constant<bool>(false);

        // Combine all tag conditions with OR
        for (final tag in tags) {
          condition = condition | tbl.tags.like('%$tag%');
        }

        return condition;
      });
    }

    return query.get();
  }

  static Future<List<String>> getAllFavoriteQuoteIds() async {
    final db = getIt.get<AppDatabase>();

    // Query that selects only IDs
    final results = await db
        .customSelect(
          'SELECT id FROM quotes WHERE is_favorite = 1',
          readsFrom: {db.quotes},
        )
        .get();

    // Map results to List<String>
    return results.map((row) => row.read<String>('id')).toList();
  }

  // Helper function to save new quotes to database
  static Future<void> saveNewQuotesToDatabase(List<QuoteDto> quoteDtos) async {
    final db = getIt.get<AppDatabase>();

    await db.batch((batch) {
      for (final dto in quoteDtos) {
        // Convert QuoteDto to database Quote entity
        final quote = Quote(
          id: dto.id,
          content: dto.content,
          author: dto.author,
          tags: dto.tags.join(','),
          authorSlug: dto.authorSlug,
          length: dto.length,
          isFavorite: false,
          dateAdded: dto.dateAdded,
          dateModified: dto.dateModified,
        );

        // New quotes are inserted; existing rows pick up edits (text,
        // author, tags) and keep their saved flag.
        batch.insert(
          db.quotes,
          quote.toCompanion(true),
          onConflict: DoUpdate(
            (_) => QuotesCompanion(
              content: Value(dto.content),
              author: Value(dto.author),
              tags: Value(dto.tags.join(',')),
              authorSlug: Value(dto.authorSlug),
              length: Value(dto.length),
              dateModified: Value(dto.dateModified),
            ),
          ),
        );
      }
    });
  }

  /// After a full download: drops local quotes the backend no longer has
  /// (removed as duplicates or for content), except saved ones.
  static Future<int> pruneMissing(Set<String> keepIds) async {
    final db = getIt.get<AppDatabase>();
    return (db.delete(db.quotes)..where(
          (q) => q.isFavorite.equals(false) & q.id.isNotIn(keepIds.toList()),
        ))
        .go();
  }

  /// Quotes by one author from the local database.
  static Future<List<Quote>> getLocalQuotesByAuthor({
    required String authorSlug,
    required int pageNumber,
    required int pageSize,
    int? seed,
  }) async {
    final db = getIt.get<AppDatabase>();
    final query = db.select(db.quotes)
      ..where((q) => q.authorSlug.equals(authorSlug))
      ..limit(pageSize, offset: (pageNumber - 1) * pageSize);
    if (seed != null) query.orderBy([(_) => seededOrder(seed)]);
    return query.get();
  }

  // Helper function to get paginated quotes from local database
  static Future<List<Quote>> getLocalQuotesWithPagination({
    required int pageNumber,
    required int pageSize,
    required List<String> tags,
    int? seed,
  }) async {
    final db = getIt.get<AppDatabase>();
    final offset = (pageNumber - 1) * pageSize;

    var query = db.select(db.quotes)..limit(pageSize, offset: offset);
    // A per-session shuffle, like the API's: pages stay stable within a
    // session and the feed opens differently next time.
    if (seed != null) query.orderBy([(_) => seededOrder(seed)]);

    if (tags.isNotEmpty) {
      query.where((tbl) {
        Expression<bool> condition = const Constant<bool>(false);
        for (final tag in tags) {
          condition = condition | tbl.tags.like('%$tag%');
        }
        return condition;
      });
    }

    return await query.get();
  }
}
