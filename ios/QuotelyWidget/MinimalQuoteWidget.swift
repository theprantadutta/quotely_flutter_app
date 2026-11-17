import SwiftUI
import UIKit
import WidgetKit

// The Minimal quote widget: today's quote in Instrument Serif and
// "— author" under it. No poster, no glow, no eyebrow.
//
// It reads the Quote of the Day data (lib/services/quote_widget_service.dart),
// and the app reloads it with Quote of the Day whenever that data changes, so
// the timeline never schedules its own refresh.
//
// Background: the plain page, paper by day and night by night (Palette), set
// as the widget's container background. iOS has no transparent Home Screen
// widgets, but because it is a container background the system removes it
// where iOS wants no background (StandBy, and the tinted and clear Home
// Screen styles from iOS 18), which is the closest iOS gets.
//
// Families: systemSmall, systemMedium and systemLarge (the text fills each,
// sized by WidgetTypeScale), and accessoryRectangular on the Lock Screen from
// iOS 16. A tap opens Today.

/// Keys written by QuoteWidgetService.
private enum MinimalKey {
  static let text = "qotd_text"
  static let author = "qotd_author"
}

private let minimalHint = "Open Quotely to bring today\u{2019}s quote here."

// MARK: - Timeline

struct MinimalEntry: TimelineEntry {
  let date: Date
  let text: String?
  let author: String?

  static let sample = MinimalEntry(
    date: Date(),
    text: "Well done is better than well said.",
    author: "Benjamin Franklin"
  )
}

struct MinimalProvider: TimelineProvider {
  func placeholder(in context: Context) -> MinimalEntry {
    .sample
  }

  func getSnapshot(in context: Context, completion: @escaping (MinimalEntry) -> Void) {
    let entry = load()
    // The widget gallery shows a sample until the app has saved a quote.
    completion(context.isPreview && entry.text == nil ? .sample : entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<MinimalEntry>) -> Void) {
    completion(Timeline(entries: [load()], policy: .never))
  }

  private func load() -> MinimalEntry {
    let defaults = sharedDefaults
    return MinimalEntry(
      date: Date(),
      text: defaults?.string(forKey: MinimalKey.text)?.nonBlank,
      author: defaults?.string(forKey: MinimalKey.author)?.nonBlank
    )
  }
}

// MARK: - Views

/// The Home Screen layout: the quote, then the author, the pair centred
/// vertically and as large as the frame allows.
struct MinimalCard: View {
  let text: String
  let author: String?
  let accessibilityText: String

  @Environment(\.colorScheme) private var scheme
  @Environment(\.widgetFamily) private var family

  var body: some View {
    GeometryReader { geo in
      card(WidgetTypeScale(
        size: geo.size, text: text, hasFooter: author != nil,
        small: family == .systemSmall, hasEyebrow: false))
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(accessibilityText))
  }

  private func card(_ type: WidgetTypeScale) -> some View {
    let palette = Palette(scheme)
    return VStack(alignment: .leading, spacing: type.footer * 0.6) {
      Text(text)
        .font(QuoteFont.serif(size: type.quote))
        .foregroundColor(palette.ink)
        // Sized for the frame already; this only trims an underestimate.
        .minimumScaleFactor(0.75)
        .truncationMode(.tail)
        .layoutPriority(1)

      if let author {
        Text("\u{2014} \(author)")
          .font(.system(size: type.footer, weight: .medium))
          .foregroundColor(palette.mute)
          .lineLimit(1)
          .truncationMode(.tail)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(type.padding)
  }
}

/// The Lock Screen layout: the quote in the serif and the author, in the
/// system's vibrant style. No background: the Lock Screen provides it.
struct MinimalLockScreenCard: View {
  let text: String
  let author: String?
  let accessibilityText: String

  var body: some View {
    VStack(alignment: .leading, spacing: 1) {
      Text(text)
        .font(QuoteFont.serif(size: 15))
        .lineLimit(author == nil ? 3 : 2)
        .minimumScaleFactor(0.75)
        .truncationMode(.tail)
      if let author {
        Text("\u{2014} \(author)")
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

struct MinimalQuoteWidgetView: View {
  let entry: MinimalEntry

  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme

  var body: some View {
    let text = entry.text ?? minimalHint
    let author = entry.text == nil ? nil : entry.author
    let spoken =
      entry.text == nil
      ? text
      : author.map { "Quote of the day: \(text) \u{2014} \($0)" } ?? "Quote of the day: \(text)"
    if isLockScreen {
      MinimalLockScreenCard(text: text, author: author, accessibilityText: spoken)
        .widgetURL(LaunchURL.minimal)
        .widgetBackground(Color.clear)
    } else {
      MinimalCard(text: text, author: author, accessibilityText: spoken)
        .widgetURL(LaunchURL.minimal)
        .widgetBackground(Palette(scheme).page)
    }
  }

  private var isLockScreen: Bool {
    if #available(iOSApplicationExtension 16.0, *) {
      return family == .accessoryRectangular
    }
    return false
  }
}

// MARK: - Widget

/// systemSmall, systemMedium and systemLarge, plus the Lock Screen's
/// accessoryRectangular from iOS 16.
private func minimalFamilies() -> [WidgetFamily] {
  if #available(iOSApplicationExtension 16.0, *) {
    return [.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular]
  }
  return [.systemSmall, .systemMedium, .systemLarge]
}

struct MinimalQuoteWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetKindName.minimal, provider: MinimalProvider()) { entry in
      MinimalQuoteWidgetView(entry: entry)
    }
    .configurationDisplayName("Minimal quote")
    .description("Just today\u{2019}s quote and who said it.")
    .supportedFamilies(minimalFamilies())
    .contentMarginsDisabledIfAvailable()
  }
}

// MARK: - Previews (Xcode 15+, iOS 17 canvas)

#if DEBUG
  @available(iOS 17.0, *)
  #Preview("Minimal quote, small", as: .systemSmall) {
    MinimalQuoteWidget()
  } timeline: {
    MinimalEntry.sample
  }

  @available(iOS 17.0, *)
  #Preview("Minimal quote, medium", as: .systemMedium) {
    MinimalQuoteWidget()
  } timeline: {
    MinimalEntry.sample
  }

  @available(iOS 17.0, *)
  #Preview("Minimal quote, large", as: .systemLarge) {
    MinimalQuoteWidget()
  } timeline: {
    MinimalEntry.sample
  }

  @available(iOS 17.0, *)
  #Preview("Minimal quote, Lock Screen", as: .accessoryRectangular) {
    MinimalQuoteWidget()
  } timeline: {
    MinimalEntry.sample
  }
#endif
