# iOS follow-up: Firebase 13 / flutter_inapp_purchase 10.7.3 plugin upgrade

Steps for a Claude Code session **on a Mac with Xcode**. Android was upgraded and
built on Windows; iOS could not be built there. Do these steps before the next
App Store build. Until they are done, Xcode Cloud will fail: its committed
`Package.resolved` still pins Firebase 12.18.0, but the plugins now need 13.1.1.

## What changed

| Package | Before (locked) | After | iOS effect |
|---|---|---|---|
| firebase_core | 4.14.0 | 5.1.0 | firebase-ios-sdk pinned **exactly** to `13.1.1` (it was 12.18.0) |
| firebase_analytics | 12.5.0 | 13.0.1 | FirebaseAnalytics / GoogleAppMeasurement 13.x |
| firebase_crashlytics | 5.3.0 | 6.0.1 | FirebaseCrashlytics 13.x |
| firebase_messaging | 16.6.0 | 17.0.1 | FirebaseMessaging 13.x, plus iOS fixes for UIScene apps (see below) |
| flutter_inapp_purchase | 10.6.1 | 10.7.3 | openiap (Swift package) `from: "3.6.1"`, which is already the pinned version. No change expected |

There are no Dart API changes to make. `flutter analyze` and `flutter test`
are clean on Windows.

Hard requirements of the Firebase Apple SDK 13:
- **Xcode 26.2 or newer.** The package will not resolve in older Xcode. It
  needs Swift tools 6.2.1.
- iOS deployment target 15.0. The project is already on 15.0, so nothing to
  change.
- Firebase 13 is **SPM only**, because CocoaPods distribution ended. This
  project already uses Swift Package Manager and has no `Podfile`. Do not add
  one. `ci_post_clone.sh` only runs `pod install` if a Podfile exists.

## How iOS dependencies are managed here

- The Flutter plugins come in through Swift Package Manager (the generated
  `FlutterGeneratedPluginSwiftPackage`). There is no Podfile.
- The pins are committed in **two** `Package.resolved` files:
  - `ios/Runner.xcworkspace/xcshareddata/swiftpm/Package.resolved`
  - `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

  They have already drifted apart: the workspace copy has app-check 11.3.0,
  GoogleUtilities 8.1.1 and so on, while the project copy has 11.3.2, 8.1.4 and
  so on. Xcode Cloud builds the **workspace**, so the workspace copy is the one
  that matters. Refresh both, and leave them identical.
- Xcode Cloud resolves packages with automatic resolution disabled. A pin that
  doesn't match the plugins' requirements fails with a resolution error, and a
  missing file fails with "a resolved file is required".
  `ios/ci_scripts/ci_post_clone.sh` deliberately keeps `Package.resolved`.

## Steps

1. Check out the branch with this change and make sure Flutter matches the
   Windows machine (3.47.x stable). Run `xcodebuild -version` and confirm
   Xcode is **26.2 or newer**.
2. Restore the git-ignored files, if they aren't already present:
   `ios/Runner/GoogleService-Info.plist`, `.env` and `lib/firebase_options.dart`.
3. Run these:
   ```sh
   flutter clean
   flutter pub get
   dart run build_runner build -d   # lib/generated/ is git-ignored
   ```
4. Re-resolve the Swift packages so both `Package.resolved` files move to
   Firebase 13.1.1. Run it against the workspace, since that is what Xcode
   Cloud builds:
   ```sh
   cd ios
   xcodebuild -resolvePackageDependencies -workspace Runner.xcworkspace -scheme Runner
   xcodebuild -resolvePackageDependencies -project Runner.xcodeproj -scheme Runner
   cd ..
   ```
   If a stale pin blocks resolution (for example "package 'firebase-ios-sdk'
   is required using an exact version 13.1.1 but resolved at 12.18.0"), delete
   the two `Package.resolved` files and run the commands again. Clearing
   `~/Library/Caches/org.swift.swiftpm` and DerivedData `SourcePackages` can
   also help.
5. Check the new pins:
   - `firebase-ios-sdk` and `googleappmeasurement` should be **13.1.1** (or
     whatever exact version `firebase_core`'s `Package.swift` declares).
   - `openiap` should still be **3.6.1** or a newer 3.x. It must **not** be 4.x.
   - The two files should be identical: `diff` them.
6. Build:
   ```sh
   flutter build ios --release --no-codesign
   ```
   Then open `ios/Runner.xcworkspace` in Xcode and run an Archive, to catch
   signing and Crashlytics dSYM upload-script problems that `--no-codesign`
   doesn't show.
7. Commit only the two `Package.resolved` files and anything Xcode legitimately
   changed in `project.pbxproj`. Use a message like
   `iOS: update Swift package pins (Firebase 13.1.1)`. Never commit
   `GoogleService-Info.plist`, `.env` or `firebase_options.dart`.

## On-device checks (a real iPhone with a sandbox Apple ID)

### In-app purchase (donations: be careful)

The two non-consumable products are `support_the_dev_1` and
`buy_me_a_coffee_1`, in `lib/screens/support_us_screen.dart`.

1. Open Settings, then Support Us. Both tiles should load with localized
   prices. "Products not found" or "Could not load support options" means a
   regression.
2. Buy one with a sandbox account. You should see the "Thank you for your
   generous support!" snackbar, and the donation tiles should disappear.
3. Kill and relaunch the app. Supporter state should persist, and no purchase
   should be replayed.
4. Delete and reinstall, then tap **Restore Purchases**. You should see "Your
   support has been restored". Apple Review requires this button.
5. Try buying again with the same account. You should see "You have already
   supported us", not an error.
6. Cancel the payment sheet. Nothing should be shown.
7. Optional: use an "Ask to Buy" or slow-payment sandbox case to check the
   pending path. You should see "Your payment is still processing" and the app
   should grant nothing.

### Notifications (firebase_messaging 17 changes UIScene handling)

The app uses UIScene (`FlutterSceneDelegate` in `Info.plist`), and messaging
17 changed exactly that area. It now registers for APNs after
`Firebase.initializeApp()`, returns NO from scene `willConnectToSession`, and
delivers the tap on a push that launched the app. Firebase SDK 13 also gives
scene delegates priority over app delegates for FCM deep-link routing.

Check each of these:
1. A debug run logs `Firebase FCM Token: ...`, so the APNs token arrived.
2. A topic push arrives while the app is in the foreground. It should show as
   a local notification, and be suppressed during quiet hours.
3. Tap a push while the app is in the background. It should navigate to its
   `routeName`.
4. Tap a push while the app is terminated (cold start). It should navigate to
   its `routeName`. This is the path messaging 17 fixed for scene apps, so
   watch for a double navigation.
5. Turning notification topics on and off in Settings still subscribes and
   unsubscribes.

### Crashlytics and Analytics

- Force a test crash in a debug or TestFlight build and check that it appears
  in the Crashlytics console with symbols, which means the dSYM upload worked.
- Check that screen_view and custom events reach DebugView. Launch with the
  `-FIRDebugEnabled` argument.

## What to watch in Xcode Cloud

- The workflow's **Xcode version must be 26.2 or newer**. Older images fail at
  package resolution because Firebase 13 needs Swift tools 6.2.1. Check
  Workflow, then Environment.
- `ci_post_clone.sh` clones Flutter **stable at head**. That build uses
  whatever stable is current, which may differ from the 3.47.x used here.
  Consider pinning the tag if builds start drifting.
- Resolution errors mean the committed workspace `Package.resolved` is stale.
  Re-run step 4 locally and commit. Do not delete `Package.resolved` in CI.
- "`<artifact>.zip` already exists": the existing SwiftPM cache clearing in
  `ci_post_clone.sh` handles this. Leave it in place.
- The Crashlytics run-script phase should still find the binary and upload
  dSYMs. firebase_crashlytics 6.0.0 skips the upload when a Debug build has no
  dSYM, which is expected and not an error.

## Not done here, deliberately

- **flutter_inapp_purchase 11.x** (11.2.0 is the latest) was **not** adopted.
  It moves to openiap-apple **4.x** and openiap-google **4.x**, and rewrites
  the connection and listener plumbing. It also doesn't fix Android built-in
  Kotlin: it still adds `src/store/kotlin` through `java.srcDirs`. Because of
  that, `android.builtInKotlin` stays `false` (see `android/gradle.properties`). If someone adopts it later, the iOS pin moves `openiap` to 4.x, and
  every IAP check above must be redone.
- **Migrating FCM `getToken()` to `register()` / `onRegistered`.** That API
  returns a Firebase Installation ID for direct-send messaging, not the FCM
  token. Quotely delivers through topics, so the deprecated call is kept, with
  an ignore comment.
