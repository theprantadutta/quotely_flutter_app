import SwiftUI
import UIKit
import WidgetKit

// The small square ("Today, small"): the Quotely mark (Instrument Serif's
// opening quote) over the page with the day's glow, the app icon's look, and
// a very short line under it:
// - today's quote when it is short enough to read whole in systemSmall (the
//   app decides, QuoteWidgetService.shortLine: at most 60 characters, saved
//   as `qotd_short`, empty otherwise);
// - otherwise the quote's day ("TUE · NOV 17", `qotd_eyebrow`) and "Open
//   today's quote".
//
// It reads the Quote of the Day data and is reloaded with it. The timeline
// still turns over at midnight (7 entries, .atEnd) so the glow follows the
// day, as Scene of the Day does.
//
// Families: systemSmall, and accessoryCircular on the Lock Screen from
// iOS 16 (the mark alone, a way into Today). A tap opens Today.

/// Keys written by QuoteWidgetService (and HomeWidgetStore for the glow).
private enum SquareKey {
  static let text = "qotd_text"
  static let author = "qotd_author"
  static let short = "qotd_short"
  static let eyebrow = "qotd_eyebrow"
}

private let squareMark = "\u{201C}"
private let openToday = "Open today\u{2019}s quote"

// MARK: - Timeline

struct SquareEntry: TimelineEntry {
  let date: Date
  /// Today's quote when it is short; nil shows `eyebrow` and "Open today's quote".
  let line: String?
  let author: String?
  let eyebrow: String?
  let glow: GlowHue

  static let sample = SquareEntry(
    date: Date(),
    line: "Well done is better than well said.",
    author: "Benjamin Franklin",
    eyebrow: "TUE \u{00B7} NOV 17",
    glow: .fallback
  )

  static let long = SquareEntry(
    date: Date(), line: nil, author: nil, eyebrow: "TUE \u{00B7} NOV 17", glow: .fallback)
}

struct SquareProvider: TimelineProvider {
  func placeholder(in context: Context) -> SquareEntry {
    .sample
  }

  func getSnapshot(in context: Context, completion: @escaping (SquareEntry) -> Void) {
    let entry = load(for: Date())
    let empty = sharedDefaults?.string(forKey: SquareKey.text)?.nonBlank == nil
    // The widget gallery shows a sample until the app has saved a quote.
    completion(context.isPreview && empty ? .sample : entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SquareEntry>) -> Void) {
    let entries = WidgetDay.dates(from: Date(), days: 7).map(load(for:))
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func load(for date: Date) -> SquareEntry {
    let defaults = sharedDefaults
    let hasQuote = defaults?.string(forKey: SquareKey.text)?.nonBlank != nil
    return SquareEntry(
      date: date,
      line: hasQuote ? defaults?.string(forKey: SquareKey.short)?.nonBlank : nil,
      author: defaults?.string(forKey: SquareKey.author)?.nonBlank,
      eyebrow: defaults?.string(forKey: SquareKey.eyebrow)?.nonBlank,
      glow: GlowHue.forDate(date, defaults)
    )
  }
}

// MARK: - Views

/// The mark at the top left, the words at the foot.
struct SquareCard: View {
  let line: String?
  let eyebrow: String?
  let accessibilityText: String

  @Environment(\.colorScheme) private var scheme

  var body: some View {
    GeometryReader { geo in
      card(geo.size)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(accessibilityText))
  }

  private func card(_ size: CGSize) -> some View {
    let palette = Palette(scheme)
    let short = min(size.width, size.height)
    let padding = min(max(short * 0.1, 12), 18)
    // The opening quote sits high in its line box: a font this size draws a
    // mark about a sixth of the widget tall, and only the top ~55% of the
    // line holds ink, so that is all the layout reserves for it.
    let markFont = short * 0.42
    let markSpace = markFont * 0.55
    let words = line ?? openToday
    let type = WidgetTypeScale(
      size: CGSize(width: size.width, height: max(1, size.height - markSpace)),
      text: words, hasFooter: false, small: true, hasEyebrow: line == nil)
    return VStack(alignment: .leading, spacing: 0) {
      Text(squareMark)
        .font(QuoteFont.serif(size: markFont))
        .foregroundColor(palette.ink)
        .lineLimit(1)
        .fixedSize()
        .offset(y: -markFont * 0.12)
        .frame(height: markSpace, alignment: .top)

      Spacer(minLength: 4)

      if line == nil, let eyebrow {
        Text(eyebrow)
          .font(QuoteFont.mono(size: min(max(short * 0.06, 8), 10)))
          .tracking(1.2)
          .foregroundColor(palette.mute)
          .lineLimit(1)
          .padding(.bottom, 3)
      }

      Text(words)
        .font(QuoteFont.serif(size: type.quote))
        .foregroundColor(palette.ink)
        .minimumScaleFactor(0.75)
        .truncationMode(.tail)
        .layoutPriority(1)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .padding(padding)
  }
}

/// The Lock Screen's circle: the mark alone, over the system's accessory
/// background.
@available(iOSApplicationExtension 16.0, *)
struct SquareLockScreenMark: View {
  var body: some View {
    ZStack {
      AccessoryWidgetBackground()
      Text(squareMark)
        .font(QuoteFont.serif(size: 44))
        .offset(y: 8)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text("Quotely: open today\u{2019}s quote"))
  }
}

struct SquareQuoteWidgetView: View {
  let entry: SquareEntry

  @Environment(\.widgetFamily) private var family

  var body: some View {
    if isLockScreen {
      lockScreen
    } else {
      SquareCard(line: entry.line, eyebrow: entry.eyebrow, accessibilityText: spoken)
        .widgetURL(LaunchURL.square)
        .widgetBackground(WidgetBackdrop(poster: nil, glow: entry.glow))
    }
  }

  @ViewBuilder
  private var lockScreen: some View {
    if #available(iOSApplicationExtension 16.0, *) {
      SquareLockScreenMark()
        .widgetURL(LaunchURL.square)
        .widgetBackground(Color.clear)
    }
  }

  private var isLockScreen: Bool {
    if #available(iOSApplicationExtension 16.0, *) {
      return family == .accessoryCircular
    }
    return false
  }

  private var spoken: String {
    guard let line = entry.line else { return "Quotely: open today\u{2019}s quote" }
    return entry.author.map { "Quote of the day: \(line) \u{2014} \($0)" }
      ?? "Quote of the day: \(line)"
  }
}

// MARK: - Widget

/// systemSmall, plus the Lock Screen's accessoryCircular from iOS 16.
private func squareFamilies() -> [WidgetFamily] {
  if #available(iOSApplicationExtension 16.0, *) {
    return [.systemSmall, .accessoryCircular]
  }
  return [.systemSmall]
}

struct SquareQuoteWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetKindName.square, provider: SquareProvider()) { entry in
      SquareQuoteWidgetView(entry: entry)
    }
    .configurationDisplayName("Today, small")
    .description("The Quotely mark and today\u{2019}s quote when it\u{2019}s short, a tap away when it\u{2019}s not.")
    .supportedFamilies(squareFamilies())
    .contentMarginsDisabledIfAvailable()
  }
}

// MARK: - Previews (Xcode 15+, iOS 17 canvas)

#if DEBUG
  @available(iOS 17.0, *)
  #Preview("Today, small", as: .systemSmall) {
    SquareQuoteWidget()
  } timeline: {
    SquareEntry.sample
    SquareEntry.long
  }

  @available(iOS 17.0, *)
  #Preview("Today, small, Lock Screen", as: .accessoryCircular) {
    SquareQuoteWidget()
  } timeline: {
    SquareEntry.sample
  }
#endif
