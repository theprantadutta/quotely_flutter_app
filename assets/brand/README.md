# Quotely brand assets

The identity is **Paper**: the opening quote mark (U+201C) of Instrument Serif,
the app's display face, in ink `#1D1915` on warm paper `#F3EEE5`, with a peach
glow top-right and a faint blue one bottom-left, the same light the in-app
backdrops use. Accent (notification tint) is terracotta `#A5492B`.

Every file here is **composed** by `tools/compose_brand_assets.py`, which only
decides scale, placement and ground. Never hand-edit an output; change the
script and re-run:

```bash
python tools/compose_brand_assets.py      # everything under assets/brand/
dart run flutter_launcher_icons           # Android + iOS launcher icons
dart run flutter_native_splash:create     # Android + iOS splash
```

Then `git diff ios/Runner.xcodeproj/project.pbxproj` must be empty.
`flutter_launcher_icons` 0.14.x rewrites any build-setting line containing
`ASSETCATALOG`, which can flip
`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` to `AppIcon`; if
it does, set it back.

The Android notification icons are not produced by either generator: copy
`android/drawable-*/ic_notification.png` into
`android/app/src/main/res/drawable-*/` after re-running the script.

## What ships

Only `app/` is bundled into the app (`pubspec.yaml`): `logo-512.png` (the
rounded icon, About and the notifications primer) and `avatar-256.png` (the
round icon, "Quotely" as a sender). Everything else is a build-time input,
baked into `android/` and `ios/` by the generators.

## The two scales

The mark is drawn at **42%** of the visible tile (`MARK_W`). Android's adaptive
layer is 108dp showing the middle 72dp, so there the same visual size is
42% x 72/108 = **28%** of the layer (`ADAPTIVE_W`), which also keeps it well
inside the 66dp safe circle. `adaptive_icon_foreground_inset` stays `0`.

## Files

| Folder / file | Used by | Notes |
|---|---|---|
| `master/quotely-icon-light-square-1024.png` | launcher `image_path` | Opaque (the App Store rejects alpha). |
| `master/quotely-icon-{light,dark}-1024.png` | reference | Rounded, with alpha. Dark is the same mark in cream on the warm ink ground. |
| `master/quotely-mark-{ink,cream}-1024.png` | reference | The bare mark, transparent. |
| `android/adaptive/ic_launcher_background.png` | adaptive background | The paper-and-glow ground as an image, so it matches iOS exactly. |
| `android/adaptive/ic_launcher_foreground.png` | adaptive foreground | Ink mark at 28% of the layer. |
| `android/adaptive/ic_launcher_monochrome.png` | Android 13+ themed icon | White, alpha defines the shape. |
| `android/drawable-*/ic_notification.png` | FCM + local notifications | White silhouette, 24dp. Copy into `res/` by hand. |
| `android/playstore-icon-512.png` | Play listing | Square, full bleed: Play rounds it. |
| `ios/AppIcon-1024-dark.png` | iOS 18 dark | Transparent, cream mark; iOS supplies the ground. |
| `ios/AppIcon-1024-tinted.png` | iOS 18 tinted | Transparent, white mark. |
| `splash/splash-background-1284x2778.png` | splash `background_image` | The icon's ground, portrait. Both appearances. |
| `splash/splash-mark-1024.png` | splash `image` | 4x asset: mark at 40% of 1024 lands at ~100dp. |
| `splash/android12-mark-1152.png` | splash `android_12.image` | Everything inside the centred 768px circle; Android crops, it does not scale. |
| `logo/` | store and press | Wordmark (Instrument Serif) and lockups. |

## The splash is one ground in both appearances

The launcher icon is fixed, so a dark splash would mean tapping a paper tile
and landing on black. The splash uses the icon's own paper ground in light and
dark mode; the app switches to the user's theme once it paints.
