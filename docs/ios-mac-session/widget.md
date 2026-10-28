# iOS: wire up the Quote of the Day widget (Mac session)

The iOS widget is written but not yet part of the Xcode project. Adding an
extension target means editing `ios/Runner.xcodeproj/project.pbxproj`, which is
only safe from Xcode, so it was left for a session on a Mac. This file is the
complete checklist for that session.

Steps marked **[HUMAN]** need a person signed in to the Apple Developer account
(developer.apple.com / App Store Connect). Everything else can be done by
Claude Code on the Mac, in Xcode or the terminal.

## What already exists (do not recreate)

| Path | What it is |
| --- | --- |
| `ios/QuotelyWidget/QuotelyWidget.swift` | Widget, `TimelineProvider`, entry and SwiftUI view |
| `ios/QuotelyWidget/QuotelyWidgetBundle.swift` | `@main` `WidgetBundle` |
| `ios/QuotelyWidget/Info.plist` | Extension Info.plist (`com.apple.widgetkit-extension`, `UIAppFonts`, Flutter build name/number) |
| `ios/QuotelyWidget/QuotelyWidget.entitlements` | App Group `group.com.pranta.quotely` |
| `ios/QuotelyWidget/Fonts/InstrumentSerif-Regular.ttf` | Quote font (PostScript name `InstrumentSerif-Regular`) |
| `ios/QuotelyWidget/Fonts/IBMPlexMono-Medium.ttf` | Eyebrow font (PostScript name `IBMPlexMono-Medium`) |
| `ios/Runner/Runner.entitlements` | Now also has the App Group `group.com.pranta.quotely` |
| `lib/services/quote_widget_service.dart` | Dart side: saves the data, calls `HomeWidget.updateWidget` |
| `lib/components/quote_widget_bridge.dart` | Dart side: when to save, and widget taps -> Today |

Contract between the app and the widget (all set by the Dart side already):

- `HomeWidget.setAppGroupId('group.com.pranta.quotely')` is called before any
  save on iOS.
- UserDefaults suite `group.com.pranta.quotely`, keys:
  `qotd_text`, `qotd_author`, `qotd_date` (yyyy-MM-dd), `qotd_poster` (absolute
  path of a PNG in the App Group container, `.../home_widget/qotd_poster.png`,
  already blurred), `qotd_poster_url`.
- Widget **kind**: `QuotelyWidget` (Dart calls
  `HomeWidget.updateWidget(iOSName: 'QuotelyWidget')`, which is
  `WidgetCenter.shared.reloadTimelines(ofKind: "QuotelyWidget")`).
- Tap URL: `quotely://widget/home?homeWidget`. home_widget recognises widget
  launches by the `homeWidget` query item; the `/home` path is the Today route.
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
   six files.
4. Add our files to the target if Xcode did not pick them up: right-click the
   `QuotelyWidget` group -> Add Files to "Runner"... -> select
   `QuotelyWidget.swift`, `QuotelyWidgetBundle.swift`, and the `Fonts` folder
   -> "Create groups", Targets: **QuotelyWidget only** (not Runner).
   Then check QuotelyWidget target -> Build Phases:
   - **Compile Sources**: `QuotelyWidget.swift`, `QuotelyWidgetBundle.swift`.
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
| iOS Deployment Target (General -> Minimum Deployments) | **15.0**, same as Runner. Flutter requires extension and app to match. |
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
   Long-press -> Edit -> Add Widget -> Quotely -> add **small** and **medium**.
   Check:
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
5. If a tap opens the app but does **not** land on Today, register the URL
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

- The widget never fetches anything. It shows what the app last saved and
  is refreshed when the app loads the day's quote or goes to the background,
  so if the app is not opened on a given day it keeps showing the last quote.
  The timeline uses `.never`; the app calls `reloadTimelines`.
- Pre-iOS 17 uses `.background`, iOS 17+ uses `containerBackground(for: .widget)`
  and `contentMarginsDisabled()`; both are already in `QuotelyWidget.swift`.
- If `InstrumentSerif-Regular` cannot be loaded, the quote falls back to the
  system serif (New York); the eyebrow falls back to the system font.
