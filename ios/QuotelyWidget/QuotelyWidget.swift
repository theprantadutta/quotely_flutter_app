import SwiftUI
import UIKit
import WidgetKit

// The Quote of the Day home-screen widget.
//
// It only displays what the app saved through home_widget
// (lib/services/quote_widget_service.dart): the quote, its author, and the
// day's scene poster as a PNG that is already blurred to colour. The wash over
// the poster, the colours and the fonts are applied here, so the widget
// follows the system's light or dark mode.
//
// The app reloads this widget (WidgetCenter.reloadTimelines(ofKind:)) whenever
// it saves new data, so the timeline never schedules its own refresh.

/// Must match QuoteWidgetService.appGroupId and the App Groups capability of
/// both the Runner and QuotelyWidget targets.
private let appGroupId = "group.com.pranta.quotely"

/// Must match QuoteWidgetService.iOSKind.
private let widgetKind = "QuotelyWidget"

/// Opens Today. The path is the Today route (Routes.today), so Flutter's deep
/// linking lands there; the `homeWidget` query is how home_widget recognises
/// a widget launch and reports it to Dart.
private let launchURL = URL(string: "quotely://widget/home?homeWidget")!

/// Keys written by QuoteWidgetService.
private enum Key {
  static let text = "qotd_text"
  static let author = "qotd_author"
  static let poster = "qotd_poster"
}

/// PostScript names of the fonts bundled with the extension (UIAppFonts in
/// Info.plist). If a font fails to load, SwiftUI falls back to the system
/// font; the serif fallback is handled in `QuoteFont`.
private enum FontName {
  static let serif = "InstrumentSerif-Regular"
  static let mono = "IBMPlexMono-Medium"
}

// MARK: - Timeline

struct QuoteEntry: TimelineEntry {
  let date: Date
  let text: String?
  let author: String?
  let poster: UIImage?

  static let sample = QuoteEntry(
    date: Date(),
    text: "It always seems impossible until it\u{2019}s done.",
    author: "Nelson Mandela",
    poster: nil
  )
}

struct QuoteProvider: TimelineProvider {
  func placeholder(in context: Context) -> QuoteEntry {
    .sample
  }

  func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
    let entry = load()
    // The widget gallery shows a sample until the app has saved a quote.
    completion(context.isPreview && entry.text == nil ? .sample : entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
    completion(Timeline(entries: [load()], policy: .never))
  }

  private func load() -> QuoteEntry {
    let defaults = UserDefaults(suiteName: appGroupId)
    return QuoteEntry(
      date: Date(),
      text: defaults?.string(forKey: Key.text)?.nonBlank,
      author: defaults?.string(forKey: Key.author)?.nonBlank,
      poster: loadPoster(defaults)
    )
  }

  /// The saved poster, from the path home_widget stored, or failing that
  /// from its known place in the App Group container (the same file, should
  /// the stored absolute path ever differ between the app and the extension).
  private func loadPoster(_ defaults: UserDefaults?) -> UIImage? {
    guard let saved = defaults?.string(forKey: Key.poster), !saved.isEmpty else {
      return nil
    }
    var paths = [saved]
    if let container = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: appGroupId)
    {
      paths.append(container.appendingPathComponent("home_widget/qotd_poster.png").path)
    }
    for path in paths {
      if let image = UIImage(contentsOfFile: path) {
        return image
      }
    }
    return nil
  }
}

// MARK: - View

struct QuotelyWidgetView: View {
  let entry: QuoteEntry

  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetFamily) private var family

  private var isDark: Bool { scheme == .dark }
  private var page: Color { isDark ? Color(hex: 0x15120F) : Color(hex: 0xF3EEE5) }
  private var ink: Color { isDark ? Color(hex: 0xEEE7DB) : Color(hex: 0x1D1915) }
  private var mute: Color { isDark ? Color(hex: 0x9B9184) : Color(hex: 0x6F665B) }
  private var isSmall: Bool { family == .systemSmall }

  var body: some View {
    content
      .widgetURL(launchURL)
      .widgetBackground(background)
  }

  private var content: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text("QUOTE OF THE DAY")
        .font(.custom(FontName.mono, size: 9, relativeTo: .caption2))
        .tracking(1.5)
        .foregroundColor(mute)
        .lineLimit(1)

      Spacer(minLength: 6)

      Text(entry.text ?? "Open Quotely to bring today\u{2019}s quote here.")
        .font(QuoteFont.serif(size: isSmall ? 18 : 21))
        .foregroundColor(ink)
        .lineLimit(isSmall ? 7 : 5)
        // Long quotes shrink to fit before they are cut short.
        .minimumScaleFactor(0.55)
        .truncationMode(.tail)
        .layoutPriority(1)

      Spacer(minLength: 6)

      if let author = entry.author, entry.text != nil {
        Text("\u{2014} \(author)")
          .font(.system(size: 11.5, weight: .medium))
          .foregroundColor(mute)
          .lineLimit(1)
          .truncationMode(.tail)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(isSmall ? 14 : 16)
  }

  /// The page colour, or the poster under a page-colour wash (as the app's
  /// PosterWash: 70% light, 72% dark).
  private var background: some View {
    ZStack {
      page
      if let poster = entry.poster {
        Image(uiImage: poster)
          .resizable()
          .scaledToFill()
        page.opacity(isDark ? 0.72 : 0.70)
      }
    }
  }
}

// MARK: - Widget

struct QuotelyWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: widgetKind, provider: QuoteProvider()) { entry in
      QuotelyWidgetView(entry: entry)
    }
    .configurationDisplayName("Quote of the Day")
    .description("Today\u{2019}s quote on your home screen, over the day\u{2019}s poster.")
    .supportedFamilies([.systemSmall, .systemMedium])
    .contentMarginsDisabledIfAvailable()
  }
}

// MARK: - Helpers

private enum QuoteFont {
  /// Instrument Serif when it loaded, otherwise the system serif (New York).
  static func serif(size: CGFloat) -> Font {
    if UIFont(name: FontName.serif, size: size) != nil {
      return .custom(FontName.serif, size: size, relativeTo: .title3)
    }
    return .system(size: size, weight: .regular, design: .serif)
  }
}

extension View {
  /// iOS 17 requires widgets to declare their background this way (it is
  /// what lets the system remove it in StandBy and tinted modes); earlier
  /// versions take a plain background.
  @ViewBuilder
  fileprivate func widgetBackground<Background: View>(_ background: Background) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { background }
    } else {
      self.background(background)
    }
  }
}

extension WidgetConfiguration {
  /// The widget pads itself, the same on every iOS version; iOS 17 would
  /// otherwise add its own content margins on top.
  fileprivate func contentMarginsDisabledIfAvailable() -> some WidgetConfiguration {
    if #available(iOSApplicationExtension 17.0, *) {
      return self.contentMarginsDisabled()
    } else {
      return self
    }
  }
}

extension Color {
  fileprivate init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255
    )
  }
}

extension String {
  fileprivate var nonBlank: String? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }
}
