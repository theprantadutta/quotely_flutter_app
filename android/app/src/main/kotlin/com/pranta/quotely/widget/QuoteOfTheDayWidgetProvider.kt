package com.pranta.quotely.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import android.util.SizeF
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.res.ResourcesCompat
import androidx.core.os.BundleCompat
import com.pranta.quotely.MainActivity
import com.pranta.quotely.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * The Quote of the Day home-screen widget.
 *
 * It only displays what the app saved through home_widget (QuoteWidgetService
 * in Dart): the quote, its author, and the day's scene poster as a PNG that is
 * already blurred. Here the poster is cropped to the widget's shape and its
 * corners rounded, and the text is drawn into a bitmap of its own.
 *
 * Why the text is a bitmap: RemoteViews are inflated in the launcher's
 * process, and launchers don't reliably load an app's res/font fonts there
 * (One UI falls back to the system sans). Drawing here, in the app's process,
 * always gets Instrument Serif and IBM Plex Mono. The text is drawn white
 * with alpha and tinted with the ink colour in layout/qotd_widget.xml, so it
 * still follows the system's dark mode without a redraw, as do the page
 * colour and the wash.
 *
 * Every size the launcher may show gets its own bitmaps (Android 12+: the
 * sizes it reports; before that: portrait and landscape), so text is never
 * stretched.
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

    /** What the app saved. */
    private class Content(val text: String, val author: String, val poster: Bitmap?) {
        companion object {
            fun load(data: SharedPreferences) = Content(
                    text = data.getString(KEY_TEXT, null)?.trim().orEmpty(),
                    author = data.getString(KEY_AUTHOR, null)?.trim().orEmpty(),
                    poster = loadPoster(data),
            )

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
        }
    }

    private fun update(context: Context, manager: AppWidgetManager, appWidgetId: Int, content: Content) {
        val options = manager.getAppWidgetOptions(appWidgetId)
        val sized = try {
            sizedViews(context, options, content)
        } catch (e: Exception) {
            null
        } catch (e: OutOfMemoryError) {
            null
        }
        manager.updateAppWidget(appWidgetId, sized ?: buildViews(context, content, DEFAULT_SIZE, sizeCount = 1))
    }

    /** One RemoteViews per size the launcher may show, or null if unknown. */
    private fun sizedViews(context: Context, options: Bundle, content: Content): RemoteViews? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val sizes = BundleCompat.getParcelableArrayList(
                    options, AppWidgetManager.OPTION_APPWIDGET_SIZES, SizeF::class.java)
                    ?.filter { it.width > 0f && it.height > 0f }
                    ?.distinct()
                    ?.take(MAX_SIZES)
            if (!sizes.isNullOrEmpty()) {
                return RemoteViews(sizes.associateWith { buildViews(context, content, it, sizes.size) })
            }
        }
        val minW = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val maxW = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0)
        val minH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val maxH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        if (minW <= 0 || maxW <= 0 || minH <= 0 || maxH <= 0) return null
        return RemoteViews(
                buildViews(context, content, SizeF(maxW.toFloat(), minH.toFloat()), sizeCount = 2),
                buildViews(context, content, SizeF(minW.toFloat(), maxH.toFloat()), sizeCount = 2),
        )
    }

    /** The widget at [sizeDp], one of [sizeCount] sizes sharing the bitmap budget. */
    private fun buildViews(context: Context, content: Content, sizeDp: SizeF, sizeCount: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.qotd_widget)
        val scale = bitmapScale(context, sizeDp, sizeCount)

        val poster = content.poster?.let { posterBitmap(context, it, sizeDp, scale) }
        if (poster != null) {
            views.setImageViewBitmap(R.id.qotd_poster, poster)
            views.setViewVisibility(R.id.qotd_poster, View.VISIBLE)
            views.setViewVisibility(R.id.qotd_wash, View.VISIBLE)
        } else {
            // No poster: the plain page colour of the system theme.
            views.setViewVisibility(R.id.qotd_poster, View.GONE)
            views.setViewVisibility(R.id.qotd_wash, View.GONE)
        }

        views.setImageViewBitmap(R.id.qotd_text, textBitmap(context, content, sizeDp, scale))
        views.setContentDescription(R.id.qotd_text, describe(context, content))

        views.setOnClickPendingIntent(
                android.R.id.background,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(LAUNCH_URI)),
        )
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

    /**
     * Pixels per widget pixel for this size's bitmaps: 1 (the widget's real
     * pixel size) unless that would push the RemoteViews past the system's
     * bitmap memory limit (screen width x height x 4 bytes x 1.5, shared by
     * every size). Half of that limit is used, split across the sizes.
     */
    private fun bitmapScale(context: Context, sizeDp: SizeF, sizeCount: Int): Float {
        val metrics = context.resources.displayMetrics
        val limitBytes = metrics.widthPixels.toFloat() * metrics.heightPixels * 4f * 1.5f
        val budgetBytes = limitBytes * 0.5f / max(1, sizeCount)
        val wPx = sizeDp.width * metrics.density
        val hPx = sizeDp.height * metrics.density
        // The text bitmap is full size; the poster is capped far smaller.
        val bytes = wPx * hPx * 4f
        return if (bytes <= budgetBytes) 1f else sqrt(budgetBytes / bytes)
    }

    /**
     * The poster cropped to this size's aspect ratio with the widget's corner
     * radius, so it lines up with the rounded page and wash on every Android
     * version (clipToOutline only rounds it from Android 12). Kept small: it is
     * a blur.
     */
    private fun posterBitmap(context: Context, poster: Bitmap, sizeDp: SizeF, scale: Float): Bitmap {
        val density = context.resources.displayMetrics.density
        val pxPerDp = min(density * scale, POSTER_MAX_EDGE_PX / max(sizeDp.width, sizeDp.height))
        val outW = max(1, (sizeDp.width * pxPerDp).roundToInt())
        val outH = max(1, (sizeDp.height * pxPerDp).roundToInt())
        val radius = context.resources.getDimension(R.dimen.qotd_widget_radius) / density * pxPerDp

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

    /**
     * Eyebrow, quote and author, laid out as the old TextView layout was:
     * 16dp sides, 14dp top and bottom, the eyebrow at the top, the author at
     * the bottom, and the quote centred between them with 6dp either side.
     * The quote shrinks from 22sp towards 13sp until it fits, and is
     * ellipsized only if it still doesn't. White with alpha; tinted by the
     * layout.
     */
    private fun textBitmap(context: Context, content: Content, sizeDp: SizeF, scale: Float): Bitmap {
        val metrics = context.resources.displayMetrics
        val pxPerDp = metrics.density * scale
        fun dp(v: Float) = v * pxPerDp
        fun sp(v: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, v, metrics) * scale

        val width = max(1, (sizeDp.width * pxPerDp).roundToInt())
        val height = max(1, (sizeDp.height * pxPerDp).roundToInt())
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val left = dp(16f)
        val right = width - dp(16f)
        val contentWidth = max(1, (right - left).toInt())
        var top = dp(14f)
        var bottom = height - dp(14f)

        // Eyebrow.
        val eyebrow = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = fonts(context).mono
            textSize = sp(9f)
            letterSpacing = 0.16f
            color = Color.WHITE
            alpha = SECONDARY_ALPHA
        }
        val eyebrowText = TextUtils.ellipsize(
                context.getString(R.string.qotd_widget_eyebrow), eyebrow, contentWidth.toFloat(),
                TextUtils.TruncateAt.END)
        val eyebrowMetrics = eyebrow.fontMetrics
        canvas.drawText(eyebrowText, 0, eyebrowText.length, left, top - eyebrowMetrics.ascent, eyebrow)
        top += eyebrowMetrics.descent - eyebrowMetrics.ascent + dp(6f)

        // Author, or nothing for the no-data hint.
        val hasQuote = content.text.isNotEmpty()
        if (hasQuote && content.author.isNotEmpty()) {
            val author = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
                textSize = sp(11.5f)
                color = Color.WHITE
                alpha = SECONDARY_ALPHA
            }
            val authorText = TextUtils.ellipsize(
                    context.getString(R.string.qotd_widget_author, content.author), author,
                    contentWidth.toFloat(), TextUtils.TruncateAt.END)
            val authorMetrics = author.fontMetrics
            canvas.drawText(authorText, 0, authorText.length, left, bottom - authorMetrics.descent, author)
            bottom -= authorMetrics.descent - authorMetrics.ascent + dp(6f)
        }

        // Quote (or the hint), centred in what is left.
        val area = (bottom - top).toInt()
        if (area > 0) {
            val quote = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = fonts(context).serif
                color = Color.WHITE
            }
            val text = if (hasQuote) content.text else context.getString(R.string.qotd_widget_empty)
            val layout = fitQuote(text, quote, contentWidth, area, sp(QUOTE_MAX_SP), sp(QUOTE_MIN_SP), sp(1f))
            canvas.save()
            canvas.translate(left, top + max(0f, (area - layout.height) / 2f))
            layout.draw(canvas)
            canvas.restore()
        }
        return bitmap
    }

    /** The largest size from [maxPx] down to [minPx] at which [text] fits [maxHeight]; else ellipsized at [minPx]. */
    private fun fitQuote(
            text: String,
            paint: TextPaint,
            width: Int,
            maxHeight: Int,
            maxPx: Float,
            minPx: Float,
            stepPx: Float,
    ): StaticLayout {
        var size = maxPx
        while (true) {
            paint.textSize = size
            val layout = quoteLayout(text, paint, width, Int.MAX_VALUE)
            if (layout.height <= maxHeight) return layout
            if (size <= minPx) break
            size = max(minPx, size - max(stepPx, 0.5f))
        }
        paint.textSize = minPx
        val lineHeight = quoteLayout("A", paint, width, 1).height.coerceAtLeast(1)
        val lines = max(1, floor(maxHeight / lineHeight.toFloat()).toInt())
        return quoteLayout(text, paint, width, lines)
    }

    private fun quoteLayout(text: String, paint: TextPaint, width: Int, maxLines: Int): StaticLayout =
            StaticLayout.Builder.obtain(text, 0, text.length, paint, width)
                    .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                    .setLineSpacing(0f, QUOTE_LINE_SPACING)
                    .setIncludePad(false)
                    .setMaxLines(maxLines)
                    .setEllipsize(TextUtils.TruncateAt.END)
                    .build()

    private class Fonts(val serif: Typeface, val mono: Typeface)

    companion object {
        // Keep in sync with QuoteWidgetService (lib/services/quote_widget_service.dart).
        private const val KEY_TEXT = "qotd_text"
        private const val KEY_AUTHOR = "qotd_author"
        private const val KEY_POSTER = "qotd_poster"

        /** Opens Today (Routes.today). */
        private const val LAUNCH_URI = "quotely://widget/home?homeWidget"

        /** Used until the launcher reports a size: the default 4x2. */
        private val DEFAULT_SIZE = SizeF(250f, 110f)

        /** RemoteViews accepts at most 16 sizes; launchers report one or two. */
        private const val MAX_SIZES = 4

        /** Longest edge of the poster bitmap in pixels: plenty for a blur. */
        private const val POSTER_MAX_EDGE_PX = 360f

        private const val QUOTE_MAX_SP = 22f
        private const val QUOTE_MIN_SP = 13f
        private const val QUOTE_LINE_SPACING = 1.02f

        /** Eyebrow and author: ink at this alpha reads as the app's `mute`. */
        private const val SECONDARY_ALPHA = 163 // 64%

        @Volatile private var fonts: Fonts? = null

        /** The app's fonts, loaded once; system serif / monospace if they fail. */
        private fun fonts(context: Context): Fonts = fonts ?: Fonts(
                serif = loadFont(context, R.font.instrument_serif) ?: Typeface.SERIF,
                mono = loadFont(context, R.font.ibm_plex_mono_medium) ?: Typeface.MONOSPACE,
        ).also { fonts = it }

        private fun loadFont(context: Context, id: Int): Typeface? = try {
            ResourcesCompat.getFont(context.applicationContext, id)
        } catch (e: Exception) {
            null
        }
    }
}
