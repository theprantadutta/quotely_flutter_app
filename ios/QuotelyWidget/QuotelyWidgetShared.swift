import SwiftUI
import UIKit
import WidgetKit

// What Quotely's widgets share: the App Group, the fonts, the colours, the
// saved poster and glow, the card layout for the Home Screen and the Lock
// Screen, and the availability shims for iOS 15 to 17.
//
// Every widget only displays what the app saved through home_widget
// (lib/services/home_widget_store.dart and the per-widget services next to
// it). None of them ever fetches anything.

/// Must match HomeWidgetStore.appGroupId and the App Groups capability of
/// both the Runner and QuotelyWidget targets.
let appGroupId = "group.com.pranta.quotely"

/// The WidgetKit kinds. Must match QuotelyWidgetKind.iOSKind in Dart.
enum WidgetKindName {
  static let qotd = "QuotelyWidget"
  static let saved = "QuotelySavedWidget"
  static let scene = "QuotelySceneWidget"
}

/// Where a tap opens the app. The path is a Flutter route (/home is Today,
/// /saved is Saved); the `homeWidget` query is how home_widget recognises a
/// widget launch and reports it to Dart, and `kind` says which widget it was
/// (for analytics).
enum LaunchURL {
  static let qotd = URL(string: "quotely://widget/home?homeWidget&kind=qotd")!
  static let saved = URL(string: "quotely://widget/saved?homeWidget&kind=saved")!
  static let scene = URL(string: "quotely://widget/home?homeWidget&kind=scene")!
}

/// PostScript names of the fonts bundled with the extension (UIAppFonts in
/// Info.plist). If a font fails to load, SwiftUI falls back to the system
/// font; the serif fallback is handled in `QuoteFont`.
enum FontName {
  static let serif = "InstrumentSerif-Regular"
  static let mono = "IBMPlexMono-Medium"
}

enum QuoteFont {
  /// Instrument Serif when it loaded, otherwise the system serif (New York).
  static func serif(size: CGFloat) -> Font {
    if UIFont(name: FontName.serif, size: size) != nil {
      return .custom(FontName.serif, size: size, relativeTo: .title3)
    }
    return .system(size: size, weight: .regular, design: .serif)
  }

  static func mono(size: CGFloat) -> Font {
    .custom(FontName.mono, size: size, relativeTo: .caption2)
  }
}

var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupId) }

/// A blurred poster the app saved: from the path home_widget stored under
/// [key], or failing that from its known place in the App Group container
/// (`home_widget/<key>.png`; the same file, should the stored absolute path
/// ever differ between the app and the extension).
func loadSavedPoster(_ defaults: UserDefaults?, key: String) -> UIImage? {
  guard let saved = defaults?.string(forKey: key), !saved.isEmpty else {
    return nil
  }
  var paths = [saved]
  if let container = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: appGroupId)
  {
    paths.append(container.appendingPathComponent("home_widget/\(key).png").path)
  }
  for path in paths {
    if let image = UIImage(contentsOfFile: path) {
      return image
    }
  }
  return nil
}

// MARK: - Days

enum WidgetDay {
  private static var calendar: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = .current
    return c
  }

  /// Calendar days from `start` (yyyy-MM-dd, a local date) to `date`'s local
  /// date, or nil if `start` can't be read.
  static func daysSince(_ start: String, to date: Date) -> Int? {
    let parts = start.split(separator: "-").compactMap { Int($0) }
    guard parts.count == 3 else { return nil }
    let cal = calendar
    guard
      let startDay = cal.date(
        from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    else { return nil }
    return cal.dateComponents(
      [.day], from: cal.startOfDay(for: startDay), to: cal.startOfDay(for: date)
    ).day
  }

  /// `date` and the next `count` local midnights after it: the entries of a
  /// timeline that turns over daily.
  static func dates(from date: Date, days count: Int) -> [Date] {
    let cal = calendar
    let today = cal.startOfDay(for: date)
    return [date]
      + (1...count).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
  }

  /// Index `i` wrapped into 0..<count.
  static func wrap(_ i: Int, _ count: Int) -> Int {
    ((i % count) + count) % count
  }
}

// MARK: - Colours and glow

/// The app's Spotlight tokens for the system theme.
struct Palette {
  let isDark: Bool
  init(_ scheme: ColorScheme) { isDark = scheme == .dark }

  var page: Color { isDark ? Color(hex: 0x15120F) : Color(hex: 0xF3EEE5) }
  var ink: Color { isDark ? Color(hex: 0xEEE7DB) : Color(hex: 0x1D1915) }
  var mute: Color { isDark ? Color(hex: 0x9B9184) : Color(hex: 0x6F665B) }
}

/// The day's glow hue, light and dark, as ARGB.
struct GlowHue {
  let light: UInt32
  let dark: UInt32

  /// The first glow (clay), for when the app hasn't saved any yet.
  static let fallback = GlowHue(light: 0xFFF2_A07E, dark: 0xFFC0_643F)

  /// The glow for `date`, from `glow_days`, which the app saves for the next
  /// 30 days (`{"start":"yyyy-MM-dd","light":[argb…],"dark":[argb…]}`),
  /// wrapping round past the end (the glow repeats every five days).
  static func forDate(_ date: Date, _ defaults: UserDefaults?) -> GlowHue {
    guard
      let raw = defaults?.string(forKey: "glow_days"),
      let data = raw.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let start = json["start"] as? String,
      let light = json["light"] as? [NSNumber],
      let dark = json["dark"] as? [NSNumber],
      let days = WidgetDay.daysSince(start, to: date)
    else { return .fallback }
    let count = min(light.count, dark.count)
    guard count > 0 else { return .fallback }
    let i = WidgetDay.wrap(days, count)
    return GlowHue(
      light: UInt32(truncatingIfNeeded: light[i].int64Value),
      dark: UInt32(truncatingIfNeeded: dark[i].int64Value))
  }
}

/// The page with the day's glow, as the app's Glow background paints it
/// (DayGlow in lib/components/thread/spotlight.dart): a glow from the
/// top-right corner (radius 1.6 x the shortest side, full strength) and one
/// from just past the bottom-left (1.4 x, 70%), each fading from
/// hue x strength x k through 45% of that at mid-radius to nothing; k is 0.5
/// on paper and 0.34 at night.
struct DayGlowView: View {
  let hue: GlowHue

  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let palette = Palette(scheme)
    let argb = palette.isDark ? hue.dark : hue.light
    let k = palette.isDark ? 0.34 : 0.5
    GeometryReader { geo in
      let shortest = min(geo.size.width, geo.size.height)
      ZStack {
        palette.page
        glow(argb, k: k, strength: 1.0, center: UnitPoint(x: 1, y: 0), radius: 1.6 * shortest)
        glow(
          argb, k: k, strength: 0.7, center: UnitPoint(x: -0.05, y: 1), radius: 1.4 * shortest)
      }
    }
  }

  private func glow(
    _ argb: UInt32, k: Double, strength: Double, center: UnitPoint, radius: CGFloat
  ) -> some View {
    let color = Color(hex: argb & 0xFFFFFF)
    return RadialGradient(
      gradient: Gradient(stops: [
        .init(color: color.opacity(strength * k), location: 0),
        .init(color: color.opacity(strength * k * 0.45), location: 0.5),
        .init(color: color.opacity(0), location: 1),
      ]),
      center: center,
      startRadius: 0,
      endRadius: max(1, radius)
    )
  }
}

/// The background of a Home Screen widget: the poster under the page-colour
/// wash (as the app's PosterWash: 70% light, 72% dark); without one, the page
/// with the day's glow when `glow` is set, else the plain page.
struct WidgetBackdrop: View {
  let poster: UIImage?
  let glow: GlowHue?

  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let palette = Palette(scheme)
    ZStack {
      palette.page
      if let poster {
        Image(uiImage: poster)
          .resizable()
          .scaledToFill()
        palette.page.opacity(palette.isDark ? 0.72 : 0.70)
      } else if let glow {
        DayGlowView(hue: glow)
      }
    }
  }
}

// MARK: - Cards

/// Eyebrow, body and footer: the Home Screen layout every widget uses.
struct WidgetCard: View {
  let eyebrow: String
  let text: String
  /// Drawn after "— ".
  let footer: String?
  /// What VoiceOver reads: everything, never truncated.
  let accessibilityText: String

  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetFamily) private var family

  private var isSmall: Bool { family == .systemSmall }

  var body: some View {
    let palette = Palette(scheme)
    VStack(alignment: .leading, spacing: 0) {
      Text(eyebrow)
        .font(QuoteFont.mono(size: 9))
        .tracking(1.5)
        .foregroundColor(palette.mute)
        .lineLimit(1)

      Spacer(minLength: 6)

      Text(text)
        .font(QuoteFont.serif(size: isSmall ? 18 : 21))
        .foregroundColor(palette.ink)
        .lineLimit(isSmall ? 7 : 5)
        // Long lines shrink to fit before they are cut short.
        .minimumScaleFactor(0.55)
        .truncationMode(.tail)
        .layoutPriority(1)

      Spacer(minLength: 6)

      if let footer, !footer.isEmpty {
        Text("\u{2014} \(footer)")
          .font(.system(size: 11.5, weight: .medium))
          .foregroundColor(palette.mute)
          .lineLimit(1)
          .truncationMode(.tail)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(isSmall ? 14 : 16)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(accessibilityText))
  }
}

/// The Lock Screen (accessoryRectangular, iOS 16+) layout: the eyebrow, the
/// line in the serif, and the footer, in the system's vibrant style. No
/// background: the Lock Screen provides it.
struct LockScreenCard: View {
  let eyebrow: String
  let text: String
  let footer: String?
  let accessibilityText: String

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(eyebrow)
        .font(QuoteFont.mono(size: 9))
        .tracking(1)
        .lineLimit(1)
        .opacity(0.8)
      Text(text)
        .font(QuoteFont.serif(size: 15))
        .lineLimit(footer == nil ? 3 : 2)
        .minimumScaleFactor(0.75)
        .truncationMode(.tail)
      if let footer, !footer.isEmpty {
        Text("\u{2014} \(footer)")
          .font(.system(size: 10, weight: .medium))
          .lineLimit(1)
          .opacity(0.8)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(accessibilityText))
  }
}

/// A widget's content for the family it is shown in: the Lock Screen card
/// for accessoryRectangular, otherwise the Home Screen card over `backdrop`.
struct FamilyCard: View {
  let eyebrow: String
  let text: String
  let footer: String?
  let accessibilityText: String
  let poster: UIImage?
  let glow: GlowHue?
  let url: URL

  @Environment(\.widgetFamily) private var family

  var body: some View {
    if isLockScreen {
      LockScreenCard(
        eyebrow: eyebrow, text: text, footer: footer, accessibilityText: accessibilityText
      )
      .widgetURL(url)
      .widgetBackground(Color.clear)
    } else {
      WidgetCard(
        eyebrow: eyebrow, text: text, footer: footer, accessibilityText: accessibilityText
      )
      .widgetURL(url)
      .widgetBackground(WidgetBackdrop(poster: poster, glow: glow))
    }
  }

  private var isLockScreen: Bool {
    if #available(iOSApplicationExtension 16.0, *) {
      return family == .accessoryRectangular
    }
    return false
  }
}

// MARK: - Shims

/// systemSmall and systemMedium everywhere, plus the Lock Screen's
/// accessoryRectangular from iOS 16.
func quotelyFamilies() -> [WidgetFamily] {
  if #available(iOSApplicationExtension 16.0, *) {
    return [.systemSmall, .systemMedium, .accessoryRectangular]
  }
  return [.systemSmall, .systemMedium]
}

extension View {
  /// iOS 17 requires widgets to declare their background this way (it is
  /// what lets the system remove it in StandBy and tinted modes); earlier
  /// versions take a plain background.
  @ViewBuilder
  func widgetBackground<Background: View>(_ background: Background) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { background }
    } else {
      self.background(background)
    }
  }
}

extension WidgetConfiguration {
  /// The widgets pad themselves, the same on every iOS version; iOS 17 would
  /// otherwise add its own content margins on top.
  func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
    if #available(iOSApplicationExtension 17.0, *) {
      return self.contentMarginsDisabled()
    } else {
      return self
    }
  }
}

extension Color {
  init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255
    )
  }
}

extension String {
  var nonBlank: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
