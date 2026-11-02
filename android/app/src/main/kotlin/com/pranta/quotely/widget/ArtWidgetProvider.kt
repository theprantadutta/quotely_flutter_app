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
 * A widget drawn on layout/quotely_art_widget.xml: text over either a
 * blurred poster under the page-colour wash, or the page with the day's glow.
 * From your saved and Scene of the Day are this, with their own [content].
 */
abstract class ArtWidgetProvider : HomeWidgetProvider() {

    /** What to draw, and what TalkBack reads. */
    class Content(
            val text: WidgetArt.Text,
            val description: String,
            val poster: Bitmap?,
            val glow: WidgetArt.Glow,
    )

    /** QuotelyWidgetKind.id, for analytics. */
    protected abstract val kind: String

    /** Where a tap opens the app; see [WidgetArt.launch]. */
    protected abstract val launchUri: String

    /** Reads what the app saved. */
    protected abstract fun content(context: Context, data: SharedPreferences): Content

    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
            widgetData: SharedPreferences,
    ) {
        val content = content(context, widgetData)
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
        update(context, appWidgetManager, appWidgetId, content(context, HomeWidgetPlugin.getData(context)))
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetArt.recordEvent(context, kind, placed = true)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetArt.recordEvent(context, kind, placed = false)
    }

    private fun update(context: Context, manager: AppWidgetManager, appWidgetId: Int, content: Content) {
        WidgetArt.update(manager, appWidgetId) { size, count -> buildViews(context, content, size, count) }
    }

    private fun buildViews(context: Context, content: Content, sizeDp: SizeF, sizeCount: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.quotely_art_widget)
        val scale = WidgetArt.bitmapScale(context, sizeDp, sizeCount)

        val poster = content.poster?.let { WidgetArt.posterBitmap(context, it, sizeDp, scale) }
        if (poster != null) {
            // The poster covers the glow layers, which stay empty.
            views.setImageViewBitmap(R.id.art_poster, poster)
            views.setViewVisibility(R.id.art_poster, View.VISIBLE)
            views.setViewVisibility(R.id.art_wash, View.VISIBLE)
        } else {
            // Both glows; the layout shows the one for the system theme.
            views.setImageViewBitmap(R.id.art_glow_light,
                    WidgetArt.glowBitmap(context, sizeDp, dark = false, hue = content.glow.light))
            views.setImageViewBitmap(R.id.art_glow_dark,
                    WidgetArt.glowBitmap(context, sizeDp, dark = true, hue = content.glow.dark))
        }

        views.setImageViewBitmap(R.id.art_text, WidgetArt.textBitmap(context, content.text, sizeDp, scale))
        views.setContentDescription(R.id.art_text, content.description)
        views.setOnClickPendingIntent(android.R.id.background, WidgetArt.launch(context, launchUri))
        return views
    }
}
