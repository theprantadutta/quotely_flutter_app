import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../constants/urls.dart';
import '../dtos/ask_answer_dto.dart';
import 'drift_quote_service.dart';
import 'local_first.dart';

/// The backend's "Ask" (GET Ask/GetAnswer): the question goes to the server,
/// which picks tags for it (once per question, then from its cache) and
/// returns matching quotes. Answers are kept on the device too, through
/// [LocalFirst.get], so a repeated question answers at once and works
/// offline. Throws on any failure; [ComposerSearchService] then falls back
/// to the local search.
class AskService {
  AskService._();

  /// The backend's normalization (less its accent folding): lowercase,
  /// punctuation and symbols dropped, spaces collapsed, trimmed. It is also
  /// the local cache key, so "Starting over!" and "starting over" share one
  /// answer.
  static String normalize(String question) => question
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static Future<AskAnswerDto> answer(String question, {required int limit}) async {
    final normalized = normalize(question);
    if (normalized.isEmpty) throw ArgumentError('Nothing to ask');
    final uri = Uri.parse('$kApiUrl/$kGetAskAnswer').replace(
      queryParameters: {'question': normalized, 'pageSize': '$limit'},
    );
    final response = await LocalFirst.get(uri.toString());
    if (response.statusCode != 200 || response.data is! String) {
      throw Exception('Ask request failed: ${response.statusCode}');
    }
    final dto = AskAnswerDto.fromJson(
      json.decode(response.data as String) as Map<String, dynamic>,
    );
    // Keep the quotes for the offline search and the library, like a feed page.
    DriftQuoteService.saveNewQuotesToDatabase(dto.quotes).catchError(
      (Object e) => debugPrint('AskService: could not save quotes: $e'),
    );
    return dto;
  }
}
