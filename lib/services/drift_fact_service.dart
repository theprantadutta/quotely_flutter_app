// import 'package:drift/drift.dart';
// import 'package:flutter/foundation.dart';

// import '../database/database.dart';
// import '../dtos/ai_fact_dto.dart';
// import '../service_locator/init_service_locators.dart';

// class DriftFactService {
//   DriftFactService._();

//   static Future<bool> isFavoriteFact(int factId) async {
//     final database = getIt.get<AppDatabase>();
//     final existingQuote = await (database.select(database.facts)
//           ..where((x) => (x.id.equals(factId))))
//         .getSingleOrNull();
//     return existingQuote == null ? false : existingQuote.isFavorite;
//   }

//   static Future<bool> changeFactUpdateStatus(
//       AiFactDto aiFact, bool isFavorite) async {
//     try {
//       final database = getIt.get<AppDatabase>();

//       await database.into(database.facts).insertOnConflictUpdate(
//             FactsCompanion(
//               id: Value(aiFact.id),
//               aiFactCategory: Value(aiFact.aiFactCategory),
//               provider: Value(aiFact.provider),
//               content: Value(aiFact.content),
//               isFavorite: Value(isFavorite), // This is what we're updating
//               dateAdded: Value(aiFact.dateAdded),
//               dateModified: Value(aiFact.dateModified), // Update modified time
//             ),
//           );

//       return true;
//     } catch (e) {
//       if (kDebugMode) print(e);
//       return false;
//     }
//   }

//   static Stream<List<Fact>> watchAllFavoriteFacts(String? category) {
//     final db = getIt.get<AppDatabase>();
//     final query = db.select(db.facts);

//     // Always filter by isFavorite
//     query.where((tbl) => tbl.isFavorite.equals(true));

//     // Add category filter if category is provided
//     if (category != null && category.isNotEmpty) {
//       query.where((tbl) => tbl.aiFactCategory.equals(category));
//     }

//     return query.watch();
//   }

//   static Future<List<Fact>> getAllFavoriteFacts(String? category) async {
//     final db = getIt.get<AppDatabase>();
//     final query = db.select(db.facts)
//       ..where((tbl) => tbl.isFavorite.equals(true));

//     if (category != null && category.isNotEmpty) {
//       query.where((tbl) => tbl.aiFactCategory.equals(category));
//     }

//     return query.get();
//   }

//   static Future<void> saveNewFactsToDatabase(List<AiFactDto> aiFactDtos) async {
//     final db = getIt.get<AppDatabase>();

//     await db.batch((batch) {
//       for (final dto in aiFactDtos) {
//         // Convert QuoteDto to database Quote entity
//         final quote = Fact(
//           id: dto.id,
//           content: dto.content,
//           aiFactCategory: dto.aiFactCategory,
//           provider: dto.provider,
//           isFavorite: false,
//           dateAdded: dto.dateAdded,
//           dateModified: dto.dateModified,
//         );

//         batch.insert(
//           db.facts,
//           quote.toCompanion(true),
//           mode: InsertMode.insertOrIgnore,
//         );
//       }
//     });
//   }

//   // static Future<int> getTotalFactCount({
//   //   List<String>? factCategories,
//   //   List<String>? aiProviders,
//   // }) async {
//   //   final db = getIt.get<AppDatabase>();
//   //   final countExpr = db.facts.id.count();

//   //   var query = db.selectOnly(db.facts)..addColumns([countExpr]);

//   //   if (factCategories != null && factCategories.isNotEmpty) {
//   //     query.where((tbl) {
//   //       Expression<bool> condition = const Constant<bool>(false);
//   //       for (final category in factCategories) {
//   //         condition = condition | tbl.category.equals(category);
//   //       }
//   //       return condition;
//   //     });
//   //   }

//   //   if (aiProviders != null && aiProviders.isNotEmpty) {
//   //     query.where((tbl) {
//   //       Expression<bool> condition = const Constant<bool>(false);
//   //       for (final provider in aiProviders) {
//   //         condition = condition | tbl.provider.equals(provider);
//   //       }
//   //       return condition;
//   //     });
//   //   }

//   //   return await query.map((row) => row.read(countExpr)).getSingle();
//   // }

//   // static Future<int> getTotalFactPages({
//   //   required int pageSize,
//   //   List<String>? factCategories,
//   //   List<String>? aiProviders,
//   // }) async {
//   //   final totalCount = await getTotalFactCount(
//   //     factCategories: factCategories,
//   //     aiProviders: aiProviders,
//   //   );
//   //   return (totalCount / pageSize).ceil();
//   // }

//   static Future<List<AiFactDto>> getLocalFactsWithPagination({
//     required int pageNumber,
//     required int pageSize,
//     required List<String> factCategories,
//     required List<String> aiProviders,
//   }) async {
//     final db = getIt.get<AppDatabase>();
//     final offset = (pageNumber - 1) * pageSize;

//     var query = db.select(db.facts)..limit(pageSize, offset: offset);

//     if (factCategories.isNotEmpty) {
//       query.where((tbl) {
//         Expression<bool> condition = const Constant<bool>(false);
//         for (final category in factCategories) {
//           condition = condition | tbl.aiFactCategory.equals(category);
//         }
//         return condition;
//       });
//     }

//     if (aiProviders.isNotEmpty) {
//       query.where((tbl) {
//         Expression<bool> condition = const Constant<bool>(false);
//         for (final provider in aiProviders) {
//           condition = condition | tbl.provider.equals(provider);
//         }
//         return condition;
//       });
//     }

//     final facts = await query.get();
//     return facts.map((e) => AiFactDto.fromDrift(e)).toList();
//   }

//   static Future<List<int>> getAllFavoriteFactIds() async {
//     final db = getIt.get<AppDatabase>();

//     // Query that selects only IDs
//     final results = await db.customSelect(
//       'SELECT id FROM facts WHERE is_favorite = 1',
//       readsFrom: {db.facts},
//     ).get();

//     // Map results to List<String>
//     return results.map((row) => row.read<int>('id')).toList();
//   }
// }

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:quotely_flutter_app/dtos/ai_fact_dto.dart'; // Your DTO for facts
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';

import '../database/database.dart';

class DriftFactService {
  DriftFactService._(); // Private constructor

  /// Checks if a specific fact is marked as a favorite in the local database.
  static Future<bool> isFavoriteFact(int factId) async {
    final database = getIt.get<AppDatabase>();
    final existingFact = await (database.select(
      database.facts,
    )..where((f) => f.id.equals(factId))).getSingleOrNull();
    return existingFact?.isFavorite ?? false;
  }

  /// Toggles the favorite status of a fact.
  /// It will insert the fact if it doesn't exist, or update it if it does.
  static Future<bool> changeFactFavoriteStatus(
    AiFactDto fact,
    bool isFavorite,
  ) async {
    try {
      final database = getIt.get<AppDatabase>();

      // Use insertOnConflictUpdate to either create a new record or update an existing one.
      await database
          .into(database.facts)
          .insertOnConflictUpdate(
            FactsCompanion(
              id: Value(fact.id),
              content: Value(fact.content),
              aiFactCategory: Value(fact.aiFactCategory),
              provider: Value(fact.provider),
              isFavorite: Value(isFavorite), // This is the value we're toggling
              dateAdded: Value(fact.dateAdded),
              dateModified: Value(
                DateTime.now(),
              ), // Update the modified timestamp
            ),
          );
      return true;
    } catch (e) {
      if (kDebugMode) print(e);
      return false;
    }
  }

  /// Returns a stream of all favorite facts, optionally filtered by categories.
  /// The stream automatically updates when the underlying data changes.
  static Stream<List<Fact>> watchAllFavoriteFacts(List<String> categories) {
    final db = getIt.get<AppDatabase>();
    final query = db.select(db.facts);

    // Always filter by isFavorite = true
    query.where((tbl) => tbl.isFavorite.equals(true));

    // --- Note: Using a more efficient 'isIn' query for categories ---
    // This is better than multiple 'LIKE' statements since a fact has only one category.
    if (categories.isNotEmpty) {
      query.where((tbl) => tbl.aiFactCategory.isIn(categories));
    }

    return query.watch();
  }

  /// Gets a single list of all favorite facts, optionally filtered by categories.
  static Future<List<Fact>> getAllFavoriteFacts(List<String> categories) async {
    final db = getIt.get<AppDatabase>();
    final query = db.select(db.facts)
      ..where((tbl) => tbl.isFavorite.equals(true));

    if (categories.isNotEmpty) {
      query.where((tbl) => tbl.aiFactCategory.isIn(categories));
    }

    return query.get();
  }

  /// Gets a list of just the IDs of all favorite facts.
  static Future<List<int>> getAllFavoriteFactIds() async {
    final db = getIt.get<AppDatabase>();

    // Using a custom query to select only the 'id' column for efficiency.
    // Note: Drift stores booleans as 0 and 1.
    final results = await db
        .customSelect(
          'SELECT id FROM facts WHERE is_favorite = 1',
          readsFrom: {db.facts},
        )
        .get();

    // Map the raw data row to a List<int>
    return results.map((row) => row.read<int>('id')).toList();
  }

  /// Saves a list of facts from DTOs into the database, ignoring duplicates.
  static Future<void> saveNewFactsToDatabase(List<AiFactDto> factDtos) async {
    final db = getIt.get<AppDatabase>();

    await db.batch((batch) {
      for (final dto in factDtos) {
        // Convert AiFactDto to a database companion object
        final factCompanion = FactsCompanion(
          id: Value(dto.id),
          content: Value(dto.content),
          aiFactCategory: Value(dto.aiFactCategory),
          provider: Value(dto.provider),
          isFavorite: const Value(
            false,
          ), // New facts are never favorites by default
          dateAdded: Value(dto.dateAdded),
          dateModified: Value(dto.dateModified),
        );

        // Insert the fact, or ignore it if a fact with the same ID already exists.
        batch.insert(db.facts, factCompanion, mode: InsertMode.insertOrIgnore);
      }
    });
  }

  /// Gets a paginated list of all facts from the local database.
  static Future<List<Fact>> getLocalFactsWithPagination({
    required int pageNumber,
    required int pageSize,
    required List<String> categories,
  }) async {
    final db = getIt.get<AppDatabase>();
    final offset = (pageNumber - 1) * pageSize;

    var query = db.select(db.facts)..limit(pageSize, offset: offset);

    if (categories.isNotEmpty) {
      query.where((tbl) => tbl.aiFactCategory.isIn(categories));
    }

    return await query.get();
  }
}
