import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:quotely_flutter_app/dtos/quote_dto.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';

import '../database/database.dart';

class DriftService {
  DriftService._();

  static Future<bool> isFavorite(String quoteId) async {
    final database = getIt.get<AppDatabase>();
    final existingQuote = await (database.select(database.quotes)
          ..where((x) => (x.id.equals(quoteId))))
        .getSingleOrNull();
    return existingQuote == null ? false : existingQuote.isFavorite;
  }

  static Future<bool> changeQuoteUpdateStatus(
      QuoteDto quote, bool isFavorite) async {
    try {
      final database = getIt.get<AppDatabase>();

      await database.into(database.quotes).insertOnConflictUpdate(
            QuotesCompanion(
              id: Value(quote.id),
              author: Value(quote.author),
              content: Value(quote.content),
              tags: Value(quote.tags.join(',')),
              authorSlug: Value(quote.authorSlug),
              length: Value(quote.length),
              isFavorite: Value(isFavorite), // This is what we're updating
              dateAdded: Value(quote.dateAdded),
              dateModified: Value(
                DateTime.now(),
              ), // Update modified time
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
      query.where((tbl) =>
          tags.map((tag) => tbl.tags.like('%$tag%')).reduce((a, b) => a | b));
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
}
