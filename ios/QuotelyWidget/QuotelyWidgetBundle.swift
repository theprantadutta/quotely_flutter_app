import SwiftUI
import WidgetKit

/// Entry point of the QuotelyWidget extension. One widget today; add more
/// here if Quotely grows others (e.g. Fact of the Day).
@main
struct QuotelyWidgetBundle: WidgetBundle {
  var body: some Widget {
    QuotelyWidget()
  }
}
