import 'package:drift/drift.dart';
import 'package:quotely_flutter_app/dtos/tag_dto.dart';
import 'package:quotely_flutter_app/service_locator/init_service_locators.dart';

import '../database/database.dart';

class DriftTagService {
  DriftTagService._(); // Private constructor

  /// Returns a stream of all tags from the local database.
  /// The stream automatically updates when the underlying data changes.
  /// Tags are ordered by quote count to show popular ones first.
  static Stream<List<Tag>> watchAllTags() {
    final db = getIt.get<AppDatabase>();
    final query = db.select(db.tags)
      ..orderBy([
        (t) => OrderingTerm(expression: t.quoteCount, mode: OrderingMode.desc)
      ]);
    return query.watch();
  }

  /// Gets a single list of all tags from the local database.
  static Future<List<Tag>> getAllTags() async {
    final db = getIt.get<AppDatabase>();
    final query = db.select(db.tags)
      ..orderBy([
        (t) => OrderingTerm(expression: t.quoteCount, mode: OrderingMode.desc)
      ]);
    return query.get();
  }

  /// Saves a list of tags from DTOs into the database.
  /// It will update existing tags or insert new ones.
  static Future<void> saveTagsToDatabase(List<TagDto> tagDtos) async {
    final db = getIt.get<AppDatabase>();

    await db.batch((batch) {
      for (final dto in tagDtos) {
        // Convert TagDto to a database companion object
        final tagCompanion = TagsCompanion(
          id: Value(dto.id),
          name: Value(dto.name),
          slug: Value(dto.slug),
          quoteCount: Value(dto.quoteCount),
          dateAdded: Value(dto.dateAdded),
          dateModified: Value(dto.dateModified),
        );

        // Insert the tag, or update it if a tag with the same ID already exists.
        batch.insert(
          db.tags,
          tagCompanion,
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Gets a paginated list of all tags from the local database.
  static Future<List<Tag>> getLocalTagsWithPagination({
    required int pageNumber,
    required int pageSize,
  }) async {
    final db = getIt.get<AppDatabase>();
    final offset = (pageNumber - 1) * pageSize;

    // The query will order by the most used tags first.
    final query = db.select(db.tags)
      ..orderBy([
        (t) => OrderingTerm(expression: t.quoteCount, mode: OrderingMode.desc)
      ])
      ..limit(pageSize, offset: offset);

    return await query.get();
  }
}
