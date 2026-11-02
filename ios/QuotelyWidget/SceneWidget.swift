import SwiftUI
import UIKit
import WidgetKit

// The "Scene of the Day" widget: today's scene line, "SCENE · <TITLE>" above
// it and the character and title below, over the title's poster blurred and
// washed exactly as Quote of the Day's is.
//
// The app (lib/services/scene_widget_service.dart) saves the scene and picks
// the poster: the scene's own, else the app's fallback backdrop poster, else
// none, and then this draws the page with the day's glow. The app never
// clears a saved scene, so offline the widget keeps the last one. The
// timeline turns over at each midnight only so the glow follows the day; the
// app reloads it when it saves a new scene.
//
// Families: systemSmall and systemMedium, and accessoryRectangular on the Lock
// Screen from iOS 16. A tap opens Today.

/// Keys written by SceneWidgetService.
private enum SceneKey {
  static let eyebrow = "scene_eyebrow"
  static let text = "scene_text"
  static let character = "scene_character"
  static let title = "scene_title"
  static let poster = "scene_poster"
}

// MARK: - Timeline

struct SceneEntry: TimelineEntry {
  let date: Date
  let eyebrow: String
  let text: String?
  let character: String?
  let title: String?
  let poster: UIImage?
  let glow: GlowHue

  static let sample = SceneEntry(
    date: Date(),
    eyebrow: "SCENE \u{00B7} THE GODFATHER",
    text: "I\u{2019}m gonna make him an offer he can\u{2019}t refuse.",
    character: "Vito Corleone",
    title: "The Godfather",
    poster: nil,
    glow: .fallback
  )
}

struct SceneProvider: TimelineProvider {
  func placeholder(in context: Context) -> SceneEntry {
    .sample
  }

  func getSnapshot(in context: Context, completion: @escaping (SceneEntry) -> Void) {
    let entry = load(for: Date(), poster: loadSavedPoster(sharedDefaults, key: SceneKey.poster))
    // The widget gallery shows a sample until the app has saved a scene.
    completion(context.isPreview && entry.text == nil ? .sample : entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<SceneEntry>) -> Void) {
    // One decode of the poster for every entry.
    let poster = loadSavedPoster(sharedDefaults, key: SceneKey.poster)
    let entries = WidgetDay.dates(from: Date(), days: 7).map { load(for: $0, poster: poster) }
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  private func load(for date: Date, poster: UIImage?) -> SceneEntry {
    let defaults = sharedDefaults
    return SceneEntry(
      date: date,
      eyebrow: defaults?.string(forKey: SceneKey.eyebrow)?.nonBlank ?? "SCENE OF THE DAY",
      text: defaults?.string(forKey: SceneKey.text)?.nonBlank,
      character: defaults?.string(forKey: SceneKey.character)?.nonBlank,
      title: defaults?.string(forKey: SceneKey.title)?.nonBlank,
      poster: poster,
      glow: GlowHue.forDate(date, defaults)
    )
  }
}

// MARK: - View

struct SceneWidgetView: View {
  let entry: SceneEntry

  var body: some View {
    let text = entry.text ?? "Open Quotely to bring today\u{2019}s scene here."
    let footer: String? =
      entry.text == nil
      ? nil
      : [entry.character, entry.title].compactMap { $0 }.joined(separator: ", ").nonBlank
    FamilyCard(
      eyebrow: entry.eyebrow,
      text: text,
      footer: footer,
      accessibilityText: accessibility(text: text, footer: footer),
      poster: entry.poster,
      glow: entry.glow,
      url: LaunchURL.scene
    )
  }

  private func accessibility(text: String, footer: String?) -> String {
    guard entry.text != nil else { return text }
    if let character = entry.character, let title = entry.title {
      return "Scene of the day from \(title): \(text) \u{2014} \(character)"
    }
    return "Scene of the day: " + ([text] + [footer].compactMap { $0 }).joined(separator: " \u{2014} ")
  }
}

// MARK: - Widget

struct SceneWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: WidgetKindName.scene, provider: SceneProvider()) { entry in
      SceneWidgetView(entry: entry)
    }
    .configurationDisplayName("Scene of the Day")
    .description("Today\u{2019}s scene line over its title\u{2019}s poster, with who said it.")
    .supportedFamilies(quotelyFamilies())
    .contentMarginsDisabledIfAvailable()
  }
}

// MARK: - Previews (Xcode 15+, iOS 17 canvas)

#if DEBUG
  @available(iOS 17.0, *)
  #Preview("Scene of the Day, small", as: .systemSmall) {
    SceneWidget()
  } timeline: {
    SceneEntry.sample
  }

  @available(iOS 17.0, *)
  #Preview("Scene of the Day, medium", as: .systemMedium) {
    SceneWidget()
  } timeline: {
    SceneEntry.sample
  }

  @available(iOS 17.0, *)
  #Preview("Scene of the Day, Lock Screen", as: .accessoryRectangular) {
    SceneWidget()
  } timeline: {
    SceneEntry.sample
  }
#endif
