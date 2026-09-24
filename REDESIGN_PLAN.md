# Thread redesign: plan

Source of truth: `quotely-thread-screens/{light,dark}/01–17*.png` and the
implementation brief. Branch: `redesign/thread`.

Scope change during the work: Scenes are backed by a real backend feature
(AI-generated, in `quotely-dotnet-api`) rather than seed data only. The API
contract lives in [`docs/scenes_api.md`](docs/scenes_api.md). The bundled seed
(`assets/data/scenes_seed.json`) is kept as the offline and first-launch
fallback.

## Architecture (unchanged)

Riverpod (codegen) for state, go_router, Drift for the offline cache, static
service classes for HTTP, SharedPreferences for settings. Nothing new is
introduced except `connectivity_plus` (Wi-Fi-only downloads) and
`flutter_launcher_icons` (dev).

## Phases

1. **Foundation** (`lib/theme/`)
   - `tokens.dart`: `QuotelyTokens` ThemeExtension (neutrals + accent roles), 5 accents × 2 brightnesses.
   - `typography.dart`: `QuotelyText` ThemeExtension, Manrope (bundled), reading font (Sans/Serif/Mono, bundled) and text-size multiplier baked into the quote styles.
   - `app_theme.dart`: Material 3 `ThemeData` mapping + system UI style.
   - `appearance.dart`: `AppearanceController` (theme mode, accent, text size, reading font, default layout), persisted, with a one-time migration from the old flex-scheme / font / grid prefs.
2. **Components** (`lib/components/thread/`): everything in brief §4, plus `/debug/components`.
3. **Navigation**: Today · Scenes · Saved · People · Facts. `/you`, `/title/:id`, `/past-messages`. Old routes redirect. Notification deep links.
4. **Scenes data layer**: DTOs, Drift tables (schema v3), `SceneRepository` (API → Drift cache → seed), providers.
5. **Screens**: Today → Scenes → Title detail → Saved (+ collections) → People → Author detail → Facts → Past messages → Report sheet → You → Appearance → Notifications → Offline library → Support → Welcome → Interests → Notification primer.
6. **Brand assets**: launcher icons, notification icon, splash, web, in-app logo.
7. **Cleanup**: dead files and assets, analyze, format, tests.

## Files

Added: `lib/theme/*`, `lib/components/thread/*`, `lib/dtos/{media_title,character,scene_quote,scene_of_the_day}*_dto.dart`,
`lib/entities/{media_titles,characters,scene_quotes,collections,collection_items}.dart`,
`lib/services/{scene_service,drift_scene_service,scene_repository,drift_collection_service,composer_search_service,streak_service}.dart`,
`lib/riverpods/scene_providers.dart`, `lib/state_providers/{favorite_scene_ids,followed_title_ids,spoiler_shield,screen_interests}.dart`,
`lib/screens/{scenes,title_detail,past_messages,you,debug_components}_screen.dart`, `assets/data/scenes_seed.json`, `assets/fonts/*`, `assets/brand/*`.

Replaced (rewritten in place): home, favorites (Saved), authors (People), facts, author detail, onboarding, interests, notification primer, settings notification, download everything (Offline library), support, appearance, report quote/fact dialogs (sheets), bottom navigation.

Deleted when unreferenced: aurora background, dark gradient background, floating theme button, top navigation bar, grid/list toggle state, flex scheme picker, the six `*_list_screen` + six single "of the day" screens and their components (routes kept as redirects into Past messages), onboarding PNGs, old splash assets.

## Status

See the "Shipped" section at the end (filled in as phases land).

## Shipped

All 17 screens, both themes, 5 accents, and the component library
(`lib/components/thread/`, with a gallery at `/debug/components`). To open
it in a debug build, long-press "Made by Pranta Dutta" on You.

### Scenes (end to end)
- **Backend** (`quotely-dotnet-api`): entities + migration `AddScenes`, the
  `Scene`, `SceneOfTheDay` and `FridayNightLines` endpoints, and
  `GenerateAiSceneJob` (AI, provider fallback, dedup, spoiler flags, optional
  TMDB posters). It runs Mon and Fri at 22:30 UTC.
  - `SceneOfTheDayJob` runs daily at 12:30 UTC.
  - `FridayNightLinesJob` runs Fri at 19:00 UTC and pushes to the
    `friday_night_lines` topic.
  - When new lines are added to a title, a push goes to `title_<slug>`.
- **App**: DTOs, Drift cache (schema v3), `SceneRepository` (API → Drift →
  bundled seed), Scenes tab, Title detail, spoiler shield (plus
  per-title "watched up to episode N"), follow, Saved › Scenes, Past messages
  › Friday lines, and the offline Scenes pack.
- **Seed**: 18 titles, 61 characters and 82 short lines (8 spoilers). It is
  used offline and before the backend has generated anything.

### Facts game
- **Backend**: `AiFact.FalseVariant` (migration `AddFactFalseVariant`), and
  `GenerateFactFalseVariantsJob` every 2 h, 25 facts per run. The field is
  exposed on `GetAllAiFacts` and on the three fact "of the day" endpoints.
- **App**: Play turns on automatically once facts arrive with a
  `falseVariant`; until then the tab opens in Browse. `kFactsGameEnabled`
  forces Play on.

### Still behind TODO(backend)
- **Semantic composer search.** `ComposerSearchService` does local matching:
  known tags go to the quotes endpoint, media words route to Scenes, anything
  else is a keyword search of the Drift cache.
- **Quiet hours server-side.** They are enforced on-device for foreground
  notifications only.
- **Scene likes are not synced.** `likes` is shown from the API plus your own
  heart.

### Deviations from the design, and why
- **Cards layout.** It is a list of full-width cards (`QuoteCard`) in the same
  scroll view, not the nested vertical PageView. The PageView doesn't compose
  with Today's header, thread and composer.
- **People previews.** `AuthorDto` has no quote, so the one-line preview is
  the author's description. Characters show their title.
- **Story rings.** An `acc` ring marks authors you follow. There is no "new
  quotes since last visit" data.
- **Offline sizes.** The API gives no byte sizes, so the summary shows packs
  and item counts, not MB. Portraits and posters aren't downloaded.
- **Support tiers.** Two tiers, from the two real store products
  (`buy_me_a_coffee_1`, `support_the_dev_1`). Titles and prices come from the
  store.
- **Nickname.** You has a "Your name" row (the brief's optional nickname for
  the Today avatar).
- **Welcome pages.** "Get started" finishes onboarding on every page, as in
  the screenshot. The pages auto-advance until the user touches them.
- **Minimum interests.** Changed from 10 to 3 (brief §5.2).
- **Platforms.** Android and iOS only. Web and desktop icons and splash were
  not regenerated.
- **iOS 18 icons.** The dark and tinted variants are added as universal 1024
  entries alongside the legacy sizes in `AppIcon.appiconset/Contents.json`.
  This couldn't be built on Windows; check it with Xcode 16.

### Removed
- Aurora and dark gradient backgrounds, the floating theme button, the top
  navigation bar, the grid/list toggle and the flex-scheme picker.
- Google Fonts at runtime (fonts are bundled now).
- The six list and six single "of the day" screens. Their routes redirect
  to Past messages.
- The onboarding PNGs, the old splash assets and old icons.
- Packages: flex_color_scheme, google_fonts, skeletonizer,
  loading_animation_widget, animate_do, smooth_page_indicator, hexcolor,
  font_awesome_flutter, motion_toast.
