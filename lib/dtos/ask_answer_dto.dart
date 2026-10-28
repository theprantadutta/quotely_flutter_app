import 'ai_fact_dto.dart';
import 'quote_dto.dart';

/// The backend's answer to an Ask question (GET Ask/GetAnswer).
///
/// [source] is how it was answered: `ai` (a new question), `cache` (asked
/// before), `keyword` (the backend's fallback search) or `empty`.
class AskAnswerDto {
  final String question;
  final String source;
  final List<String> tags;
  final List<QuoteDto> quotes;
  final List<AiFactDto> facts;

  const AskAnswerDto({
    required this.question,
    required this.source,
    required this.tags,
    required this.quotes,
    required this.facts,
  });

  factory AskAnswerDto.fromJson(Map<String, dynamic> json) => AskAnswerDto(
    question: json['question'] as String? ?? '',
    source: json['source'] as String? ?? '',
    tags: [
      for (final t in json['tags'] as List<dynamic>? ?? const []) t as String,
    ],
    quotes: [
      for (final q in json['quotes'] as List<dynamic>? ?? const [])
        QuoteDto.fromJson(q as Map<String, dynamic>),
    ],
    facts: [
      for (final f in json['facts'] as List<dynamic>? ?? const [])
        AiFactDto.fromJson(f as Map<String, dynamic>),
    ],
  );
}
