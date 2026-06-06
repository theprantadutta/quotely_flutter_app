const kThemeModeKey = 'theme_mode_key';
const kFontFamilyKey = 'font_family_key';
const kIsDarkModeKey = 'is_dark_mode_key';
const kFlexSchemeKey = 'is_flex_scheme_key';
const kBiometricKey = 'biometric_key';
const kIsGridViewKey = 'is-grid-view';

/// Legacy key from the retired painted view modes (book/deck/scroll/
/// coverflow); removed on startup now that Home & Facts use one carousel.
const kLegacyContentViewModeKey = 'content-view-mode';

/// Bump this whenever terms.md or privacy.md changes in a way that requires
/// users to re-accept. Users who accepted an older version will see the
/// consent dialog again on next launch.
/// History:
///   2 = original terms (stored under the legacy 'hasAcceptedTermsV2' bool)
///   3 = added AI-generated content disclosure to privacy policy (2026-06-05)
const kCurrentLegalVersion = 3;
const kAcceptedLegalVersionKey = 'accepted-legal-version';

/// Legacy bool key from before legal versioning; migrated to
/// [kAcceptedLegalVersionKey] and removed on first read.
const kLegacyAcceptedTermsKey = 'hasAcceptedTermsV2';

/// One-time "swipe up for more" coach overlay on the Home/Facts carousel.
const kCarouselCoachShownKey = 'carousel-swipe-coach-shown';

const kNotificationEnabled = 'notification-enabled';
const kNotificationMotivation = 'notification-motivation';
const kNotificationDailyInspiration = 'notification-daily-inspiration';
const kNotificationQuoteOfTheDay = 'notification-quote-of-the-week';
const kNotificationFactOfTheDay = 'notification-fact-of-the-day';
const kNotificationDailyBrainFood = 'notification-daily-brain-food';
const kNotificationWeirdFactWednesday = 'notification-weird-fact-wednesday';
