package com.pranta.quotely.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.util.SizeF
import com.pranta.quotely.R
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * The Minimal quote home-screen widget's receiver. Dart updates and pins it
 * by this class name (QuotelyWidgetKind.minimal).
 *
 * Each placed widget can be switched between the page and a transparent
 * background ([MinimalWidgetConfigureActivity]); that choice is kept per
 * widget id and forgotten here when the widget is removed.
 */
class MinimalQuoteWidgetProvider : ArtWidgetReceiver<MinimalQuoteWidget>() {
    override val glanceAppWidget = MinimalQuoteWidget()

    /** QuotelyWidgetKind.minimal.id, for analytics. */
    override val kind = "minimal"

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        try {
            val editor = HomeWidgetPlugin.getData(context).edit()
            appWidgetIds.forEach { editor.remove(MinimalQuoteWidget.clearKey(it)) }
            editor.apply()
        } catch (e: Exception) {
            // A leftover flag for a removed id is harmless.
        }
    }
}

/**
 * The Minimal quote home-screen widget: today's quote in Instrument Serif and
 * "— author" under it. No poster, no glow, no eyebrow.
 *
 * It reads the Quote of the Day data (QuoteWidgetService in Dart), so it
 * changes when that does. Resizable from 2x1 to 4x3; the quote is fitted to
 * the space exactly as the other widgets fit theirs ([WidgetArt.minimalBitmap]).
 *
 * Background, per widget:
 * - the page (the default): paper by day, night by night, with the ink
 *   tinted to match. Day/night is resolved by the launcher, so it switches
 *   with the app closed.
 * - transparent: no page, and the text in parchment with a soft dark shadow,
 *   like the launcher's own icon labels. A widget can't learn the
 *   wallpaper's brightness with the app closed (and the system theme says
 *   nothing about it), so the text doesn't guess: light text with a shadow
 *   reads on both light and dark wallpapers.
 *
 * A tap opens Today.
 */
class MinimalQuoteWidget : ArtWidget() {

    override val launchUri = "quotely://widget/home?homeWidget&kind=minimal"

    override fun content(context: Context, data: SharedPreferences): Content =
            content(context, data, AppWidgetManager.INVALID_APPWIDGET_ID)

    override fun content(context: Context, data: SharedPreferences, appWidgetId: Int): Content {
        val transparent = appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID &&
                data.getBoolean(clearKey(appWidgetId), false)
        val text = data.getString(KEY_TEXT, null)?.trim().orEmpty()
        val author = data.getString(KEY_AUTHOR, null)?.trim().orEmpty()
        if (text.isEmpty()) {
            val hint = context.getString(R.string.qotd_widget_empty)
            return Content(WidgetArt.Text("", hint, null), hint, null, null, transparent)
        }
        val description = if (author.isEmpty()) {
            context.getString(R.string.qotd_widget_a11y, text)
        } else {
            context.getString(R.string.qotd_widget_a11y_author, text, author)
        }
        return Content(WidgetArt.Text("", text, author.ifEmpty { null }), description, null, null, transparent)
    }

    override fun textBitmap(context: Context, content: Content, sizeDp: SizeF, scale: Float): Bitmap =
            WidgetArt.minimalBitmap(
                    context, content.text.body, content.text.footer, sizeDp, scale,
                    shadow = content.transparent)

    companion object {
        // Keep in sync with QuoteWidgetService (lib/services/quote_widget_service.dart).
        private const val KEY_TEXT = "qotd_text"
        private const val KEY_AUTHOR = "qotd_author"

        /**
         * Per-widget "transparent background" flag, in home_widget's storage
         * so a change redraws through the same state. Native only: Dart
         * never reads or writes it.
         */
        private const val CLEAR_PREFIX = "minimal_clear_"

        fun clearKey(appWidgetId: Int) = CLEAR_PREFIX + appWidgetId
    }
}
