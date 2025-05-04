import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final kApiProdUrl = dotenv.env['PROD_API_URL'];
final kApiDevUrl = dotenv.env['DEV_API_URL'];
final kApiUrl = kDebugMode ? kApiDevUrl : kApiProdUrl;
// final kApiUrl = kApiProdUrl;

final kAppUpdateInfo = 'Application/GetApplicationInfo';

const kGetAllTags = 'Tag/GetAllTags';
const kGetAllAuthors = 'Author/GetAllAuthors';
const kGetAuthorDetails = 'Author/GetAuthorDetails';
const kGetAllQuotes = 'Quote/GetAllQuotes';
const kGetAllQuotesByAuthor = 'Quote/GetAllQuotesByAuthor';

const kGetAllAiFacts = 'Fact/GetAllAiFacts';
const kGetAllAiFactCategories = 'Fact/GetAllAiFactCategories';
const kGetAllAiFactProviders = 'Fact/GetAllAiFactProviders';

const kGetAllQuoteOfTheDay = 'QuoteOfTheDay/GetAllQuoteOfTheDay';
const kGetTodayQuoteOfTheDay = 'QuoteOfTheDay/GetTodayQuoteOfTheDay';

const kGetAllDailyInspiration = 'DailyInspiration/GetAllDailyInspiration';
const kGetTodayDailyInspiration = 'DailyInspiration/GetTodayDailyInspiration';

const kGetAllMotivationMonday = 'MotivationMonday/GetAllMotivationMonday';
const kGetTodayMotivationMonday = 'MotivationMonday/GetTodayMotivationMonday';
