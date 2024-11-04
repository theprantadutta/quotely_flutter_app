import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../../dtos/quote_dto.dart';

class IsarService {
  late Future<Isar> db;

  /// Gets Called when we initiate a new Isar Instance
  IsarService() {
    db = openDB();
  }

  /// This functions opens up the database for CRUD operations
  Future<Isar> openDB() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      schemas: [QuoteDtoSchema],
      directory: dir.path,
      inspector: true,
    );
  }

  Future<bool> isFavourite(String quoteId) async {
    final isar = await openDB();
    final existingQuote =
        await isar.quoteDtos.where().idEqualTo(quoteId).findFirstAsync();
    return existingQuote == null ? false : existingQuote.isFavourite;
  }

  Future<bool> changeQuoteUpdateStatus(
      QuoteDto quoteDto, bool isFavourite) async {
    try {
      final isar = await openDB();
      // check if quote exists
      // final existingQuote =
      //     await isar.quoteDtos.where().idEqualTo(quoteDto.id).findFirstAsync();
      // if doesn't exist, create it
      // if (existingQuote == null) {
      await isar.writeAsync((isarDb) async {
        final newQuote = QuoteDto(
          id: quoteDto.id,
          author: quoteDto.author,
          content: quoteDto.content,
          tags: quoteDto.tags,
          authorSlug: quoteDto.authorSlug,
          length: quoteDto.length,
          isFavourite: isFavourite,
          dateAdded: quoteDto.dateAdded,
          dateModified: quoteDto.dateModified,
        );
        isarDb.quoteDtos.put(newQuote);
      });
      // }
      // // otherwise, just udpate it
      // else {
      //   await isar.writeAsync((isarDb) {
      //     final updatedQuote = QuoteDto(
      //       id: existingQuote.id,
      //       author: existingQuote.author,
      //       content: existingQuote.content,
      //       tags: existingQuote.tags,
      //       authorSlug: existingQuote.authorSlug,
      //       length: existingQuote.length,
      //       isFavourite: isFavourite,
      //       dateAdded: existingQuote.dateAdded,
      //       dateModified: existingQuote.dateModified,
      //     );
      //     isarDb.quoteDtos.put(updatedQuote);
      //   });
      // }
      return true;
    } catch (e) {
      if (kDebugMode) print(e);
      return false;
    }
  }
}
