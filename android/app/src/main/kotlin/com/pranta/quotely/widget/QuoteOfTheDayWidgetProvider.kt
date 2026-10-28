package com.pranta.quotely.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.pranta.quotely.MainActivity
import com.pranta.quotely.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * The Quote of the Day home-screen widget.
 *
 * It only displays what the app saved through home_widget (QuoteWidgetService
 * in Dart): the quote, its author, and the day's scene poster as a PNG that is
 * already blurred. Here the poster is cropped to the widget's shape and its
 * corners rounded; the wash over it, the colours and the fonts come from
 * resources (layout/qotd_widget.xml), so they follow the system's dark mode.
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
        val poster = loadPoster(widgetData)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, buildViews(context, appWidgetManager, id, widgetData, poster))
        }
    }

    /** Resized: re-crop the poster to the new shape. */
    override fun onAppWidgetOptionsChanged(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val widgetData = HomeWidgetPlugin.getData(context)
        appWidgetManager.updateAppWidget(
                appWidgetId,
                buildViews(context, appWidgetManager, appWidgetId, widgetData, loadPoster(widgetData)),
        )
    }

    private fun buildViews(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
            data: SharedPreferences,
            poster: Bitmap?,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.qotd_widget)

        val text = data.getString(KEY_TEXT, null)?.trim().orEmpty()
        val author = data.getString(KEY_AUTHOR, null)?.trim().orEmpty()
        if (text.isEmpty()) {
            // Installed before the app has loaded a quote.
            views.setTextViewText(R.id.qotd_text, context.getString(R.string.qotd_widget_empty))
            views.setViewVisibility(R.id.qotd_author, View.GONE)
        } else {
            views.setTextViewText(R.id.qotd_text, text)
            if (author.isEmpty()) {
                views.setViewVisibility(R.id.qotd_author, View.GONE)
            } else {
                views.setTextViewText(
                        R.id.qotd_author, context.getString(R.string.qotd_widget_author, author))
                views.setViewVisibility(R.id.qotd_author, View.VISIBLE)
            }
            views.setContentDescription(
                    android.R.id.background,
                    if (author.isEmpty()) text else "$text — $author",
            )
        }

        val shaped = poster?.let { fitToWidget(context, manager, appWidgetId, it) }
        if (shaped != null) {
            views.setImageViewBitmap(R.id.qotd_poster, shaped)
            views.setViewVisibility(R.id.qotd_poster, View.VISIBLE)
            views.setViewVisibility(R.id.qotd_wash, View.VISIBLE)
        } else {
            // No poster: the plain page colour of the system theme.
            views.setViewVisibility(R.id.qotd_poster, View.GONE)
            views.setViewVisibility(R.id.qotd_wash, View.GONE)
        }

        views.setOnClickPendingIntent(
                android.R.id.background,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(LAUNCH_URI)),
        )
        return views
    }

    private fun loadPoster(data: SharedPreferences): Bitmap? {
        val path = data.getString(KEY_POSTER, null) ?: return null
        if (!File(path).exists()) return null
        return try {
            BitmapFactory.decodeFile(path)
        } catch (e: Exception) {
            null
        } catch (e: OutOfMemoryError) {
            null
        }
    }

    /**
     * The poster cropped to this widget's aspect ratio with the widget's corner
     * radius, so it lines up with the rounded page and wash on every Android
     * version (clipToOutline only rounds it from Android 12). Kept small: it is
     * a blur, and RemoteViews bitmaps travel over IPC.
     */
    private fun fitToWidget(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
            poster: Bitmap,
    ): Bitmap {
        val options = manager.getAppWidgetOptions(appWidgetId)
        // Portrait size: min width, max height (what phones show most).
        val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val heightDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        if (widthDp <= 0 || heightDp <= 0) return poster

        val density = context.resources.displayMetrics.density
        val scale = min(1f, MAX_EDGE_PX / max(widthDp, heightDp).toFloat())
        val outW = max(1, (widthDp * scale).roundToInt())
        val outH = max(1, (heightDp * scale).roundToInt())
        val radius = context.resources.getDimension(R.dimen.qotd_widget_radius) / density * scale

        val matrix = Matrix()
        val cover = max(outW / poster.width.toFloat(), outH / poster.height.toFloat())
        matrix.setScale(cover, cover)
        matrix.postTranslate((outW - poster.width * cover) / 2f, (outH - poster.height * cover) / 2f)
        val shader = BitmapShader(poster, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
        shader.setLocalMatrix(matrix)

        val out = Bitmap.createBitmap(outW, outH, Bitmap.Config.ARGB_8888)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
        paint.shader = shader
        Canvas(out).drawRoundRect(RectF(0f, 0f, outW.toFloat(), outH.toFloat()), radius, radius, paint)
        return out
    }

    companion object {
        // Keep in sync with QuoteWidgetService (lib/services/quote_widget_service.dart).
        private const val KEY_TEXT = "qotd_text"
        private const val KEY_AUTHOR = "qotd_author"
        private const val KEY_POSTER = "qotd_poster"

        /** Opens Today (Routes.today). */
        private const val LAUNCH_URI = "quotely://widget/home?homeWidget"

        /** Longest edge of the poster bitmap in pixels: at most one per dp, plenty for a blur. */
        private const val MAX_EDGE_PX = 360f
    }
}
