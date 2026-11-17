package com.pranta.quotely.widget

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.util.SizeF
import com.pranta.quotely.R

/**
 * The small square home-screen widget's receiver ("Today, small"). Dart
 * updates and pins it by this class name (QuotelyWidgetKind.square).
 */
class SquareQuoteWidgetProvider : ArtWidgetReceiver<SquareQuoteWidget>() {
    override val glanceAppWidget = SquareQuoteWidget()

    /** QuotelyWidgetKind.square.id, for analytics. */
    override val kind = "square"
}

/**
 * The small square: the Quotely mark over the page with the day's glow (the
 * app icon's look), and a very short line under it:
 * - today's quote, when it is short enough to read whole at 2x2 (the app
 *   decides: QuoteWidgetService.shortLine, at most 60 characters);
 * - otherwise the quote's day ("TUE · NOV 17") and "Open today's quote".
 * At 1x1 the mark alone, as a way into Today.
 *
 * It reads the Quote of the Day data, so it changes when that does. The
 * page, glow and ink follow day and night with the app closed, as the other
 * widgets do. A tap opens Today.
 */
class SquareQuoteWidget : ArtWidget() {

    override val launchUri = "quotely://widget/home?homeWidget&kind=square"

    override fun content(context: Context, data: SharedPreferences): Content {
        val glow = WidgetArt.glowToday(data)
        val text = data.getString(KEY_TEXT, null)?.trim().orEmpty()
        val short = data.getString(KEY_SHORT, null)?.trim().orEmpty()
        if (text.isNotEmpty() && short.isNotEmpty()) {
            val author = data.getString(KEY_AUTHOR, null)?.trim().orEmpty()
            val description = if (author.isEmpty()) {
                context.getString(R.string.qotd_widget_a11y, short)
            } else {
                context.getString(R.string.qotd_widget_a11y_author, short, author)
            }
            return Content(WidgetArt.Text("", short, null), description, null, glow)
        }
        val eyebrow = data.getString(KEY_EYEBROW, null)?.trim().orEmpty()
        val open = context.getString(R.string.square_widget_open)
        return Content(
                WidgetArt.Text(eyebrow, open, null),
                context.getString(R.string.square_widget_a11y_open),
                null,
                glow,
        )
    }

    override fun textBitmap(context: Context, content: Content, sizeDp: SizeF, scale: Float): Bitmap =
            WidgetArt.squareBitmap(
                    context, content.text.eyebrow.ifEmpty { null }, content.text.body, sizeDp, scale)

    companion object {
        // Keep in sync with QuoteWidgetService (lib/services/quote_widget_service.dart).
        private const val KEY_TEXT = "qotd_text"
        private const val KEY_AUTHOR = "qotd_author"
        private const val KEY_SHORT = "qotd_short"
        private const val KEY_EYEBROW = "qotd_eyebrow"
    }
}
