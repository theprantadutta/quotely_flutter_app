/// Every route path in one place. Screens and notification payloads build
/// locations through these helpers instead of hand-writing strings.
class Routes {
  Routes._();

  // Onboarding
  static const onboarding = '/onboarding';
  static const interests = '/interests';
  static const notificationsOnboarding = '/notifications-onboarding';

  // Tabs
  static const today = '/home';
  static const scenes = '/scenes';
  static const saved = '/saved';
  static const people = '/people';
  static const facts = '/facts';

  // Pushed
  static const you = '/you';
  static const appearance = '/appearance';
  static const notifications = '/settings-notification';
  static const offlineLibrary = '/download-everything';
  static const support = '/support-us';
  static const pastMessages = '/past-messages';
  static const titleBase = '/title';
  static const authorBase = '/author-detail';
  static const search = '/search';
  static const debugComponents = '/debug/components';

  static String title(String id, {String? quoteId}) => Uri(
    path: '$titleBase/$id',
    queryParameters: quoteId == null ? null : {'quote': quoteId},
  ).toString();

  static String author(String slug) => '$authorBase/$slug';

  static String past(PastKind kind, {bool latest = false, String? highlight}) =>
      Uri(
        path: pastMessages,
        queryParameters: {
          'type': kind.slug,
          if (latest) 'latest': '1',
          'highlight': ?highlight,
        },
      ).toString();
}

/// The "of the day" feeds shown in Past messages, in chip order.
enum PastKind {
  quoteOfTheDay('quote-of-the-day', 'Quote of the day'),
  inspiration('daily-inspiration', 'Inspiration'),
  monday('motivation-monday', 'Monday'),
  fridayLines('friday-night-lines', 'Friday lines'),
  factOfTheDay('fact-of-the-day', 'Fact of the day'),
  brainFood('daily-brain-food', 'Brain food'),
  weirdWednesday('weird-fact-wednesday', 'Weird Wednesday');

  final String slug;
  final String label;
  const PastKind(this.slug, this.label);

  static PastKind parse(String? slug) => PastKind.values.firstWhere(
    (k) => k.slug == slug,
    orElse: () => PastKind.quoteOfTheDay,
  );
}

/// Pre-redesign routes. Notifications already in people's trays (and the
/// backend jobs) still send these as `routeName`, so each one keeps working:
/// the single "of the day" screens open Past messages with the newest item
/// highlighted, the lists open it on the matching chip, and the old tabs map
/// to their new names.
final Map<String, String> kLegacyRedirects = {
  '/favorites': Routes.saved,
  '/authors': Routes.people,
  '/settings': Routes.you,
  '/quote-of-the-day': Routes.past(PastKind.quoteOfTheDay, latest: true),
  '/quote-of-the-day-list': Routes.past(PastKind.quoteOfTheDay),
  '/daily-inspiration': Routes.past(PastKind.inspiration, latest: true),
  '/daily-inspiration-list': Routes.past(PastKind.inspiration),
  '/motivation-monday': Routes.past(PastKind.monday, latest: true),
  '/motivation-monday-list': Routes.past(PastKind.monday),
  '/fact-of-the-day': Routes.past(PastKind.factOfTheDay, latest: true),
  // Sic: the old list route really was "/fact-of-the-list".
  '/fact-of-the-list': Routes.past(PastKind.factOfTheDay),
  '/daily-brain-food': Routes.past(PastKind.brainFood, latest: true),
  '/daily-brain-food-list': Routes.past(PastKind.brainFood),
  '/weird-fact-wednesday': Routes.past(PastKind.weirdWednesday, latest: true),
  '/weird-fact-wednesday-list': Routes.past(PastKind.weirdWednesday),
  '/friday-night-lines': Routes.past(PastKind.fridayLines, latest: true),
};
