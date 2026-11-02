# iOS work for the next Mac session

Start here. Version 3.2.0 (25) was built and tested on Android from Windows,
where iOS cannot be built. Everything below needs a Mac with **Xcode 26.2 or
newer** and a human for the Apple Developer portal steps. The details are in
the per-topic files in `docs/ios-mac-session/`; this file gives the order.

**Until steps 1 to 3 are done, Xcode Cloud builds will fail.** The Firebase
pins are stale, and the App Group in `Runner.entitlements` isn't in the
signing profile yet. Don't ship an iOS build from master before then.

## Order of work

1. **Portal (human): App Group and widget App ID.** See
   `ios-mac-session/widget.md`, "Apple Developer portal". Create the App Group
   `group.com.pranta.quotely` and enable it on `com.pranta.quotely`. Create
   `com.pranta.quotely.QuotelyWidget`. Regenerate the app's profiles and add
   one for the widget.
2. **Dependencies: re-resolve Swift packages.** See `ios-mac-session/plugins.md`.
   The project uses SPM, not CocoaPods. Both committed `Package.resolved`
   files must be refreshed: the workspace one is what Xcode Cloud builds.
   - Firebase moved to the 13.x Apple SDK (pinned exactly to 13.1.1).
   - `flutter_inapp_purchase` is now **11.2.0**, which uses the **openiap 4.x**
     native libraries. `plugins.md` was written for 10.7.3 / openiap 3.6.1. The
     4.x pin is now expected, not a mistake. The Dart API didn't change
     (analyze and tests are clean).
3. **Xcode: add the widget target.** Follow `ios-mac-session/widget.md`, "Xcode".
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
4. **Xcode Cloud.** Check the workflow uses Xcode 26.2+, and that the
   archive includes the widget extension.
5. **Test on a device:**
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
6. **App Store:** submit 3.2.0 (25) with the release notes used for Play.

## Already done on Windows (no Mac needed)

- `NSPhotoLibraryAddUsageDescription` in `ios/Runner/Info.plist`, for the
  share sheet's Save Image.
- The App Group in `ios/Runner/Runner.entitlements` (this is why step 1 is
  needed first).
- All Dart code. Accessibility labels, the tablet layout, the poster fallback,
  Ask and Maintenance mode are shared Dart code with no iOS-specific setup.
