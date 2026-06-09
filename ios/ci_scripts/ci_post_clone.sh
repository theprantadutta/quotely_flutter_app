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

# This project uses Swift Package Manager for its plugins, so there is no
# Podfile. Only install and run CocoaPods if a Podfile is actually present
# (e.g. if a pod-only plugin is added in the future).
if [ -f ios/Podfile ]; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods # disable homebrew's automatic updates.
  cd ios && pod install # run `pod install` in the `ios` directory.
fi

exit 0
