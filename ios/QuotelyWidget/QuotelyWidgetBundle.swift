import SwiftUI
import WidgetKit

/// Entry point of the QuotelyWidget extension: every Quotely widget, in the
/// order the widget gallery lists them. Add new widgets here (and their Swift
/// files to the QuotelyWidget target).
@main
struct QuotelyWidgetBundle: WidgetBundle {
  var body: some Widget {
    QuotelyWidget()
    SavedQuoteWidget()
    SceneWidget()
  }
}
