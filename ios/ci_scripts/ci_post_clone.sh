#!/bin/sh

# Fail this script if any subcommand fails.
set -e

# The default execution directory of this script is the ci_scripts directory.
cd $CI_PRIMARY_REPOSITORY_PATH # change working directory to the root of your cloned repo.

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
flutter precache --ios

# Install Flutter dependencies. For a Swift Package Manager project this
# also (re)generates the ephemeral FlutterGeneratedPluginSwiftPackage that
# Xcode resolves at build time.
flutter pub get

# Restore gitignored config files from base64-encoded Xcode Cloud secret
# environment variables. Generate a value locally with, e.g.:
#   base64 -i ios/Runner/GoogleService-Info.plist | pbcopy
# then add it to the workflow as a secret env var of the matching name.
if [ -n "$GOOGLE_SERVICE_INFO_PLIST_BASE64" ]; then
  echo "$GOOGLE_SERVICE_INFO_PLIST_BASE64" | base64 --decode > ios/Runner/GoogleService-Info.plist
  echo "Restored ios/Runner/GoogleService-Info.plist from environment."
fi

# .env is a bundled Flutter asset (see pubspec.yaml) and is gitignored, so it
# must be restored too or asset bundling fails. Provide ENV_FILE_BASE64 as a
# secret env var:  base64 -i .env | pbcopy
if [ -n "$ENV_FILE_BASE64" ]; then
  echo "$ENV_FILE_BASE64" | base64 --decode > .env
  echo "Restored .env from environment."
fi

# Clear cached Swift Package Manager binary artifacts to avoid
# "<artifact>.zip already exists in file system" errors when Xcode resolves
# Firebase's binary targets against Xcode Cloud's restored dependency cache.
# Clear every location SwiftPM may have cached artifacts, plus the resolved
# SourcePackages in DerivedData. The echo markers let us confirm in the
# post-clone log that this actually ran.
echo "==> Clearing SwiftPM caches to avoid Firebase binary-target conflicts"
rm -rf "$HOME/Library/Caches/org.swift.swiftpm"
rm -rf /Users/local/Library/Caches/org.swift.swiftpm
rm -rf "$HOME/Library/org.swift.swiftpm"
rm -rf "$CI_DERIVED_DATA_PATH/SourcePackages"
rm -rf /Volumes/workspace/DerivedData/SourcePackages
# NOTE: do NOT delete ios/.../Package.resolved here. Xcode Cloud resolves
# with automatic resolution disabled and REQUIRES the committed Package.resolved
# to be present; removing it fails with "a resolved file is required". We only
# clear the downloaded-artifact cache above so the pinned versions in
# Package.resolved are re-downloaded cleanly.
echo "==> SwiftPM artifact caches cleared (Package.resolved left intact)"

# This project uses Swift Package Manager for its plugins, so there is no
# Podfile. Only install and run CocoaPods if a Podfile is actually present
# (e.g. if a pod-only plugin is added in the future).
if [ -f ios/Podfile ]; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods # disable homebrew's automatic updates.
  cd ios && pod install # run `pod install` in the `ios` directory.
fi

exit 0
