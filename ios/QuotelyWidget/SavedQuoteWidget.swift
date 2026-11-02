import SwiftUI
import UIKit
import WidgetKit

// The "From your saved" widget: one of the person's own saved quotes, a
// different one each day, over the page with the day's glow. Entirely
// offline.
//
// The app (lib/services/saved_widget_service.dart) saves the picks for the
// next 30 days, so the quote turns over at midnight without the app: the
// timeline has one entry for now and one for each of the next 7 midnights,
// each indexing its own day into the picks (wrapping round if the app hasn't
// run for longer), and asks for a new timeline when they run out. The app
// also reloads it whenever the saved quotes change.
//
// Families: systemSmall and systemMedium, and accessoryRectangular on the Lock
// Screen from iOS 16. A tap opens the Saved tab.

/// Keys written by SavedWidgetService (and HomeWidgetStore for the glow).
private enum SavedKey {
  /// `{"start":"yyyy-MM-dd","quotes":[{"t":text,"a":author}…]}`
  static let days = "saved_days"
  /// 0: nothing saved yet, show the hint.
  static let count = "saved_count"
}

private let savedHint = "Save a quote you love and it will live here."

// MARK: - Timeline

struct SavedEntry: TimelineEntry {
  let date: Date
  let text: String?
  let author: String?
  let glow: GlowHue

  static let sample = SavedEntry(
    date: Date(),
    text: "Nothing will work unless you do.",
    author: "Maya Angelou",
    glow: .fallback
  )

  static let empty = SavedEntry(date: Date(), text: nil, author: nil, glow: .fallback)
}

struct SavedProvider: TimelineProvider {
  func placeholder(in context: Context) -> SavedEntry {
    .sample
  }

  func getSnapshot(in context: Context, completion: @escaping (SavedEntry) -> Void) {
    let entry = load(for: Date())
    // The widget gallery shows a sample until something is saved.
    completion(context.isPreview && entry.text == nil ? .sample : entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SavedEntry>) -> Void) {
    let entries = WidgetDay.dates(from: Date(), days: 7).map(load(for:))
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func load(for date: Date) -> SavedEntry {
    let defaults = sharedDefaults
    let glow = GlowHue.forDate(date, defaults)
    guard
      (defaults?.integer(forKey: SavedKey.count) ?? 0) > 0,
      let raw = defaults?.string(forKey: SavedKey.days),
      let data = raw.data(using: .utf8),
      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      let start = json["start"] as? String,
      let quotes = json["quotes"] as? [[String: Any]],
      !quotes.isEmpty,
      let days = WidgetDay.daysSince(start, to: date)
    else {
      return SavedEntry(date: date, text: nil, author: nil, glow: glow)
    }
    let pick = quotes[WidgetDay.wrap(days, quotes.count)]
    return SavedEntry(
      date: date,
      text: (pick["t"] as? String)?.nonBlank,
      author: (pick["a"] as? String)?.nonBlank,
      glow: glow
    )
  }
}

// MARK: - View

struct SavedQuoteWidgetView: View {
  let entry: SavedEntry

  var body: some View {
    let text = entry.text ?? savedHint
    let author = entry.text == nil ? nil : entry.author
    FamilyCard(
      eyebrow: "FROM YOUR SAVED",
      text: text,
      footer: author,
      accessibilityText: entry.text == nil
        ? savedHint
        : author.map { "From your saved: \(text) \u{2014} \($0)" } ?? "From your saved: \(text)",
      poster: nil,
      glow: entry.glow,
      url: LaunchURL.saved
    )
  }
}

// MARK: - Widget

struct SavedQuoteWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetKindName.saved, provider: SavedProvider()) { entry in
      SavedQuoteWidgetView(entry: entry)
    }
    .configurationDisplayName("From your saved")
    .description("One of your saved quotes, a different one each day. Works offline.")
    .supportedFamilies(quotelyFamilies())
    .contentMarginsDisabledIfAvailable()
  }
}

// MARK: - Previews (Xcode 15+, iOS 17 canvas)

#if DEBUG
  @available(iOS 17.0, *)
  #Preview("From your saved, small", as: .systemSmall) {
    SavedQuoteWidget()
  } timeline: {
    SavedEntry.sample
    SavedEntry.empty
  }

  @available(iOS 17.0, *)
  #Preview("From your saved, medium", as: .systemMedium) {
    SavedQuoteWidget()
  } timeline: {
    SavedEntry.sample
    SavedEntry.empty
  }

  @available(iOS 17.0, *)
  #Preview("From your saved, Lock Screen", as: .accessoryRectangular) {
    SavedQuoteWidget()
  } timeline: {
    SavedEntry.sample
  }
#endif
