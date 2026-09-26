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

/// The user's chosen interests (merged quote tags + fact categories). Used as
/// the base filter for the Home & Facts screens. Stored as a string list.
const kInterestsKey = 'user-interests';

/// Whether the user has completed the post-onboarding interest picker. Gates
/// entry to the app the same way onboarding does.
const kHasSelectedInterestsKey = 'has-selected-interests';

const kNotificationEnabled = 'notification-enabled';
const kNotificationMotivation = 'notification-motivation';
const kNotificationDailyInspiration = 'notification-daily-inspiration';
const kNotificationQuoteOfTheDay = 'notification-quote-of-the-week';
const kNotificationFactOfTheDay = 'notification-fact-of-the-day';
const kNotificationDailyBrainFood = 'notification-daily-brain-food';
const kNotificationWeirdFactWednesday = 'notification-weird-fact-wednesday';

/// Set once the notification-default prefs have been seeded + subscribed (see
/// [NotificationService.initializeNotificationPreferencesOnce]). Once true, the
/// Home startup job won't re-seed prefs and clobber the user's choices.
const kNotificationsInitializedKey = 'notifications_preferences_initialized';

/// Whether the user has been shown the post-interests notification permission +
/// preferences screen. Gates that screen the same way onboarding/interests do.
const kHasSeenNotificationPrompt = 'has-seen-notification-prompt';

/// Set once the user has donated. The donation products are non-consumable, so
/// a user can only ever buy one; this hides the donation tiles afterwards so we
/// don't ask again. Restored from the store on open too, for reinstalls.
const kIsSupporterKey = 'is-supporter';

// --- Thread redesign -------------------------------------------------------

/// Appearance (replaces the flex-scheme / Google-font / grid prefs above,
/// which are migrated once and then removed; see AppearanceSettings.load).
const kAppearanceThemeKey = 'appearance-theme-mode';
const kAppearanceAccentKey = 'appearance-accent';
const kAppearanceQuoteScaleKey = 'appearance-quote-scale';
const kAppearanceReadingFontKey = 'appearance-reading-font';
const kAppearanceLayoutKey = 'appearance-layout';
/// Legacy on/off for the glow; read once to seed [kAppearanceBackdropKey].
const kAppearanceGlowKey = 'appearance-background-glow';
const kAppearanceBackdropKey = 'appearance-backdrop';
const kAppearanceMigratedKey = 'appearance-migrated-v1';
const kSpotlightFontMigratedKey = 'appearance-spotlight-font-v1';

/// Interests → SCREEN picks (movie, tv, anime, game, cartoon). Kept apart from
/// [kInterestsKey] because those strings filter quote tags and fact
/// categories, and "Movies" is already a fact category.
const kScreenInterestsKey = 'screen-interests';

/// Scenes: spoiler shield (default on), followed title ids + slugs, and the
/// per-title "watched up to episode N" setting (JSON map titleId -> N).
const kSpoilerShieldKey = 'spoiler-shield-enabled';
const kFollowedTitlesKey = 'followed-title-ids';
const kFollowedTitleSlugsKey = 'followed-title-slugs';
const kWatchedUpToKey = 'watched-up-to-episode';

/// Authors the user follows (slugs). Local only; powers the People stories.
const kFollowedAuthorsKey = 'followed-author-slugs';

/// Recently opened people, newest first (JSON list of {kind,id,name,image}).
const kRecentPeopleKey = 'recent-people';

/// Daily activity log for the streak card: JSON map yyyy-MM-dd ->
/// {"q": quotesViewed, "s": scenesViewed, "f": factsViewed}.
const kActivityLogKey = 'activity-log';

/// Optional nickname; its initial fills the You avatar on Today.
const kNicknameKey = 'user-nickname';

/// Notifications added by the redesign.
const kNotificationFridayNightLines = 'notification-friday-night-lines';
const kNotificationFollowedTitles = 'notification-followed-titles';

/// Quiet hours, minutes after midnight. Foreground notifications that arrive
/// inside the window are not shown.
const kQuietHoursEnabledKey = 'quiet-hours-enabled';
const kQuietHoursStartKey = 'quiet-hours-start';
const kQuietHoursEndKey = 'quiet-hours-end';

/// Offline library: only download over Wi-Fi, and per-pack saved counts.
const kWifiOnlyKey = 'offline-wifi-only';
const kOfflinePackCountPrefix = 'offline-pack-count-';

/// Facts game: answers today (JSON {date, answered, correct}).
const kFactsGameProgressKey = 'facts-game-progress';
