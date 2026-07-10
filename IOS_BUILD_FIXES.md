# iOS Build Fixes

Known iOS build gotchas for this project and how to fix them. Keep this file
updated when a fix has to be re-applied.

---

## 1. `flutter build ipa` fails: `Crashlytics/run: No such file or directory`

### Symptom

`flutter build ipa --release` (or an Xcode archive) fails near the end with:

```
Unhandled exception:
ProcessException: No such file or directory
  Command: .../DerivedData/Runner-xxxxx/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run --validate ...
  ...
  UploadCrashlyticsSymbols.run (package:flutterfire_cli/src/commands/upload_symbols.dart:...)
Command PhaseScriptExecution failed with a nonzero exit code
Encountered error while archiving for device.
```

### Cause

The FlutterFire **"upload-crashlytics-symbols"** build phase in
`ios/Runner.xcodeproj/project.pbxproj` only knows how to find the Crashlytics
`run` helper in **CocoaPods** or **DerivedData**. But `flutter build ipa`
resolves Swift Packages into **`build/ios/SourcePackages`**, not DerivedData,
so the script points at a file that doesn't exist and the archive fails.

> **This regenerates.** Running `flutterfire configure` rewrites
> `project.pbxproj` and **wipes this fix**, reverting to the broken stock
> script. If the error comes back after a `flutterfire configure`, that's why —
> just re-apply the fix below.

### Fix

Open `ios/Runner.xcodeproj/project.pbxproj`, find the build phase named
**`FlutterFire: "flutterfire upload-crashlytics-symbols"`** (search for
`upload-crashlytics-symbols`), and look at its `shellScript`.

**Replace the broken block** (stock version — note it only has Pods + DerivedData):

```bash
if [ -z "$PODS_ROOT" ] || [ ! -d "$PODS_ROOT/FirebaseCrashlytics" ]; then
  # Cannot use "BUILD_DIR%/Build/*" as per Firebase documentation, it points to "flutter-project/build/ios/*" path which doesn't have run script
  DERIVED_DATA_PATH=$(echo "$BUILD_ROOT" | sed -E 's|(.*DerivedData/[^/]+).*|\1|')
  PATH_TO_CRASHLYTICS_UPLOAD_SCRIPT="${DERIVED_DATA_PATH}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
else
  PATH_TO_CRASHLYTICS_UPLOAD_SCRIPT="$PODS_ROOT/FirebaseCrashlytics/run"
fi
```

**with the fixed block** (adds the `build/ios/SourcePackages` fallback):

```bash
if [ -n "$PODS_ROOT" ] && [ -d "$PODS_ROOT/FirebaseCrashlytics" ]; then
  PATH_TO_CRASHLYTICS_UPLOAD_SCRIPT="$PODS_ROOT/FirebaseCrashlytics/run"
else
  DERIVED_DATA_PATH=$(echo "$BUILD_ROOT" | sed -E 's|(.*DerivedData/[^/]+).*|\1|')
  PATH_TO_CRASHLYTICS_UPLOAD_SCRIPT="${DERIVED_DATA_PATH}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
  if [ ! -f "$PATH_TO_CRASHLYTICS_UPLOAD_SCRIPT" ]; then
    # flutter build (ipa/archive) resolves Swift packages into the Flutter
    # build dir, not DerivedData. Fall back to that location.
    PATH_TO_CRASHLYTICS_UPLOAD_SCRIPT="${SRCROOT}/../build/ios/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
  fi
fi
```

> ⚠️ In `project.pbxproj` the whole `shellScript` is a single **escaped,
> one-line** string (newlines are literal `\n`, quotes are `\"`). Edit it as
> escaped text on that one line — don't paste the pretty-printed version above
> verbatim. The commit that applied this fix is a good reference:
> `git log --oneline -- ios/Runner.xcodeproj/project.pbxproj` →
> *"Re-apply Crashlytics upload-symbols path fix for flutter build ipa"*.

### Verify

```bash
flutter build ipa --release
```

Should end with `✓ Built IPA to build/ios/ipa`.

---

## Notes

- This project is **Swift Package Manager only** (CocoaPods was deintegrated),
  which is why the DerivedData-only path assumption in the stock FlutterFire
  script doesn't hold.
- iOS deployment target is **15.0** (required by the Firebase SPM packages).
