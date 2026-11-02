package com.pranta.quotely.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import com.pranta.quotely.R
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * The Quote of the Day home-screen widget.
 *
 * It only displays what the app saved through home_widget (QuoteWidgetService
 * in Dart): the quote, its author, and the day's scene poster as a PNG that is
 * already blurred. Here the poster is cropped to the widget's shape and its
 * corners rounded, and the text is drawn into a bitmap of its own with the
 * app's fonts (see [WidgetArt] for why). The text is tinted with the ink
 * colour in layout/qotd_widget.xml, so it still follows the system's dark
 * mode without a redraw, as do the page colour and the wash.
 *
 * A tap opens the app on Today. The URI's path is the Today route, so Flutter's
 * own deep linking lands there too; the `homeWidget` query marks it as a
 * widget launch for home_widget on iOS, and is kept the same here.
 */
class QuoteOfTheDayWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
            widgetData: SharedPreferences,
    ) {
        val content = Content.load(widgetData)
        for (id in appWidgetIds) {
            update(context, appWidgetManager, id, content)
        }
    }

    /** Resized: redraw for the new size. */
    override fun onAppWidgetOptionsChanged(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        update(context, appWidgetManager, appWidgetId, Content.load(HomeWidgetPlugin.getData(context)))
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetArt.recordEvent(context, KIND, placed = true)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetArt.recordEvent(context, KIND, placed = false)
    }

    /** What the app saved. */
    private class Content(val text: String, val author: String, val poster: Bitmap?) {
        companion object {
            fun load(data: SharedPreferences) = Content(
                    text = data.getString(KEY_TEXT, null)?.trim().orEmpty(),
                    author = data.getString(KEY_AUTHOR, null)?.trim().orEmpty(),
                    poster = WidgetArt.loadPoster(data, KEY_POSTER),
            )
        }
    }

    private fun update(context: Context, manager: AppWidgetManager, appWidgetId: Int, content: Content) {
        WidgetArt.update(manager, appWidgetId) { size, count -> buildViews(context, content, size, count) }
    }

    /** The widget at [sizeDp], one of [sizeCount] sizes sharing the bitmap budget. */
    private fun buildViews(context: Context, content: Content, sizeDp: SizeF, sizeCount: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.qotd_widget)
        val scale = WidgetArt.bitmapScale(context, sizeDp, sizeCount)

        val poster = content.poster?.let { WidgetArt.posterBitmap(context, it, sizeDp, scale) }
        if (poster != null) {
            views.setImageViewBitmap(R.id.qotd_poster, poster)
            views.setViewVisibility(R.id.qotd_poster, View.VISIBLE)
            views.setViewVisibility(R.id.qotd_wash, View.VISIBLE)
        } else {
            // No poster: the plain page colour of the system theme.
            views.setViewVisibility(R.id.qotd_poster, View.GONE)
            views.setViewVisibility(R.id.qotd_wash, View.GONE)
        }

        val hasQuote = content.text.isNotEmpty()
        val text = WidgetArt.Text(
                eyebrow = context.getString(R.string.qotd_widget_eyebrow),
                body = if (hasQuote) content.text else context.getString(R.string.qotd_widget_empty),
                footer = if (hasQuote) content.author else null,
        )
        views.setImageViewBitmap(R.id.qotd_text, WidgetArt.textBitmap(context, text, sizeDp, scale))
        views.setContentDescription(R.id.qotd_text, describe(context, content))

        views.setOnClickPendingIntent(android.R.id.background, WidgetArt.launch(context, LAUNCH_URI))
        return views
    }

    private fun describe(context: Context, content: Content): String {
        if (content.text.isEmpty()) return context.getString(R.string.qotd_widget_empty)
        return if (content.author.isEmpty()) {
            context.getString(R.string.qotd_widget_a11y, content.text)
        } else {
            context.getString(R.string.qotd_widget_a11y_author, content.text, content.author)
        }
    }

    companion object {
        /** QuotelyWidgetKind.qotd.id, for analytics. */
        private const val KIND = "qotd"

        // Keep in sync with QuoteWidgetService (lib/services/quote_widget_service.dart).
        private const val KEY_TEXT = "qotd_text"
        private const val KEY_AUTHOR = "qotd_author"
        private const val KEY_POSTER = "qotd_poster"

        /** Opens Today (Routes.today). */
        private const val LAUNCH_URI = "quotely://widget/home?homeWidget&kind=qotd"
    }
}
