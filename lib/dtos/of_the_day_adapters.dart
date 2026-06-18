import 'ai_fact_dto.dart';
import 'daily_brain_food_dto.dart';
import 'daily_inspiration_dto.dart';
import 'fact_of_the_day_dto.dart';
import 'motivation_monday_dto.dart';
import 'quote_of_the_day_dto.dart';
import 'quote_dto.dart';
import 'weird_fact_wednesday_dto.dart';

/// Adapters that convert the various "feature" DTOs (Quote/Fact of the Day,
/// Daily Inspiration, etc.) into the base [QuoteDto] / [AiFactDto] used by the
/// content carousel. Each feature DTO is the same underlying quote/fact wrapped
/// with a date, so these let every feature screen reuse the shared ContentCard
/// and the existing quote/fact action bundles (favorite/share/report key on the
/// real quote/fact id).

extension QuoteOfTheDayAdapter on QuoteOfTheDayDto {
  QuoteDto toQuoteDto() => QuoteDto(
    id: quoteId,
    author: author,
    content: content,
    tags: tags,
    authorSlug: authorSlug,
    length: length,
    dateAdded: quoteDateAdded,
    dateModified: quoteDateModified,
  );
}

extension DailyInspirationAdapter on DailyInspirationDto {
  QuoteDto toQuoteDto() => QuoteDto(
    id: quoteId,
    author: author,
    content: content,
    tags: tags,
    authorSlug: authorSlug,
    length: length,
    dateAdded: quoteDateAdded,
    dateModified: quoteDateModified,
  );
}

extension MotivationMondayAdapter on MotivationMondayDto {
  QuoteDto toQuoteDto() => QuoteDto(
    id: quoteId,
    author: author,
    content: content,
    tags: tags,
    authorSlug: authorSlug,
    length: length,
    dateAdded: quoteDateAdded,
    dateModified: quoteDateModified,
  );
}

extension FactOfTheDayAdapter on FactOfTheDayDto {
  AiFactDto toAiFactDto() => AiFactDto(
    id: factId,
    content: content,
    aiFactCategory: aiFactCategory,
    provider: provider,
    dateAdded: factDateAdded,
    dateModified: factDateModified,
  );
}

extension DailyBrainFoodAdapter on DailyBrainFoodDto {
  AiFactDto toAiFactDto() => AiFactDto(
    id: factId,
    content: content,
    aiFactCategory: aiFactCategory,
    provider: provider,
    dateAdded: factDateAdded,
    dateModified: factDateModified,
  );
}

extension WeirdFactWednesdayAdapter on WeirdFactWednesdayDto {
  AiFactDto toAiFactDto() => AiFactDto(
    id: factId,
    content: content,
    aiFactCategory: aiFactCategory,
    provider: provider,
    dateAdded: factDateAdded,
    dateModified: factDateModified,
  );
}
