import SwiftUI
import UIKit
import WidgetKit

// The Quote of the Day widget.
//
// It only displays what the app saved through home_widget
// (lib/services/quote_widget_service.dart): the quote, its author, and the
// day's scene poster as a PNG that is already blurred to colour. The wash over
// the poster, the colours and the fonts are applied here (QuotelyWidgetShared
// .swift), so the widget follows the system's light or dark mode.
//
// The app reloads this widget (WidgetCenter.reloadTimelines(ofKind:)) whenever
// it saves new data, so the timeline never schedules its own refresh.
//
// Families: systemSmall and systemMedium, and accessoryRectangular on the Lock
// Screen from iOS 16.

/// Keys written by QuoteWidgetService.
private enum QotdKey {
  static let text = "qotd_text"
  static let author = "qotd_author"
  static let poster = "qotd_poster"
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
    let defaults = sharedDefaults
    return QuoteEntry(
      date: Date(),
      text: defaults?.string(forKey: QotdKey.text)?.nonBlank,
      author: defaults?.string(forKey: QotdKey.author)?.nonBlank,
      poster: loadSavedPoster(defaults, key: QotdKey.poster)
    )
  }
}

// MARK: - View

struct QuotelyWidgetView: View {
  let entry: QuoteEntry

  var body: some View {
    let text = entry.text ?? "Open Quotely to bring today\u{2019}s quote here."
    let author = entry.text == nil ? nil : entry.author
    FamilyCard(
      eyebrow: "QUOTE OF THE DAY",
      text: text,
      footer: author,
      accessibilityText: author.map { "Quote of the day: \(text) \u{2014} \($0)" }
        ?? (entry.text == nil ? text : "Quote of the day: \(text)"),
      poster: entry.poster,
      // No poster: the plain page, as before.
      glow: nil,
      url: LaunchURL.qotd
    )
  }
}

// MARK: - Widget

struct QuotelyWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetKindName.qotd, provider: QuoteProvider()) { entry in
      QuotelyWidgetView(entry: entry)
    }
    .configurationDisplayName("Quote of the Day")
    .description("Today\u{2019}s quote on your home screen, over the day\u{2019}s poster.")
    .supportedFamilies(quotelyFamilies())
    .contentMarginsDisabledIfAvailable()
  }
}

// MARK: - Previews (Xcode 15+, iOS 17 canvas)

#if DEBUG
  @available(iOS 17.0, *)
  #Preview("Quote of the Day, small", as: .systemSmall) {
    QuotelyWidget()
  } timeline: {
    QuoteEntry.sample
  }

  @available(iOS 17.0, *)
  #Preview("Quote of the Day, medium", as: .systemMedium) {
    QuotelyWidget()
  } timeline: {
    QuoteEntry.sample
  }

  @available(iOS 17.0, *)
  #Preview("Quote of the Day, Lock Screen", as: .accessoryRectangular) {
    QuotelyWidget()
  } timeline: {
    QuoteEntry.sample
  }
#endif
