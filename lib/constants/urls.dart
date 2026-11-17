import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final kApiProdUrl = dotenv.env['PROD_API_URL'];
final kApiDevUrl = dotenv.env['DEV_API_URL'];

/// Debug builds use the local dev API unless run with
/// `--dart-define=PROD_API=true` (on-device checks with real content).
final kApiUrl = kDebugMode && !const bool.fromEnvironment('PROD_API')
    ? kApiDevUrl
    : kApiProdUrl;

const kGetAllTags = 'Tag/GetAllTags';
const kGetAllAuthors = 'Author/GetAllAuthors';
const kGetAuthorDetails = 'Author/GetAuthorDetails';
const kGetAllQuotes = 'Quote/GetAllQuotes';
const kGetAllQuotesByAuthor = 'Quote/GetAllQuotesByAuthor';
const kGetMostLovedQuotesByAuthor = 'Quote/GetMostLovedQuotesByAuthor';

// The composer's "Ask": a question answered by tags the backend picks
const kGetAskAnswer = 'Ask/GetAnswer';

const kGetAllAiFacts = 'Fact/GetAllAiFacts';
const kGetAllAiFactCategories = 'Fact/GetAllAiFactCategories';
const kGetAllAiFactProviders = 'Fact/GetAllAiFactProviders';

const kGetAllQuoteOfTheDay = 'QuoteOfTheDay/GetAllQuoteOfTheDay';
const kGetTodayQuoteOfTheDay = 'QuoteOfTheDay/GetTodayQuoteOfTheDay';

const kGetAllDailyInspiration = 'DailyInspiration/GetAllDailyInspiration';
const kGetTodayDailyInspiration = 'DailyInspiration/GetTodayDailyInspiration';

const kGetAllMotivationMonday = 'MotivationMonday/GetAllMotivationMonday';
const kGetTodayMotivationMonday = 'MotivationMonday/GetTodayMotivationMonday';

const kGetAllFactOfTheDay = 'FactOfTheDay/GetAllFactOfTheDay';
const kGetTodayFactOfTheDay = 'FactOfTheDay/GetTodayFactOfTheDay';

const kGetAllDailyBrainFood = 'DailyBrainFood/GetAllDailyBrainFood';
const kGetTodayDailyBrainFood = 'DailyBrainFood/GetTodayDailyBrainFood';

const kGetAllWeirdFactWednesday = 'WeirdFactWednesday/GetAllWeirdFactWednesday';
const kGetTodayWeirdFactWednesday =
    'WeirdFactWednesday/GetTodayWeirdFactWednesday';

const kGetApplicationInfo = 'Application/GetApplicationInfo';

// Scenes (docs/scenes_api.md)
const kGetAllSceneQuotes = 'Scene/GetAllSceneQuotes';
const kGetAllTitles = 'Scene/GetAllTitles';
const kGetTrendingTitles = 'Scene/GetTrendingTitles';
const kGetTitleDetail = 'Scene/GetTitleDetail';
const kGetAllCharacters = 'Scene/GetAllCharacters';
const kGetTodaySceneOfTheDay = 'SceneOfTheDay/GetTodaySceneOfTheDay';
const kGetAllSceneOfTheDay = 'SceneOfTheDay/GetAllSceneOfTheDay';
const kGetTodayFridayNightLines = 'FridayNightLines/GetTodayFridayNightLines';
const kGetAllFridayNightLines = 'FridayNightLines/GetAllFridayNightLines';

// Upcoming releases tied to titles with lines ("Before Avengers: Doomsday")
const kGetComingSoon = 'Spotlight/GetComingSoon';
const kGetRetractions = 'Retractions/GetAll';
