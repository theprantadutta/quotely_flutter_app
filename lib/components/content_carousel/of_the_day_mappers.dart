import 'package:intl/intl.dart';

import '../../dtos/daily_brain_food_dto.dart';
import '../../dtos/daily_inspiration_dto.dart';
import '../../dtos/fact_of_the_day_dto.dart';
import '../../dtos/motivation_monday_dto.dart';
import '../../dtos/of_the_day_adapters.dart';
import '../../dtos/quote_of_the_day_dto.dart';
import '../../dtos/weird_fact_wednesday_dto.dart';
import 'content_item.dart';
import 'content_mappers.dart';

/// Maps the date-stamped "feature" DTOs into [ContentItem]s for the shared
/// carousel card, surfacing the item's date as the card's eyebrow label.
final DateFormat _eyebrowDate = DateFormat('dd MMM, yyyy');

ContentItem contentItemFromQuoteOfTheDay(QuoteOfTheDayDto dto) =>
    contentItemFromQuote(
      dto.toQuoteDto(),
      eyebrow: _eyebrowDate.format(dto.quoteDate),
    );

ContentItem contentItemFromDailyInspiration(DailyInspirationDto dto) =>
    contentItemFromQuote(
      dto.toQuoteDto(),
      eyebrow: _eyebrowDate.format(dto.quoteDate),
    );

ContentItem contentItemFromMotivationMonday(MotivationMondayDto dto) =>
    contentItemFromQuote(
      dto.toQuoteDto(),
      eyebrow: _eyebrowDate.format(dto.quoteDate),
    );

ContentItem contentItemFromFactOfTheDay(FactOfTheDayDto dto) =>
    contentItemFromFact(
      dto.toAiFactDto(),
      eyebrow: _eyebrowDate.format(dto.factDate),
    );

ContentItem contentItemFromDailyBrainFood(DailyBrainFoodDto dto) =>
    contentItemFromFact(
      dto.toAiFactDto(),
      eyebrow: _eyebrowDate.format(dto.factDate),
    );

ContentItem contentItemFromWeirdFactWednesday(WeirdFactWednesdayDto dto) =>
    contentItemFromFact(
      dto.toAiFactDto(),
      eyebrow: _eyebrowDate.format(dto.factDate),
    );
