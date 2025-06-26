import 'package:drift/drift.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';

import '../database/database.dart';

class DriftAuthorService {
  DriftAuthorService._(); // Private constructor

  /// Saves a list of authors from DTOs into the local database.
  /// It will update existing authors or insert new ones based on their ID.
  static Future<void> saveAuthorsToDatabase(List<AuthorDto> authorDtos) async {
    final db = getIt.get<AppDatabase>();

    await db.batch((batch) {
      for (final dto in authorDtos) {
        // Convert AuthorDto to a database companion object
        final authorCompanion = AuthorsCompanion(
          id: Value(dto.id),
          name: Value(dto.name),
          bio: Value(dto.bio),
          description: Value(dto.description),
          link: Value(dto.link),
          quoteCount: Value(dto.quoteCount),
          slug: Value(dto.slug),
          imageUrl: Value(dto.imageUrl),
          dateAdded: Value(dto.dateAdded),
          dateModified: Value(dto.dateModified),
        );

        // Insert the author, or replace them if an entry with the same ID already exists.
        batch.insert(
          db.authors,
          authorCompanion,
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Gets a paginated list of all authors from the local database, with optional search.
  static Future<List<Author>> getLocalAuthorsWithPagination({
    required int pageNumber,
    required int pageSize,
    required String searchTerm,
  }) async {
    final db = getIt.get<AppDatabase>();
    final offset = (pageNumber - 1) * pageSize;

    var query = db.select(db.authors)
      ..orderBy(
          [(a) => OrderingTerm(expression: a.name)]) // Order alphabetically
      ..limit(pageSize, offset: offset);

    // Apply a search filter if a search term is provided
    if (searchTerm.isNotEmpty) {
      query.where((tbl) => tbl.name.like('%$searchTerm%'));
    }

    return await query.get();
  }

  /// Gets a single author by their slug from the local database.
  static Future<Author?> getLocalAuthorBySlug(String authorSlug) async {
    final db = getIt.get<AppDatabase>();
    return await (db.select(db.authors)
          ..where((a) => a.slug.equals(authorSlug)))
        .getSingleOrNull();
  }
}
