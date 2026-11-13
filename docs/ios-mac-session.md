# iOS work for the next Mac session

Start here. Version 3.3.0 (26) was built and tested on Android from Windows,
where iOS cannot be built. Everything below needs a Mac with **Xcode 26.2 or
newer** and a human for the Apple Developer portal steps. The details are in
the per-topic files in `docs/ios-mac-session/`; this file gives the order.

## Status (updated 2026-11-13)

| Step | Status |
| --- | --- |
| 1. Portal: App Group, widget App ID, profiles | **Done** |
| 2. Swift package pins | **Done** (Firebase 13.1.1, openiap 4.0.9) |
| 3. Widget target in Xcode | **Done** (commit `1f30fc6`) |
| 4. Xcode Cloud | **Not checked**: confirm the next cloud build is green |
| 5. Device tests | **Not done**: run them from TestFlight build 25 |
| 6. App Store | **Done**: 3.2.0 (25) approved and live |
| 7. 3.3.0 (26) | **Done**: Flutter 3.50 checked on iOS, submitted for review 2026-11-13, automatic release |

What was done on the Mac:

- **Portal.** Registered App Group `group.com.pranta.quotely` and enabled it
  on `com.pranta.quotely`. Registered `com.pranta.quotely.QuotelyWidget`
  ("Quotely Widget") with the same group. Regenerated the App Store profile
  "New Quotely App" so it carries the App Group, and created the App Store
  profile "Quotely Widget". Both use the "Pranta Dutta (Distribution)"
  certificate. Copies are in
  `~/Certificates & Documents/Apple Signing/` (`New_Quotely_App.mobileprovision`,
  `Quotely_Widget.mobileprovision`).
- **Packages.** Both `Package.resolved` files were re-resolved and are
  identical: firebase-ios-sdk 13.1.1, GoogleAppMeasurement 13.0.1,
  openiap 4.0.9.
- **Widget target.** The `QuotelyWidget` app-extension target was added to
  `project.pbxproj` with the `xcodeproj` Ruby gem, not the Xcode template, so
  no template files were created. It compiles the five Swift files and copies
  the two fonts. Its configurations use Runner's Flutter xcconfigs, so the
  version follows `pubspec.yaml`. Deployment target is 15.0. Debug signs
  automatically; Release and Profile sign manually with "Quotely Widget".
  "Embed Foundation Extensions" sits before "Run Script" and "Thin Binary".
- **Build.** `flutter build ipa --release` with an export-options plist
  (method `app-store-connect`, manual signing, the two profiles above)
  produced `build/ios/ipa/Quotely.ipa`. Checked: `PlugIns/QuotelyWidget.appex`
  is embedded, the app and extension are both 3.2.0 (25), both carry the
  App Group, and the extension bundles both fonts. Uploaded with Transporter.
- **App Store.** Version 3.2.0 created, with new What's New and Promotional
  Text (widgets, Ask, share cards, feedback and flags, calmer notifications,
  supporter thank-you, Settings gear, accessibility and iPad polish; this
  covers 3.1.x too, which never shipped on iOS). Build 25 attached and
  submitted for review.

Gotcha: the `sqlite3` package's build hook downloads a prebuilt dylib from
GitHub releases. When GitHub returns a 504 the build fails with "Hash of
downloaded file libsqlite3.arm64.ios.dylib is …, expected …". That is the
HTML error page being hashed, not a real mismatch; retry once GitHub serves
the file.

## Order of work

1. ✅ **Done.** **Portal (human): App Group and widget App ID.** See
   `ios-mac-session/widget.md`, "Apple Developer portal". Create the App Group
   `group.com.pranta.quotely` and enable it on `com.pranta.quotely`. Create
   `com.pranta.quotely.QuotelyWidget`. Regenerate the app's profiles and add
   one for the widget.
2. ✅ **Done.** **Dependencies: re-resolve Swift packages.** See `ios-mac-session/plugins.md`.
   The project uses SPM, not CocoaPods. Both committed `Package.resolved`
   files must be refreshed: the workspace one is what Xcode Cloud builds.
   - Firebase moved to the 13.x Apple SDK (pinned exactly to 13.1.1).
   - `flutter_inapp_purchase` is now **11.2.0**, which uses the **openiap 4.x**
     native libraries. `plugins.md` was written for 10.7.3 / openiap 3.6.1. The
     4.x pin is now expected, not a mistake. The Dart API didn't change
     (analyze and tests are clean).
3. ✅ **Done.** **Xcode: add the widget target.** Follow `ios-mac-session/widget.md`, "Xcode".
   Create the Widget Extension target `QuotelyWidget` and use the existing
   Swift files in `ios/QuotelyWidget/`: there are now **five**
   (`QuotelyWidgetShared.swift`, `QuotelyWidget.swift`,
   `SavedQuoteWidget.swift`, `SceneWidget.swift`, `QuotelyWidgetBundle.swift`)
   for **three widgets in one extension** (Quote of the Day, From your saved,
   Scene of the Day; kinds `QuotelyWidget`, `QuotelySavedWidget`,
   `QuotelySceneWidget`). All five go in the QuotelyWidget target's Compile
   Sources. Add the fonts, App Groups on both targets, and the build-phase
   order fix. Keep the deployment target at 15.0: the Lock Screen family
   (iOS 16) and the iOS 17 APIs are already behind `#available`. Then build
   and archive locally before pushing.
4. ⬜ **Not checked.** **Xcode Cloud.** Check the workflow uses Xcode 26.2+, and that the
   archive includes the widget extension.
5. ⬜ **Not done.** **Test on a device:**
   - **Donations.** These now use in-app purchase 11 and a new thank-you flow.
     In the sandbox, test: buy (expect the full-screen thank-you), relaunch
     (no second thank-you), delete and reinstall then Restore (expect the
     "welcome back" form), cancel, and pending. Then open Support as a
     supporter: you should see the letter with "Supporter since".
   - **Widgets.** Work through the "Device test checklist" in `widget.md`
     (section 6d): each of the three widgets in small, medium and on the Lock
     Screen, in light and dark. In short: Quote of the Day and Scene of the
     Day open Today, From your saved opens Saved; From your saved shows the
     "Save a quote you love" hint when nothing is saved and changes quote the
     next day without the app; Scene of the Day never goes blank offline.
     Check the in-app "Add widget" steps (You -> Home-screen widgets) match
     what iOS really shows, and fix the wording if not (`widget.md`,
     section 6 step 5).
   - **Share cards.** See `ios-mac-session/share.md`: the iPad popover anchor,
     image plus text arriving in WhatsApp and Messages, and the Save Image
     permission prompt.
   - **Notifications.** Firebase Messaging 17 changes how UIScene apps
     handle notifications. Tap a push from the background and from a
     terminated app; both should land on the right screen (`plugins.md`).
   - **Maintenance mode.** Turn it on in the admin dashboard, check the
     notice, "Check again" and "Read what you saved", then turn it off and
     bring the app back to the foreground.
   - **Ask.** Ask a question online (an answer from the server), then offline
     (the local search, with no error).
   - **Feedback, flags and the review prompt.** See
     `ios-mac-session/feedback.md`: a flag and feedback sent in Airplane Mode
     arrive once back online, and the `in_app_review` dialog (TestFlight
     never shows it; a dev build does).
6. ✅ **Done.** **App Store:** 3.2.0 (25) submitted for review on 2026-11-08 with new release notes (see Status above).
7. ✅ **Done.** **3.3.0 (26) on Flutter 3.50.** Checked on the Mac on
   2026-11-13: all 177 tests pass, and the analyzer shows only the old warnings.
   `flutter build ios --release` compiles with the widget embedded, and
   `.env` is in the iOS bundle. The Android ignore-assets problem doesn't
   affect iOS. Swift package pins are unchanged; the two `Package.resolved`
   files were made identical again (gtm-session-fetcher 5.3.0). Smoke-tested on the
   iPhone 17 simulator: onboarding, Today, share as image, Ask, save,
   Settings, the widget chooser, Scenes, and the App Group widget data.
   Fixed along the way: `DarwinInitializationSettings()` defaults to
   requesting permission, so iOS showed the notification prompt at every
   launch even after "Not now". It now requests nothing on initialize, and
   only `PushNotifications.requestPermissions()` asks. Submitted for review
   with new What's New text. Not tested: IAP, push and placed widgets on a
   physical device.

## Already done on Windows (no Mac needed)

- `NSPhotoLibraryAddUsageDescription` in `ios/Runner/Info.plist`, for the
  share sheet's Save Image.
- The App Group in `ios/Runner/Runner.entitlements` (this is why step 1 is
  needed first).
- All Dart code. Accessibility labels, the tablet layout, the poster fallback,
  Ask and Maintenance mode are shared Dart code with no iOS-specific setup.
