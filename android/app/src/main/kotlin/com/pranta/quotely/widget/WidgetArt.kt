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
import android.graphics.RadialGradient
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
import android.widget.RemoteViews
import androidx.core.content.res.ResourcesCompat
import androidx.core.os.BundleCompat
import com.pranta.quotely.MainActivity
import com.pranta.quotely.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject
import java.io.File
import java.time.LocalDate
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * What Quotely's home-screen widgets share: per-size RemoteViews within the
 * bitmap memory limit, the app's fonts, the text drawn into a bitmap, the
 * poster cropped and rounded, the page with the day's glow, tap intents, and
 * the placement log for analytics.
 *
 * Why the text is a bitmap: RemoteViews are inflated in the launcher's
 * process, and launchers don't reliably load an app's res/font fonts there
 * (One UI falls back to the system sans). Drawing here, in the app's process,
 * always gets Instrument Serif and IBM Plex Mono. The text is drawn white
 * with alpha and tinted with the ink colour by the layout, so it still
 * follows the system's dark mode without a redraw.
 */
object WidgetArt {

    /** The three lines every widget draws. [footer] is drawn after "— ". */
    class Text(val eyebrow: String, val body: String, val footer: String?)

    /** Used until the launcher reports a size: the default 4x2. */
    private val DEFAULT_SIZE = SizeF(250f, 110f)

    /** RemoteViews accepts at most 16 sizes; launchers report one or two. */
    private const val MAX_SIZES = 4

    /** Longest edge of the poster bitmap in pixels: plenty for a blur. */
    private const val POSTER_MAX_EDGE_PX = 360f

    /** Longest edge of the glow bitmaps: soft gradients scale up cleanly. */
    private const val GLOW_MAX_EDGE_PX = 240f

    private const val QUOTE_MAX_SP = 22f
    private const val QUOTE_MIN_SP = 13f
    private const val QUOTE_LINE_SPACING = 1.02f

    /** Eyebrow and author: ink at this alpha reads as the app's `mute`. */
    private const val SECONDARY_ALPHA = 163 // 64%

    /** The page colours (Spotlight tokens: paper and night). */
    const val PAGE_LIGHT = 0xFFF3EEE5.toInt()
    const val PAGE_DARK = 0xFF15120F.toInt()

    /** The first glow (clay), for when the app hasn't saved any yet. */
    private const val GLOW_LIGHT_DEFAULT = 0xFFF2A07E.toInt()
    private const val GLOW_DARK_DEFAULT = 0xFFC0643F.toInt()

    // Keep in sync with HomeWidgetStore / WidgetAnalytics (lib/services/).
    private const val KEY_GLOW_DAYS = "glow_days"
    private const val KEY_EVENTS = "widget_events"

    // ---- Sizes ------------------------------------------------------------

    /**
     * Gives [appWidgetId] one RemoteViews per size the launcher may show
     * (Android 12+: the sizes it reports; before that: landscape and
     * portrait), each from [build] with the size in dp and the number of
     * sizes sharing the bitmap budget, so text is never stretched.
     */
    fun update(manager: AppWidgetManager, appWidgetId: Int, build: (SizeF, Int) -> RemoteViews) {
        val options = manager.getAppWidgetOptions(appWidgetId)
        val sized = try {
            sizedViews(options, build)
        } catch (e: Exception) {
            null
        } catch (e: OutOfMemoryError) {
            null
        }
        manager.updateAppWidget(appWidgetId, sized ?: build(DEFAULT_SIZE, 1))
    }

    private fun sizedViews(options: Bundle, build: (SizeF, Int) -> RemoteViews): RemoteViews? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val sizes = BundleCompat.getParcelableArrayList(
                    options, AppWidgetManager.OPTION_APPWIDGET_SIZES, SizeF::class.java)
                    ?.filter { it.width > 0f && it.height > 0f }
                    ?.distinct()
                    ?.take(MAX_SIZES)
            if (!sizes.isNullOrEmpty()) {
                return RemoteViews(sizes.associateWith { build(it, sizes.size) })
            }
        }
        val minW = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val maxW = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0)
        val minH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val maxH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        if (minW <= 0 || maxW <= 0 || minH <= 0 || maxH <= 0) return null
        return RemoteViews(
                build(SizeF(maxW.toFloat(), minH.toFloat()), 2),
                build(SizeF(minW.toFloat(), maxH.toFloat()), 2),
        )
    }

    /**
     * Pixels per widget pixel for this size's bitmaps: 1 (the widget's real
     * pixel size) unless that would push the RemoteViews past the system's
     * bitmap memory limit (screen width x height x 4 bytes x 1.5, shared by
     * every size). Half of that limit is used, split across the sizes.
     */
    fun bitmapScale(context: Context, sizeDp: SizeF, sizeCount: Int): Float {
        val metrics = context.resources.displayMetrics
        val limitBytes = metrics.widthPixels.toFloat() * metrics.heightPixels * 4f * 1.5f
        val budgetBytes = limitBytes * 0.5f / max(1, sizeCount)
        val wPx = sizeDp.width * metrics.density
        val hPx = sizeDp.height * metrics.density
        // The text bitmap is full size; the poster and glow are capped far smaller.
        val bytes = wPx * hPx * 4f
        return if (bytes <= budgetBytes) 1f else sqrt(budgetBytes / bytes)
    }

    // ---- Backgrounds ------------------------------------------------------

    /** The blurred poster the app saved at the path under [key], or null. */
    fun loadPoster(data: SharedPreferences, key: String): Bitmap? {
        val path = data.getString(key, null) ?: return null
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
     * The poster cropped to this size's aspect ratio with the widget's corner
     * radius, so it lines up with the rounded page and wash on every Android
     * version (clipToOutline only rounds it from Android 12). Kept small: it is
     * a blur.
     */
    fun posterBitmap(context: Context, poster: Bitmap, sizeDp: SizeF, scale: Float): Bitmap {
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

    /** Today's glow hue, light and dark, from the days the app saved. */
    class Glow(val light: Int, val dark: Int)

    fun glowToday(data: SharedPreferences): Glow {
        return try {
            val json = JSONObject(data.getString(KEY_GLOW_DAYS, null) ?: return defaultGlow())
            val light = json.getJSONArray("light")
            val dark = json.getJSONArray("dark")
            val count = min(light.length(), dark.length())
            if (count == 0) return defaultGlow()
            val i = Math.floorMod(daysSince(json.getString("start")), count)
            Glow(light.getLong(i).toInt(), dark.getLong(i).toInt())
        } catch (e: Exception) {
            defaultGlow()
        }
    }

    private fun defaultGlow() = Glow(GLOW_LIGHT_DEFAULT, GLOW_DARK_DEFAULT)

    /** Calendar days from [start] (yyyy-MM-dd) to today, local time. */
    fun daysSince(start: String): Int =
            (LocalDate.now().toEpochDay() - LocalDate.parse(start).toEpochDay()).toInt()

    /**
     * The page with the day's glow, as the app's Glow background paints it
     * (DayGlow in lib/components/thread/spotlight.dart): the page colour, a
     * glow from the top-right corner (radius 1.6 x the shortest side, full
     * strength) and one from just past the bottom-left (1.4 x, 70%), each
     * fading from hue x strength x k through 45% of that at mid-radius to
     * nothing. k is 0.5 on paper and 0.34 at night. Rounded like the page.
     */
    fun glowBitmap(context: Context, sizeDp: SizeF, dark: Boolean, hue: Int): Bitmap {
        val density = context.resources.displayMetrics.density
        val pxPerDp = min(density, GLOW_MAX_EDGE_PX / max(sizeDp.width, sizeDp.height))
        val w = max(1, (sizeDp.width * pxPerDp).roundToInt())
        val h = max(1, (sizeDp.height * pxPerDp).roundToInt())
        val radius = context.resources.getDimension(R.dimen.qotd_widget_radius) / density * pxPerDp
        val rect = RectF(0f, 0f, w.toFloat(), h.toFloat())
        val shortest = min(w, h).toFloat()
        val k = if (dark) 0.34f else 0.5f

        val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.color = if (dark) PAGE_DARK else PAGE_LIGHT
        canvas.drawRoundRect(rect, radius, radius, paint)

        fun glow(cx: Float, cy: Float, r: Float, strength: Float) {
            fun tone(alpha: Float) =
                    Color.argb((alpha * 255f).roundToInt().coerceIn(0, 255),
                            Color.red(hue), Color.green(hue), Color.blue(hue))
            paint.shader = RadialGradient(
                    cx, cy, max(1f, r),
                    intArrayOf(tone(strength * k), tone(strength * k * 0.45f), tone(0f)),
                    floatArrayOf(0f, 0.5f, 1f),
                    Shader.TileMode.CLAMP)
            canvas.drawRoundRect(rect, radius, radius, paint)
            paint.shader = null
        }
        // Alignment(1, -1) and Alignment(-1.1, 1) in Flutter's terms.
        glow(w.toFloat(), 0f, 1.6f * shortest, 1.0f)
        glow(-0.05f * w, h.toFloat(), 1.4f * shortest, 0.7f)
        return out
    }

    // ---- Text -------------------------------------------------------------

    /**
     * Eyebrow, body and footer, laid out as the widget's TextView layout
     * once was: 16dp sides, 14dp top and bottom, the eyebrow at the top, the
     * footer at the bottom, and the body centred between them with 6dp
     * either side. The body shrinks from 22sp towards 13sp until it fits, and
     * is ellipsized only if it still doesn't. White with alpha; tinted by the
     * layout.
     */
    fun textBitmap(context: Context, text: Text, sizeDp: SizeF, scale: Float): Bitmap {
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
                text.eyebrow, eyebrow, contentWidth.toFloat(), TextUtils.TruncateAt.END)
        val eyebrowMetrics = eyebrow.fontMetrics
        canvas.drawText(eyebrowText, 0, eyebrowText.length, left, top - eyebrowMetrics.ascent, eyebrow)
        top += eyebrowMetrics.descent - eyebrowMetrics.ascent + dp(6f)

        // Footer ("— Author"), if any.
        val footer = text.footer
        if (!footer.isNullOrEmpty()) {
            val author = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
                textSize = sp(11.5f)
                color = Color.WHITE
                alpha = SECONDARY_ALPHA
            }
            val authorText = TextUtils.ellipsize(
                    context.getString(R.string.qotd_widget_author, footer), author,
                    contentWidth.toFloat(), TextUtils.TruncateAt.END)
            val authorMetrics = author.fontMetrics
            canvas.drawText(authorText, 0, authorText.length, left, bottom - authorMetrics.descent, author)
            bottom -= authorMetrics.descent - authorMetrics.ascent + dp(6f)
        }

        // Body, centred in what is left.
        val area = (bottom - top).toInt()
        if (area > 0) {
            val quote = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = fonts(context).serif
                color = Color.WHITE
            }
            val layout = fitQuote(text.body, quote, contentWidth, area, sp(QUOTE_MAX_SP), sp(QUOTE_MIN_SP), sp(1f))
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

    // ---- Taps and analytics ----------------------------------------------

    /**
     * Opens the app at [uri]. Its path is a Flutter route, so Flutter's own
     * deep linking lands there too; the `homeWidget` query marks it as a
     * widget launch for home_widget, and `kind` says which widget it was.
     */
    fun launch(context: Context, uri: String) =
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uri))

    /**
     * Notes that the first widget of [kind] was placed, or the last one
     * removed, for the app to log next time it runs
     * (WidgetAnalytics.flushPlacements in Dart). Never throws.
     */
    fun recordEvent(context: Context, kind: String, placed: Boolean) {
        try {
            val prefs = HomeWidgetPlugin.getData(context)
            val entry = (if (placed) "placed:" else "removed:") + kind
            val events = prefs.getString(KEY_EVENTS, null)
                    ?.split(',')?.filter { it.isNotBlank() }?.takeLast(49).orEmpty() + entry
            prefs.edit().putString(KEY_EVENTS, events.joinToString(",")).apply()
        } catch (e: Exception) {
            // Analytics must never break the widget.
        }
    }
}
