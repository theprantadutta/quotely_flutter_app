# Quotely icon assets (option 1a · Speech quote)

Colors
- Violet (primary)      #6e62cd   oklch(0.56 0.16 285)
- Violet light (dark)   #a3a0f3   oklch(0.74 0.12 285)
- Ink                   #16151C
- Night (dark bg)       #0F0E14
- Paper (light bg)      #F4F3F8
- Font: Manrope ExtraBold (800), tracking -4.5%

Folders
- master/   1024 icons (rounded + square, light + dark) and the bare mark (violet / white / ink, transparent)
- ios/      AppIcon sizes (square, opaque — iOS applies the mask) + iOS 18 dark & tinted 1024
- android/  mipmap-* ic_launcher + ic_launcher_round, adaptive/ foreground, background, monochrome (themed icons),
            drawable-*/ic_notification (white silhouette for FCM small icon), playstore-icon-512
- web/      favicons, apple-touch-icon, PWA icons + maskable
- splash/   full-screen splashes (light/dark), splash logo, Android 12 icon (1152, inside 768 circle), branding wordmarks
- logo/     horizontal lockups + wordmarks

flutter_launcher_icons (pubspec.yaml)
  flutter_launcher_icons:
    android: true
    ios: true
    image_path: "assets/icon/master/quotely-icon-light-square-1024.png"
    adaptive_icon_background: "#6e62cd"
    adaptive_icon_foreground: "assets/icon/android/adaptive/ic_launcher_foreground.png"
    adaptive_icon_monochrome: "assets/icon/android/adaptive/ic_launcher_monochrome.png"
    remove_alpha_ios: true

flutter_native_splash.yaml
  flutter_native_splash:
    color: "#F4F3F8"
    image: assets/icon/splash/splash-logo-light-512.png
    branding: assets/icon/splash/branding-light-800x240.png
    color_dark: "#0F0E14"
    image_dark: assets/icon/splash/splash-logo-dark-512.png
    branding_dark: assets/icon/splash/branding-dark-800x240.png
    android_12:
      image: assets/icon/splash/android12-icon-light-1152.png
      icon_background_color: "#6e62cd"
      image_dark: assets/icon/splash/android12-icon-dark-1152.png
      icon_background_color_dark: "#a3a0f3"
      branding: assets/icon/splash/branding-light-800x240.png
      branding_dark: assets/icon/splash/branding-dark-800x240.png

Android notification icon: set com.google.firebase.messaging.default_notification_icon to @drawable/ic_notification
