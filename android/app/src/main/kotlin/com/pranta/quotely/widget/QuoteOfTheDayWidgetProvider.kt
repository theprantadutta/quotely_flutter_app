package com.pranta.quotely.widget

import android.content.Context
import android.content.SharedPreferences
import com.pranta.quotely.R

/**
 * The Quote of the Day home-screen widget's receiver. The class name is the
 * one Dart updates and pins (QuotelyWidgetKind.qotd), so it is kept.
 */
class QuoteOfTheDayWidgetProvider : ArtWidgetReceiver<QuoteOfTheDayWidget>() {
    override val glanceAppWidget = QuoteOfTheDayWidget()

    /** QuotelyWidgetKind.qotd.id, for analytics. */
    override val kind = "qotd"
}

/**
 * The Quote of the Day home-screen widget.
 *
 * It only displays what the app saved through home_widget (QuoteWidgetService
 * in Dart): the quote, its author, and the day's scene poster as a PNG that is
 * already blurred. [ArtWidget] crops the poster to the widget's shape, rounds
 * its corners and washes it with the page colour, and draws the text into a
 * bitmap of its own with the app's fonts (see [WidgetArt] for why). Without a
 * poster it is the plain page colour.
 *
 * A tap opens the app on Today. The URI's path is the Today route, so Flutter's
 * own deep linking lands there too; the `homeWidget` query marks it as a
 * widget launch for home_widget on iOS, and is kept the same here.
 */
class QuoteOfTheDayWidget : ArtWidget() {

    /** Opens Today (Routes.today). */
    override val launchUri = "quotely://widget/home?homeWidget&kind=qotd"

    override fun content(context: Context, data: SharedPreferences): Content {
        val text = data.getString(KEY_TEXT, null)?.trim().orEmpty()
        val author = data.getString(KEY_AUTHOR, null)?.trim().orEmpty()
        val eyebrow = context.getString(R.string.qotd_widget_eyebrow)
        val poster = WidgetArt.loadPoster(data, KEY_POSTER)
        if (text.isEmpty()) {
            val hint = context.getString(R.string.qotd_widget_empty)
            return Content(WidgetArt.Text(eyebrow, hint, null), hint, poster, glow = null)
        }
        val description = if (author.isEmpty()) {
            context.getString(R.string.qotd_widget_a11y, text)
        } else {
            context.getString(R.string.qotd_widget_a11y_author, text, author)
        }
        return Content(WidgetArt.Text(eyebrow, text, author), description, poster, glow = null)
    }

    companion object {
        // Keep in sync with QuoteWidgetService (lib/services/quote_widget_service.dart).
        private const val KEY_TEXT = "qotd_text"
        private const val KEY_AUTHOR = "qotd_author"
        private const val KEY_POSTER = "qotd_poster"
    }
}
