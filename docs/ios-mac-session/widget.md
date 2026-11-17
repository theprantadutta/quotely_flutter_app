# iOS: wire up the Quotely widgets (Mac session)

Quotely has **five** widgets, all in **one** widget extension
(`QuotelyWidget`) with one `WidgetBundle`:

| Widget | WidgetKit kind | Families | Tap opens |
| --- | --- | --- | --- |
| Quote of the Day | `QuotelyWidget` | systemSmall, systemMedium, accessoryRectangular (iOS 16+) | Today |
| From your saved | `QuotelySavedWidget` | systemSmall, systemMedium, accessoryRectangular (iOS 16+) | Saved tab |
| Scene of the Day | `QuotelySceneWidget` | systemSmall, systemMedium, accessoryRectangular (iOS 16+) | Today |
| Minimal quote (new, 2026-11-17) | `QuotelyMinimalWidget` | systemSmall, systemMedium, systemLarge, accessoryRectangular (iOS 16+) | Today |
| Today, small (new, 2026-11-17) | `QuotelySquareWidget` | systemSmall, accessoryCircular (iOS 16+) | Today |

> **Next Mac session: the two new widgets.** Minimal quote and Today, small
> were written on Windows and have **not been compiled**. The exact steps and
> the device checklist are in section 9 at the end of this file. Sections 1
> to 8 below are the original setup, already done (commit `1f30fc6`).

The iOS widgets are written but not yet part of the Xcode project. Adding an
extension target means editing `ios/Runner.xcodeproj/project.pbxproj`, which is
only safe from Xcode, so it was left for a session on a Mac. This file is the
complete checklist for that session.

Steps marked **[HUMAN]** need a person signed in to the Apple Developer account
(developer.apple.com / App Store Connect). Everything else can be done by
Claude Code on the Mac, in Xcode or the terminal.

## What already exists (do not recreate)

| Path | What it is |
| --- | --- |
| `ios/QuotelyWidget/QuotelyWidgetShared.swift` | Shared by all three: App Group id, kinds, tap URLs, fonts, palette, saved-poster loader, the day's glow (`GlowHue`, `DayGlowView`), the Home Screen card (`WidgetCard`), the Lock Screen card (`LockScreenCard`), `FamilyCard` (picks one by family), `quotelyFamilies()`, and the iOS 16/17 availability shims |
| `ios/QuotelyWidget/QuotelyWidget.swift` | Quote of the Day: widget, `TimelineProvider`, entry, view, previews |
| `ios/QuotelyWidget/SavedQuoteWidget.swift` | From your saved: widget, provider (daily timeline), entry, view, previews |
| `ios/QuotelyWidget/SceneWidget.swift` | Scene of the Day: widget, provider, entry, view, previews |
| `ios/QuotelyWidget/MinimalQuoteWidget.swift` | Minimal quote: widget, provider (reads the Quote of the Day keys), entry, `MinimalCard`, `MinimalLockScreenCard`, previews |
| `ios/QuotelyWidget/SquareQuoteWidget.swift` | Today, small: widget, provider (daily timeline for the glow), entry, `SquareCard`, `SquareLockScreenMark`, previews |
| `ios/QuotelyWidget/QuotelyWidgetBundle.swift` | `@main` `WidgetBundle` listing the five widgets |
| `ios/QuotelyWidget/Info.plist` | Extension Info.plist (`com.apple.widgetkit-extension`, `UIAppFonts`, Flutter build name/number) |
| `ios/QuotelyWidget/QuotelyWidget.entitlements` | App Group `group.com.pranta.quotely` |
| `ios/QuotelyWidget/Fonts/InstrumentSerif-Regular.ttf` | Quote font (PostScript name `InstrumentSerif-Regular`) |
| `ios/QuotelyWidget/Fonts/IBMPlexMono-Medium.ttf` | Eyebrow font (PostScript name `IBMPlexMono-Medium`) |
| `ios/Runner/Runner.entitlements` | Now also has the App Group `group.com.pranta.quotely` |
| `lib/services/home_widget_store.dart` | Dart side, shared: kinds, App Group, poster crop/blur, glow days, redraws |
| `lib/services/quote_widget_service.dart` | Dart side: Quote of the Day data |
| `lib/services/saved_widget_service.dart` | Dart side: From your saved data (30 days of picks) |
| `lib/services/scene_widget_service.dart` | Dart side: Scene of the Day data |
| `lib/services/widget_analytics.dart` | Dart side: placed / removed / opened analytics |
| `lib/components/quote_widget_bridge.dart` | Dart side: when to save, and widget taps -> Today or Saved |
| `lib/components/quote_widget_intro.dart` | In-app introduction, You -> Home-screen widgets chooser, "Add the widget" steps |

Contract between the app and the widget (all set by the Dart side already):

- `HomeWidget.setAppGroupId('group.com.pranta.quotely')` is called before any
  save on iOS.
- UserDefaults suite `group.com.pranta.quotely`. Keys (App Group keys):

  | Key | Type | Written by | Read by |
  | --- | --- | --- | --- |
  | `qotd_text`, `qotd_author` | String | QuoteWidgetService | Quote of the Day, Minimal quote, Today, small |
  | `qotd_date` | String yyyy-MM-dd | QuoteWidgetService | (informational) |
  | `qotd_short` | String: the quote when it is at most 60 characters, else empty | QuoteWidgetService (`shortLine`) | Today, small |
  | `qotd_eyebrow` | String: the quote's day, "TUE · NOV 17" | QuoteWidgetService (`eyebrow`) | Today, small (when `qotd_short` is empty) |
  | `qotd_poster` | String: absolute path of `.../home_widget/qotd_poster.png` in the App Group container, already blurred | QuoteWidgetService | Quote of the Day |
  | `qotd_poster_url` | String | QuoteWidgetService | (the app, to skip re-blurring) |
  | `saved_days` | String, JSON `{"start":"yyyy-MM-dd","quotes":[{"t":text,"a":author}, ...]}`: 30 entries, entry i is the pick for start + i days; empty `quotes` when nothing is saved | SavedWidgetService | From your saved |
  | `saved_count` | Int, number of saved quotes (0 shows the hint "Save a quote you love and it will live here.") | SavedWidgetService | From your saved |
  | `scene_eyebrow` | String, "SCENE · <TITLE>" already upper-cased | SceneWidgetService | Scene of the Day |
  | `scene_text`, `scene_character`, `scene_title` | String | SceneWidgetService | Scene of the Day |
  | `scene_title_id`, `scene_date` | String | SceneWidgetService | (informational) |
  | `scene_poster` | String: absolute path of `.../home_widget/scene_poster.png`, already blurred | SceneWidgetService | Scene of the Day |
  | `scene_poster_url` | String | SceneWidgetService | (the app) |
  | `glow_days` | String, JSON `{"start":"yyyy-MM-dd","light":[ARGB ints],"dark":[ARGB ints]}`: the app's day glow for 30 days | HomeWidgetStore (saved, scene and quote services) | From your saved, Scene of the Day (when no poster), Today, small |

  Past the 30 days (the app not opened for a month) the widgets wrap round:
  `index = days since start mod count`. The glow repeats every 5 days, so it
  stays right forever; the saved quotes repeat a 30-day cycle.
- Widget **kinds**: `QuotelyWidget`, `QuotelySavedWidget`, `QuotelySceneWidget`,
  `QuotelyMinimalWidget`, `QuotelySquareWidget`. When the quote changes, Dart
  reloads all three kinds that show it (`QuotelyWidgetKind.quoteOfTheDayReaders`).
  Dart calls `HomeWidget.updateWidget(iOSName: <kind>)`, which is
  `WidgetCenter.shared.reloadTimelines(ofKind: <kind>)`. The kind strings in
  Swift (`WidgetKindName`) must match `QuotelyWidgetKind.iOSKind` in
  `lib/services/home_widget_store.dart`.
- Tap URLs (`LaunchURL` in `QuotelyWidgetShared.swift`):
  `quotely://widget/home?homeWidget&kind=qotd`,
  `quotely://widget/saved?homeWidget&kind=saved`,
  `quotely://widget/home?homeWidget&kind=scene`,
  `quotely://widget/home?homeWidget&kind=minimal`,
  `quotely://widget/home?homeWidget&kind=square`. home_widget recognises widget
  launches by the `homeWidget` query item; the path is the Flutter route
  (`/home` Today, `/saved` Saved); `kind` is logged as `widget_opened`
  {widget_kind}.
- Analytics on iOS: there is no "widget added" callback, so at each app start
  `WidgetAnalytics.flushPlacements` calls `HomeWidget.getInstalledWidgets()`
  (`WidgetCenter.getCurrentConfigurations`) and logs `widget_placed` /
  `widget_removed` for kinds that appeared or disappeared since the last run.
  Nothing to set up in Xcode for this.
- The home_widget iOS plugin is already registered through Swift Package
  Manager with the other plugins (`flutter pub get` regenerates
  `FlutterGeneratedPluginSwiftPackage`). The **app** uses it; the **extension
  does not** link Flutter or any plugin. Do not add
  `FlutterGeneratedPluginSwiftPackage` to the extension target.

## 1. [HUMAN] Apple Developer portal

Do this first: the Runner entitlements already ask for the App Group, so a
release signing of Runner fails until the profiles below include it.

1. Certificates, Identifiers & Profiles -> Identifiers -> **+** -> **App
   Groups** -> description `Quotely`, identifier `group.com.pranta.quotely`.
2. Identifiers -> `com.pranta.quotely` -> enable **App Groups** -> Configure ->
   tick `group.com.pranta.quotely` -> Save. (Push Notifications stays on.)
3. Identifiers -> **+** -> App IDs -> App -> description `Quotely Widget`,
   explicit bundle ID `com.pranta.quotely.QuotelyWidget` -> enable **App
   Groups** and configure it with `group.com.pranta.quotely` -> Register.
4. Profiles. Runner's Release and Profile configurations use **manual**
   signing with the App Store profile **"New Quotely App"**.
   - Edit "New Quotely App" (or regenerate it) so it is built from the App ID
     that now has App Groups, then download it / let Xcode fetch it. An old
     copy of the profile without the App Group will fail signing with
     "Provisioning profile doesn't include the com.apple.security.application-groups entitlement".
   - Create an App Store distribution profile for
     `com.pranta.quotely.QuotelyWidget`, e.g. named **"Quotely Widget"**.
   - Debug uses automatic signing; Xcode creates development profiles itself
     once the App IDs above exist.

If you would rather move both targets to automatic signing, that also works
(Xcode registers the App IDs and group for you), but it changes the release
setup the app has shipped with so far; ask the owner first.

## 2. Create the extension target in Xcode

1. `flutter pub get` at the repo root, then `open ios/Runner.xcworkspace`
   (the workspace, not the project).
2. File -> New -> Target... -> iOS -> **Widget Extension** -> Next.
   - Product Name: **`QuotelyWidget`**
   - Team: the Quotely team (`9M6X7M798T`)
   - Bundle Identifier: must end up as **`com.pranta.quotely.QuotelyWidget`**
   - **Untick** "Include Live Activity", "Include Control" and "Include
     Configuration App Intent" (this is a static widget).
   - Project: Runner, Embed in Application: **Runner**.
   - Finish; when asked to activate the `QuotelyWidget` scheme, choose
     **Activate** (switch back to the Runner scheme afterwards for normal runs).
3. Xcode creates a `QuotelyWidget` group pointing at `ios/QuotelyWidget/`,
   which already contains our files. It also writes its template files there.
   **Delete the template files** (Move to Trash), keeping ours:
   - delete `QuotelyWidget.swift` *only if* Xcode overwrote ours; check
     `git status` / `git diff ios/QuotelyWidget` and restore ours with
     `git checkout -- ios/QuotelyWidget/QuotelyWidget.swift` if needed;
   - delete the template `QuotelyWidgetBundle.swift` the same way (restore
     ours from git);
   - delete `QuotelyWidgetLiveActivity.swift`, `QuotelyWidgetControl.swift`,
     `AppIntent.swift` if any were generated;
   - the template `Assets.xcassets` (AccentColor/WidgetBackground) can be
     deleted; nothing uses it.
   - If Xcode wrote its own `Info.plist`, restore ours from git.
   After this, `git status ios/QuotelyWidget` should show no changes to our
   nine files (five Swift files, Info.plist, the entitlements, two fonts).
4. Add our files to the target if Xcode did not pick them up: right-click the
   `QuotelyWidget` group -> Add Files to "Runner"... -> select
   `QuotelyWidgetShared.swift`, `QuotelyWidget.swift`,
   `SavedQuoteWidget.swift`, `SceneWidget.swift`, `QuotelyWidgetBundle.swift`,
   and the `Fonts` folder -> "Create groups", Targets: **QuotelyWidget only**
   (not Runner).
   Then check QuotelyWidget target -> Build Phases:
   - **Compile Sources**: all five: `QuotelyWidgetShared.swift`,
     `QuotelyWidget.swift`, `SavedQuoteWidget.swift`, `SceneWidget.swift`,
     `QuotelyWidgetBundle.swift`. A missing one shows up as "cannot find
     'SavedQuoteWidget' in scope" (or similar) in the bundle file.
   - **Copy Bundle Resources**: `InstrumentSerif-Regular.ttf`,
     `IBMPlexMono-Medium.ttf`. (Without this the fonts silently fall back to
     the system serif / system font.)
   - `Info.plist` and `QuotelyWidget.entitlements` must NOT be in Copy Bundle
     Resources.

## 3. QuotelyWidget target build settings

Set for **all three** configurations (Debug, Release, Profile):

| Setting | Value |
| --- | --- |
| Product Bundle Identifier | `com.pranta.quotely.QuotelyWidget` |
| iOS Deployment Target (General -> Minimum Deployments) | **15.0**, same as Runner. Flutter requires extension and app to match. Do NOT raise it to get the Lock Screen: the code already guards iOS 16 and 17 APIs (section "Lock Screen and iOS versions"). |
| Info.plist File (`INFOPLIST_FILE`) | `QuotelyWidget/Info.plist` |
| Generate Info.plist File (`GENERATE_INFOPLIST_FILE`) | No |
| Code Signing Entitlements (`CODE_SIGN_ENTITLEMENTS`) | `QuotelyWidget/QuotelyWidget.entitlements` |
| Swift Language Version | 5 (same as Runner) |
| Targeted Device Family | 1,2 (iPhone, iPad), same as Runner |
| User Script Sandboxing | No (same as Runner; harmless) |

Signing, mirroring Runner:

- Debug: Automatic, team `9M6X7M798T`.
- Release and Profile: Manual, "iPhone Distribution", team `9M6X7M798T`,
  provisioning profile **"Quotely Widget"** (from step 1.4).

Versions: our Info.plist uses `$(FLUTTER_BUILD_NAME)` and
`$(FLUTTER_BUILD_NUMBER)` so the extension always matches the app (App Store
Connect rejects an extension whose version differs from the app's). Those
variables come from `Flutter/Generated.xcconfig`, so give the extension the same
base configurations as Runner: Project Runner -> Info -> Configurations ->
expand Debug / Release / Profile and set **QuotelyWidget** to
`Debug` -> `Flutter/Debug.xcconfig`, `Release` -> `Flutter/Release.xcconfig`,
`Profile` -> `Flutter/Release.xcconfig` (exactly what Runner uses).
After building once, check the built `QuotelyWidget.appex/Info.plist` shows
`3.0.2` / `22` (or whatever `pubspec.yaml` says), not empty strings.

## 4. App Groups capability on both targets

1. Runner target -> Signing & Capabilities: an **App Groups** capability
   should already show (it reads `Runner/Runner.entitlements`) with
   `group.com.pranta.quotely` ticked. If not, + Capability -> App Groups ->
   tick/add `group.com.pranta.quotely`. Keep Push Notifications.
2. QuotelyWidget target -> Signing & Capabilities -> + Capability -> **App
   Groups** -> tick `group.com.pranta.quotely`. Xcode must keep using
   `QuotelyWidget/QuotelyWidget.entitlements` (no second entitlements file).
3. No red errors on either target's signing section for Debug or Release.

## 5. Runner build phases (Flutter-specific)

Runner target -> Build Phases: drag **Embed Foundation Extensions** (Xcode adds
it with the target) so it sits **above** "Run Script" and "Thin Binary".
Otherwise the build fails with "Cycle inside Runner; building could produce
unreliable results". Then run `flutter build ios --config-only` once.

## 6. Build and test

1. `flutter build ios --release --no-codesign` from the repo root: must
   succeed with the extension embedded (`build/ios/iphoneos/Runner.app/PlugIns/QuotelyWidget.appex`).
2. Simulator (debug is fine here): select the Runner scheme, run on an iPhone
   simulator, let Today load (quote + poster), then go to the home screen.
   Long-press -> Edit -> Add Widget -> Quotely. The gallery must show **three**
   widgets (Quote of the Day, From your saved, Scene of the Day), each in small
   and medium. Add **small** and **medium** of each. Quote of the Day checks
   (the full checklist for all three is in "Device test checklist" below):
   - eyebrow "QUOTE OF THE DAY" in IBM Plex Mono, quote in Instrument Serif,
     author below;
   - the poster shows blurred under a light wash (light mode) / dark wash (dark
     mode: Settings -> Developer -> Dark Appearance, or Features -> Toggle
     Appearance in Simulator); with no poster, plain paper `#F3EEE5` /
     night `#15120F`;
   - a long quote shrinks and then truncates with an ellipsis, never overflows;
   - tapping opens the app on **Today** both from a cold start (kill the app
     first) and when it is in the background.
   - The gallery preview shows the sample Mandela quote before the app has
     ever saved one.
3. Device: `flutter run --release` (widget extensions plus a debug Flutter
   build on a physical device are unreliable). Repeat the checks; also put the
   app in the background after a pull-to-refresh on Today and confirm the
   widget updates.
4. To debug the extension itself: choose the QuotelyWidget scheme, Run, pick
   the Home Screen as the host. If the fonts are not applied, check the Copy
   Bundle Resources step and print `UIFont.familyNames` in the provider.
5. Check the in-app UI that tells people about the widgets
   (`lib/components/quote_widget_intro.dart`):
   - **You -> Home-screen widgets** ("Quote of the Day, your saved quotes, or
     a scene") opens a chooser with the three widgets as small previews and
     "Add widget". iOS has no API to add a widget, so on iOS "Add widget"
     always opens the "Add the widget" sheet with these steps (`<Widget>` is
     the chosen widget's name):
     1. "Touch and hold an empty spot on your Home Screen until the apps jiggle."
     2. "Tap + (or Edit, then Add Widget) in the top corner."
     3. "Search for Quotely, swipe to `<Widget>`, pick a size and tap Add Widget."
     and a note: "On the Lock Screen: touch and hold it, tap Customize, pick
     the Lock Screen, then tap the area under the clock and choose Quotely."
     **Follow them on the simulator and on the device's iOS version and make
     sure they match what iOS actually shows** (button names and placement
     changed in iOS 18: "Edit" -> "Add Widget"). If they don't, fix the
     strings in `showQuoteWidgetHowTo` and the expectations in
     `test/quote_widget_intro_test.dart`.
   - The one-time introduction sheet on Today ("NEW · HOME-SCREEN WIDGETS",
     the same three previews, "Put Quotely on your home screen", Add widget /
     Not now). It appears once, only after
     onboarding is complete, and only from the second app open on. To see it
     again on a test install, delete the app (or clear its
     `quote-widget-intro-shown` / `app-open-count` preferences) and open it
     twice after finishing onboarding. "Add widget" on iOS leads to the same
     instructions sheet.
6. If a tap opens the app but does **not** land on Today, register the URL
   scheme in `ios/Runner/Info.plist` (normally not needed for widget URLs):

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLName</key>
       <string>com.pranta.quotely.widget</string>
       <key>CFBundleURLSchemes</key>
       <array><string>quotely</string></array>
     </dict>
   </array>
   ```

## 6a. Lock Screen and iOS versions

- Deployment target stays **15.0** (Runner's). Everything newer is guarded:
  - `.accessoryRectangular` (Lock Screen, **iOS 16+**) is only added to
    `supportedFamilies` by `quotelyFamilies()`, under
    `if #available(iOSApplicationExtension 16.0, *)`. On iOS 15 the widgets
    offer small and medium only.
  - `FamilyCard` checks `family == .accessoryRectangular` only inside the
    same `#available` check, and then shows `LockScreenCard` (eyebrow, the
    line in the serif, the footer; no background, the system tints it).
  - `containerBackground(for: .widget)` and `contentMarginsDisabled()` are
    **iOS 17+** and wrapped in `widgetBackground(_:)` /
    `contentMarginsDisabledIfAvailable()`; iOS 15/16 use `.background`.
  - The `#Preview` blocks are `@available(iOS 17.0, *)` and inside
    `#if DEBUG`. If this Xcode rejects `@available` on `#Preview`, delete the
    attribute lines or the whole `#if DEBUG` blocks; they are previews only.
- The Lock Screen widgets read the same App Group data as the Home Screen
  ones; there is no separate data path.
- iOS 18 tinted / clear Home Screen modes: the background is a
  `containerBackground`, so the system can remove it; the text stays legible
  in the system's tint. No extra code.

## 6b. Fonts

- The extension bundles its own copies: `ios/QuotelyWidget/Fonts/
  InstrumentSerif-Regular.ttf` (PostScript `InstrumentSerif-Regular`, the
  quote/line) and `IBMPlexMono-Medium.ttf` (PostScript `IBMPlexMono-Medium`,
  the eyebrow). Both are listed under `UIAppFonts` in
  `ios/QuotelyWidget/Info.plist` and must be in the target's **Copy Bundle
  Resources**. The footer uses the system font (11.5pt medium, 10pt on the
  Lock Screen).
- Fallbacks: serif -> New York (`QuoteFont.serif`), mono -> system font.
  If every widget shows the system font, the Copy Bundle Resources step was
  missed; print `UIFont.familyNames` in a provider to confirm.

## 6c. Previews

- Each widget file ends with `#Preview` blocks (Xcode 15+ canvas, iOS 17
  simulator runtime): small, medium and Lock Screen for every widget; From
  your saved also previews its empty state (the hint). Open a widget file,
  show the canvas (Editor -> Canvas), pick the QuotelyWidget scheme.
- The widget gallery uses `placeholder` / `getSnapshot`: each shows a sample
  (Mandela quote; Maya Angelou for From your saved; "I'm gonna make him an
  offer he can't refuse." for Scene of the Day) until the app has saved
  real data.

## 6d. Device test checklist

Run `flutter run --release` on a device (iOS 16 or later for the Lock
Screen; also one iOS 15 device or simulator if available). Before testing,
open the app, let Today load, and save at least two quotes (and unsave all
of them for the empty-state checks). Do every row in **light** and **dark**
(Settings -> Display & Brightness), and tick each cell.

| Check | Small | Medium | Lock Screen |
| --- | --- | --- | --- |
| **Quote of the Day**: eyebrow "QUOTE OF THE DAY" in IBM Plex Mono, today's quote in Instrument Serif, "— Author" | | | |
| QOTD: today's poster blurred under the wash (light: paper wash; dark: night wash); with no poster, plain paper `#F3EEE5` / night `#15120F` | | | n/a |
| QOTD: a long quote shrinks, then truncates with an ellipsis; never overflows | | | |
| QOTD: tap opens **Today** (cold start and from background) | | | |
| **From your saved**: eyebrow "FROM YOUR SAVED", one of your saved quotes, "— Author" | | | |
| Saved: background is the page with the day's glow (soft colour top-right and bottom-left), no poster | | | n/a |
| Saved: unsave everything -> the widget shows "Save a quote you love and it will live here." after the app goes to the background | | | |
| Saved: save a quote -> the widget updates after the app goes to the background | | | |
| Saved: the next day the quote changes **without opening the app** (or change the device date forward a day and wait / re-add the widget) | | | |
| Saved: works in Airplane mode (no network needed at all) | | | |
| Saved: tap opens the **Saved** tab | | | |
| **Scene of the Day**: eyebrow "SCENE · <TITLE>", the line in the serif, "— Character, Title" | | | |
| Scene: the title's poster blurred under the wash; if the scene has no poster, the app's fallback poster; otherwise the page with the glow | | | n/a |
| Scene: in Airplane mode, kill and reopen the app -> the widget still shows a scene, never blank | | | |
| Scene: tap opens **Today** | | | |
| All: VoiceOver (Settings -> Accessibility) reads the whole quote/line and the author/character, not a truncated version | | | |
| All: the gallery shows the sample text before the app has saved anything (fresh install) | | | |

Also check: You -> Home-screen widgets shows three previews and the steps
sheet names the chosen widget; Firebase DebugView (run with
`-FIRDebugEnabled`) shows `widget_opened` with `widget_kind` after a widget
tap, and `widget_placed` the next app start after adding a widget.

## 7. Xcode Cloud

- `ios/ci_scripts/ci_post_clone.sh` needs no change: the extension has no
  CocoaPods or SwiftPM dependencies of its own, and `flutter pub get` there
  already produces the home_widget package for Runner.
- Commit the `project.pbxproj` changes, the new scheme if Xcode created a
  shared one (`ios/Runner.xcodeproj/xcshareddata/xcschemes/QuotelyWidget.xcscheme`)
  and any `Package.resolved` update. Do not commit `xcuserdata`.
- The Xcode Cloud workflow builds the **Runner** scheme; the extension is
  built and embedded as its dependency. Do not switch the workflow to the
  QuotelyWidget scheme.
- **[HUMAN]** In App Store Connect -> Xcode Cloud -> the workflow, confirm the
  archive action signs both `com.pranta.quotely` and
  `com.pranta.quotely.QuotelyWidget`. With cloud-managed signing it needs the
  App IDs and App Group from step 1 to exist; a missing App Group shows up as
  an export/signing error in the "Archive - iOS" step, not as a compile error.
- After the first green build, check in TestFlight that the widget appears in
  the widget gallery and the build's version matches the app's.

## 8. Notes

- No widget ever fetches anything. Each shows what the app last saved and
  is refreshed when the app loads the day's quote/scene, when the saved
  quotes change, at app start and when it goes to the background.
  - Quote of the Day: if the app is not opened on a given day it keeps
    showing the last quote. Timeline `.never`; the app calls
    `reloadTimelines`.
  - From your saved: timeline of now + the next 7 midnights, `.atEnd`, so the
    quote changes daily without the app (picks for 30 days are saved).
  - Scene of the Day: keeps the last scene; the timeline still turns over at
    midnight (7 entries, `.atEnd`) only so the glow follows the day.
- Pre-iOS 17 uses `.background`, iOS 17+ uses `containerBackground(for: .widget)`
  and `contentMarginsDisabled()`; both are already in `QuotelyWidget.swift`.
- If `InstrumentSerif-Regular` cannot be loaded, the quote falls back to the
  system serif (New York); the eyebrow falls back to the system font.

## 9. Next Mac session: Minimal quote and Today, small (added 2026-11-17)

Two more widgets in the same extension, written on Windows and **not yet
compiled**. No portal, signing, App Group or Xcode Cloud change is needed:
same target, same bundle ID, same App Group, same fonts. Android has both
too (Glance, verified with a release build).

### What they are

- **Minimal quote** (`QuotelyMinimalWidget`, `MinimalQuoteWidget.swift`):
  today's quote in Instrument Serif and "— author" under it, the pair centred
  vertically. No poster, no glow, no eyebrow. The background is the plain
  page (paper `#F3EEE5` by day, night `#15120F` by night), set as the
  container background, so iOS 17+ removes it in StandBy and iOS 18 in the
  tinted and clear Home Screen styles. iOS has no transparent Home Screen
  widgets otherwise, so there is no transparency setting on iOS (Android has
  one). Text size: `WidgetTypeScale(..., hasEyebrow: false)`, the same
  estimate as the other widgets, so a short quote fills a large widget.
  Families: systemSmall, systemMedium, systemLarge; accessoryRectangular
  (quote and author, no eyebrow) from iOS 16. Timeline `.never`; the app
  reloads it with Quote of the Day.
- **Today, small** (`QuotelySquareWidget`, `SquareQuoteWidget.swift`): the
  Quotely mark (the serif's opening quote, U+201C, in ink) top left over the
  page with the day's glow, and at the foot either today's quote (when
  `qotd_short` is not empty, so 60 characters or fewer) or the eyebrow
  `qotd_eyebrow` ("TUE · NOV 17") over "Open today's quote". Families:
  systemSmall; accessoryCircular (the mark alone over
  `AccessoryWidgetBackground`) from iOS 16. Timeline: now plus the next 7
  midnights, `.atEnd`, so the glow follows the day.

### Files

| File | Change |
| --- | --- |
| `ios/QuotelyWidget/MinimalQuoteWidget.swift` | **New** |
| `ios/QuotelyWidget/SquareQuoteWidget.swift` | **New** |
| `ios/QuotelyWidget/QuotelyWidgetBundle.swift` | Lists `MinimalQuoteWidget()` and `SquareQuoteWidget()` after `SceneWidget()` |
| `ios/QuotelyWidget/QuotelyWidgetShared.swift` | `WidgetKindName.minimal` / `.square`, `LaunchURL.minimal` / `.square`, and `WidgetTypeScale`'s new `hasEyebrow:` parameter (default `true`, so the other widgets are unchanged) |
| `ios/Runner.xcodeproj/project.pbxproj` | The two new files are already added to the `QuotelyWidget` group and to the QuotelyWidget target's **Compile Sources** (hand-edited on Windows, IDs `A1B2C3D4E5F60718293A4B5C` to `…5F`) |

### Steps

1. `git pull`, `flutter pub get`, `open ios/Runner.xcworkspace`.
2. In the Project navigator, check that `MinimalQuoteWidget.swift` and
   `SquareQuoteWidget.swift` show under `QuotelyWidget` (not red). Select each
   and check File inspector -> Target Membership: **QuotelyWidget only**, not
   Runner.
   - If Xcode refuses to open the project ("damaged" / parse error), the
     hand edit is at fault: `git checkout ios/Runner.xcodeproj/project.pbxproj`
     from before this change, then add the two files by hand: right-click the
     `QuotelyWidget` group -> Add Files to "Runner"... -> select both ->
     "Create groups", Targets: **QuotelyWidget** only.
3. QuotelyWidget target -> Build Phases -> **Compile Sources** must list
   seven files: `QuotelyWidgetShared.swift`, `QuotelyWidget.swift`,
   `SavedQuoteWidget.swift`, `SceneWidget.swift`, `MinimalQuoteWidget.swift`,
   `SquareQuoteWidget.swift`, `QuotelyWidgetBundle.swift`. A missing one
   shows as "cannot find 'MinimalQuoteWidget' in scope" in the bundle.
4. Build the QuotelyWidget scheme for an iPhone simulator (Cmd-B). Likely
   compile fixes, if any:
   - `#Preview` with `@available`: as for the other widgets (section 6a),
     drop the attribute or the `#if DEBUG` block if this Xcode rejects it.
   - `AccessoryWidgetBackground` is iOS 16+; it is only used inside
     `SquareLockScreenMark`, which is `@available(iOSApplicationExtension 16.0, *)`.
5. Open both files with the canvas (Editor -> Canvas, QuotelyWidget scheme):
   previews for Minimal (small, medium, large, Lock Screen) and Today, small
   (a short quote and the long-quote fallback, and the Lock Screen circle).
6. Tune by eye, if needed:
   - the mark's size and position in `SquareCard` (`markFont = short * 0.42`,
     `markSpace = markFont * 0.55`, `.offset(y: -markFont * 0.12)`): its top
     should line up with the padding, like the Android widget, and the line
     at the foot must never collide with it;
   - the circle's mark (`SquareLockScreenMark`: size 44, `offset(y: 8)`),
     visually centred in the circle.
7. `flutter build ios --release --no-codesign` from the repo root must
   succeed with the extension embedded.
8. Run the app on a simulator, let Today load, then add both widgets
   (Edit -> Add Widget -> Quotely: the gallery now shows **five** widgets).
   Then the device checklist below on a phone with `flutter run --release`.

### Device checklist (light and dark, tick each cell)

| Check | Small | Medium | Large | Lock Screen |
| --- | --- | --- | --- | --- |
| **Minimal quote**: today's quote in Instrument Serif, "— Author" under it; no eyebrow, no poster, no glow | | | | |
| Minimal: plain paper by day, night by night; switches with the system appearance without opening the app | | | | n/a |
| Minimal: a short quote (about 5 words) fills the card; a long one (about 30 words) shrinks and never overflows or clips | | | | |
| Minimal: iOS 18 Home Screen "Tinted" and "Clear" styles, and StandBy (iOS 17): the background goes and the text stays legible | | | | n/a |
| Minimal: tap opens **Today** | | | | |
| **Today, small**: the mark top left over the page with the day's glow | | n/a | n/a | n/a |
| Square: a quote of 60 characters or fewer shows whole at the foot | | n/a | n/a | n/a |
| Square: a longer quote shows "TUE · NOV 17" (the quote's day) and "Open today's quote" | | n/a | n/a | n/a |
| Square: the Lock Screen circle shows the mark, centred | n/a | n/a | n/a | |
| Square: tap opens **Today** (both families) | | n/a | n/a | |
| Both: after a new day's quote loads in the app and the app goes to the background, both widgets update with Quote of the Day | | | | |
| Both: VoiceOver reads the whole quote and author ("Quotely: open today's quote" for the square's fallback and the circle) | | | | |
| Both: the gallery shows the sample (Benjamin Franklin) on a fresh install | | | | |

Also check: Settings (You) -> Home-screen widgets shows **five** previews
(they scroll sideways); choosing Minimal quote or Today, small and tapping
"Add widget" opens the steps sheet naming it; after adding one,
`widget_placed` with `widget_kind` `minimal` / `square` appears at the next
app start, and a tap logs `widget_opened` with the same kind.
