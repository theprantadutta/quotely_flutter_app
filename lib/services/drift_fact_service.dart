import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/database.dart';
import '../dtos/ai_fact_dto.dart';
import '../service_locator/init_service_locators.dart';

class DriftFactService {
  DriftFactService._();

  static Future<bool> isFavoriteFact(int factId) async {
    final database = getIt.get<AppDatabase>();
    final existingQuote = await (database.select(database.facts)
          ..where((x) => (x.id.equals(factId))))
        .getSingleOrNull();
    return existingQuote == null ? false : existingQuote.isFavorite;
  }

  static Future<bool> changeFactUpdateStatus(
      AiFactDto aiFact, bool isFavorite) async {
    try {
      final database = getIt.get<AppDatabase>();

      await database.into(database.facts).insertOnConflictUpdate(
            FactsCompanion(
              id: Value(aiFact.id),
              aiFactCategory: Value(aiFact.aiFactCategory),
              provider: Value(aiFact.provider),
              content: Value(aiFact.content),
              isFavorite: Value(isFavorite), // This is what we're updating
              dateAdded: Value(aiFact.dateAdded),
              dateModified: Value(aiFact.dateModified), // Update modified time
            ),
          );

      return true;
    } catch (e) {
      if (kDebugMode) print(e);
      return false;
    }
  }

  static Stream<List<Fact>> watchAllFavoriteFacts(String? category) {
    final db = getIt.get<AppDatabase>();
    final query = db.select(db.facts);

    // Always filter by isFavorite
    query.where((tbl) => tbl.isFavorite.equals(true));

    // Add category filter if category is provided
    if (category != null && category.isNotEmpty) {
      query.where((tbl) => tbl.aiFactCategory.equals(category));
    }

    return query.watch();
  }

  static Future<List<Fact>> getAllFavoriteFacts(String? category) async {
    final db = getIt.get<AppDatabase>();
    final query = db.select(db.facts)
      ..where((tbl) => tbl.isFavorite.equals(true));

    if (category != null && category.isNotEmpty) {
      query.where((tbl) => tbl.aiFactCategory.equals(category));
    }

    return query.get();
  }

  static Future<void> saveNewFactsToDatabase(List<AiFactDto> aiFactDtos) async {
    final db = getIt.get<AppDatabase>();

    await db.batch((batch) {
      for (final dto in aiFactDtos) {
        // Convert QuoteDto to database Quote entity
        final quote = Fact(
          id: dto.id,
          content: dto.content,
          aiFactCategory: dto.aiFactCategory,
          provider: dto.provider,
          isFavorite: false,
          dateAdded: dto.dateAdded,
          dateModified: dto.dateModified,
        );

        batch.insert(
          db.facts,
          quote.toCompanion(true),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  // static Future<int> getTotalFactCount({
  //   List<String>? factCategories,
  //   List<String>? aiProviders,
  // }) async {
  //   final db = getIt.get<AppDatabase>();
  //   final countExpr = db.facts.id.count();

  //   var query = db.selectOnly(db.facts)..addColumns([countExpr]);

  //   if (factCategories != null && factCategories.isNotEmpty) {
  //     query.where((tbl) {
  //       Expression<bool> condition = const Constant<bool>(false);
  //       for (final category in factCategories) {
  //         condition = condition | tbl.category.equals(category);
  //       }
  //       return condition;
  //     });
  //   }

  //   if (aiProviders != null && aiProviders.isNotEmpty) {
  //     query.where((tbl) {
  //       Expression<bool> condition = const Constant<bool>(false);
  //       for (final provider in aiProviders) {
  //         condition = condition | tbl.provider.equals(provider);
  //       }
  //       return condition;
  //     });
  //   }

  //   return await query.map((row) => row.read(countExpr)).getSingle();
  // }

  // static Future<int> getTotalFactPages({
  //   required int pageSize,
  //   List<String>? factCategories,
  //   List<String>? aiProviders,
  // }) async {
  //   final totalCount = await getTotalFactCount(
  //     factCategories: factCategories,
  //     aiProviders: aiProviders,
  //   );
  //   return (totalCount / pageSize).ceil();
  // }

  static Future<List<AiFactDto>> getLocalFactsWithPagination({
    required int pageNumber,
    required int pageSize,
    required List<String> factCategories,
    required List<String> aiProviders,
  }) async {
    final db = getIt.get<AppDatabase>();
    final offset = (pageNumber - 1) * pageSize;

    var query = db.select(db.facts)..limit(pageSize, offset: offset);

    if (factCategories.isNotEmpty) {
      query.where((tbl) {
        Expression<bool> condition = const Constant<bool>(false);
        for (final category in factCategories) {
          condition = condition | tbl.aiFactCategory.equals(category);
        }
        return condition;
      });
    }

    if (aiProviders.isNotEmpty) {
      query.where((tbl) {
        Expression<bool> condition = const Constant<bool>(false);
        for (final provider in aiProviders) {
          condition = condition | tbl.provider.equals(provider);
        }
        return condition;
      });
    }

    final facts = await query.get();
    return facts.map((e) => AiFactDto.fromDrift(e)).toList();
  }

  static Future<List<int>> getAllFavoriteFactIds() async {
    final db = getIt.get<AppDatabase>();

    // Query that selects only IDs
    final results = await db.customSelect(
      'SELECT id FROM facts WHERE is_favorite = 1',
      readsFrom: {db.facts},
    ).get();

    // Map results to List<String>
    return results.map((row) => row.read<int>('id')).toList();
  }
}
