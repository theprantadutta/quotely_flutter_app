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
import androidx.core.content.res.ResourcesCompat
import androidx.core.os.BundleCompat
import androidx.glance.action.Action
import com.pranta.quotely.MainActivity
import com.pranta.quotely.R
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.actionStartActivity
import org.json.JSONObject
import java.io.File
import java.time.LocalDate
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * What Quotely's home-screen widgets share: the bitmap memory budget, the
 * app's fonts, the text drawn into a bitmap, the poster cropped and rounded,
 * the day's glow, the colours, the tap action, and the placement log for
 * analytics. [ArtWidget] puts them together in Glance.
 *
 * Why the text is a bitmap: a widget's views are inflated in the launcher's
 * process, and launchers don't reliably load an app's res/font fonts there
 * (One UI falls back to the system sans). Drawing here, in the app's process,
 * always gets Instrument Serif and IBM Plex Mono. The text and the glow are
 * drawn white with alpha and tinted with a day and a night colour where they
 * are shown, so they still follow the system's dark mode without a redraw.
 */
object WidgetArt {

    /** The three lines every widget draws. [footer] is drawn after "— ". */
    class Text(val eyebrow: String, val body: String, val footer: String?)

    /** Longest edge of the poster bitmap in pixels: plenty for a blur. */
    private const val POSTER_MAX_EDGE_PX = 360f

    /** Longest edge of the glow bitmap: soft gradients scale up cleanly. */
    private const val GLOW_MAX_EDGE_PX = 240f

    /**
     * The quote grows with the widget: up to QUOTE_MAX_PER_SHORT_SIDE of its
     * shorter side (a 4x2 phone widget ~26sp, a 4x3 or tablet one up to 40sp,
     * like the original TextView's autosize ceiling of 30sp and above), then
     * shrinks until it fits. A fixed 22sp ceiling left big widgets nearly empty.
     */
    private const val QUOTE_MAX_PER_SHORT_SIDE = 0.24f
    private const val QUOTE_MAX_SP_FLOOR = 22f
    private const val QUOTE_MAX_SP_CEIL = 40f
    private const val QUOTE_MIN_SP = 12f
    private const val QUOTE_LINE_SPACING = 1.02f

    /** Eyebrow and author: ink at this alpha reads as the app's `mute`. */
    private const val SECONDARY_ALPHA = 163 // 64%

    /** The page colours (Spotlight tokens: paper and night). */
    const val PAGE_LIGHT = 0xFFF3EEE5.toInt()
    const val PAGE_DARK = 0xFF15120F.toInt()

    /** The text colours (ink, and parchment at night), as values/qotd_widget.xml. */
    const val INK_LIGHT = 0xFF1D1915.toInt()
    const val INK_DARK = 0xFFEEE7DB.toInt()

    /** The page colour over the poster: paper at 70%, night at 72% (PosterWash). */
    const val WASH_LIGHT = 0xB3F3EEE5.toInt()
    const val WASH_DARK = 0xB815120F.toInt()

    /** The first glow (clay), for when the app hasn't saved any yet. */
    private const val GLOW_LIGHT_DEFAULT = 0xFFF2A07E.toInt()
    private const val GLOW_DARK_DEFAULT = 0xFFC0643F.toInt()

    /** The glow's strength (k in [glowMask]) on paper and at night. */
    private const val GLOW_K_LIGHT = 0.5f
    private const val GLOW_K_DARK = 0.34f

    // Keep in sync with HomeWidgetStore / WidgetAnalytics (lib/services/).
    private const val KEY_GLOW_DAYS = "glow_days"
    private const val KEY_EVENTS = "widget_events"

    // ---- Sizes ------------------------------------------------------------

    /**
     * How many sizes Glance draws a SizeMode.Exact widget at, for them to
     * share the bitmap budget. Mirrors Glance's own choice: on Android 12+
     * the sizes the launcher reports, else (and before Android 12) landscape
     * and portrait, else one.
     */
    fun sizeCount(options: Bundle): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val sizes = BundleCompat.getParcelableArrayList(
                    options, AppWidgetManager.OPTION_APPWIDGET_SIZES, SizeF::class.java)
            if (!sizes.isNullOrEmpty()) return sizes.distinct().size
        }
        val minW = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val maxW = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 0)
        val minH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)
        val maxH = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0)
        return if (minW <= 0 || maxW <= 0 || minH <= 0 || maxH <= 0) 1 else 2
    }

    /**
     * Pixels per widget pixel for this size's bitmaps: 1 (the widget's real
     * pixel size) unless that would push the widget past the system's bitmap
     * memory limit (screen width x height x 4 bytes x 1.5, shared by every
     * size). Half of that limit is used, split across the sizes.
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

    /**
     * Width and height in pixels of a bitmap for a box of [widthDp] x
     * [heightDp] at [pxPerDp]. Both come from the same scale, so the bitmap
     * has the box's aspect ratio to within a pixel's rounding.
     */
    fun pixelSize(widthDp: Float, heightDp: Float, pxPerDp: Float): Pair<Int, Int> =
            max(1, (widthDp * pxPerDp).roundToInt()) to max(1, (heightDp * pxPerDp).roundToInt())

    private fun pixelSize(sizeDp: SizeF, pxPerDp: Float) =
            pixelSize(sizeDp.width, sizeDp.height, pxPerDp)

    // ---- Backgrounds ------------------------------------------------------

    /** The blurred poster the app saved at the path under [key], or null. */
    fun loadPoster(data: SharedPreferences, key: String): Bitmap? {
        val path = data.getString(key, null) ?: return null
        if (!File(path).exists()) return null
        return try {
            // Read the size first, then decode only as large as the widget ever
            // draws it (POSTER_MAX_EDGE_PX, it is a blur), and without alpha:
            // the poster is opaque, so RGB_565 halves its memory again.
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(path, bounds)
            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
            var sample = 1
            while (max(bounds.outWidth, bounds.outHeight) / (sample * 2) >= POSTER_MAX_EDGE_PX) {
                sample *= 2
            }
            val options = BitmapFactory.Options().apply {
                inSampleSize = sample
                inPreferredConfig = Bitmap.Config.RGB_565
            }
            BitmapFactory.decodeFile(path, options)
        } catch (e: Exception) {
            null
        } catch (e: OutOfMemoryError) {
            null
        }
    }

    /**
     * The poster cropped to this size's aspect ratio with the widget's corner
     * radius, so it lines up with the rounded page and wash on every Android
     * version (Glance only clips to the corners from Android 12). Kept small:
     * it is a blur.
     */
    fun posterBitmap(context: Context, poster: Bitmap, sizeDp: SizeF, scale: Float): Bitmap {
        val density = context.resources.displayMetrics.density
        val pxPerDp = min(density * scale, POSTER_MAX_EDGE_PX / max(sizeDp.width, sizeDp.height))
        val (outW, outH) = pixelSize(sizeDp, pxPerDp)
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
     * The day's glow as the app's Glow background paints it (DayGlow in
     * lib/components/thread/spotlight.dart), minus the page and the hue: a
     * glow from the top-right corner (radius 1.6 x the shortest side, full
     * strength) and one from just past the bottom-left (1.4 x, 70%), each
     * fading from strength x k through 45% of that at mid-radius to nothing,
     * with paper's k (0.5). Drawn white with alpha, to be tinted with
     * [Glow.light] on paper and [glowNightTint] at night over the page
     * colour. Rounded like the page.
     */
    fun glowMask(context: Context, sizeDp: SizeF): Bitmap {
        val density = context.resources.displayMetrics.density
        val pxPerDp = min(density, GLOW_MAX_EDGE_PX / max(sizeDp.width, sizeDp.height))
        val (w, h) = pixelSize(sizeDp, pxPerDp)
        val radius = context.resources.getDimension(R.dimen.qotd_widget_radius) / density * pxPerDp
        val rect = RectF(0f, 0f, w.toFloat(), h.toFloat())
        val shortest = min(w, h).toFloat()

        val out = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)

        fun glow(cx: Float, cy: Float, r: Float, strength: Float) {
            fun white(alpha: Float) =
                    Color.argb((alpha * 255f).roundToInt().coerceIn(0, 255), 255, 255, 255)
            val k = GLOW_K_LIGHT
            paint.shader = RadialGradient(
                    cx, cy, max(1f, r),
                    intArrayOf(white(strength * k), white(strength * k * 0.45f), white(0f)),
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

    /**
     * What to tint the [glowMask] with at night. The mask carries paper's
     * strength, so the night hue is pre-mixed with the night page by the
     * ratio of the strengths: the page under the mask's alpha a in this
     * colour is the page under the night hue at a x 0.34 / 0.5, which is
     * what the app paints at night.
     */
    fun glowNightTint(hue: Int): Int = mix(PAGE_DARK, hue, GLOW_K_DARK / GLOW_K_LIGHT)

    /** Opaque [from] moved [t] of the way to [to], channel by channel (ARGB ints). */
    fun mix(from: Int, to: Int, t: Float): Int {
        fun channel(shift: Int): Int {
            val a = (from shr shift) and 0xFF
            val b = (to shr shift) and 0xFF
            return (a + (b - a) * t).roundToInt().coerceIn(0, 255) shl shift
        }
        return (0xFF shl 24) or channel(16) or channel(8) or channel(0)
    }

    // ---- Text -------------------------------------------------------------

    /**
     * Eyebrow, body and footer: the eyebrow at the top, the footer at the
     * bottom, and the body centred between them. Margins and the eyebrow and
     * footer sizes scale with the widget's shorter side, so a 2x2, a 4x3 and a
     * tablet widget all look proportioned. The body starts as large as the
     * widget allows and shrinks until it fits, ellipsized only as a last
     * resort. White with alpha; tinted where it is shown.
     *
     * The bitmap is [sizeDp] at [scale] x the density, so in a box of
     * [sizeDp] it has the box's aspect ratio and is never stretched.
     */
    fun textBitmap(context: Context, text: Text, sizeDp: SizeF, scale: Float): Bitmap {
        val metrics = context.resources.displayMetrics
        val pxPerDp = metrics.density * scale
        fun dp(v: Float) = v * pxPerDp
        fun sp(v: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, v, metrics) * scale

        val (width, height) = pixelSize(sizeDp, pxPerDp)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        // Proportions follow the shorter side (dp), within readable bounds.
        val shortDp = min(sizeDp.width, sizeDp.height)
        fun scaled(perShort: Float, lo: Float, hi: Float) = (shortDp * perShort).coerceIn(lo, hi)
        val side = dp(scaled(0.1f, 14f, 20f))
        val gap = dp(scaled(0.035f, 5f, 8f))

        val left = side
        val right = width - side
        val contentWidth = max(1, (right - left).toInt())
        var top = dp(scaled(0.085f, 12f, 18f))
        var bottom = height - dp(scaled(0.085f, 12f, 18f))

        // Eyebrow.
        val eyebrow = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = fonts(context).mono
            textSize = sp(scaled(0.05f, 9f, 11f))
            letterSpacing = 0.16f
            color = Color.WHITE
            alpha = SECONDARY_ALPHA
        }
        val eyebrowText = TextUtils.ellipsize(
                text.eyebrow, eyebrow, contentWidth.toFloat(), TextUtils.TruncateAt.END)
        val eyebrowMetrics = eyebrow.fontMetrics
        canvas.drawText(eyebrowText, 0, eyebrowText.length, left, top - eyebrowMetrics.ascent, eyebrow)
        top += eyebrowMetrics.descent - eyebrowMetrics.ascent + gap

        // Footer ("— Author"), if any.
        val footer = text.footer
        if (!footer.isNullOrEmpty()) {
            val author = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
                textSize = sp(scaled(0.06f, 11.5f, 13.5f))
                color = Color.WHITE
                alpha = SECONDARY_ALPHA
            }
            val authorText = TextUtils.ellipsize(
                    context.getString(R.string.qotd_widget_author, footer), author,
                    contentWidth.toFloat(), TextUtils.TruncateAt.END)
            val authorMetrics = author.fontMetrics
            canvas.drawText(authorText, 0, authorText.length, left, bottom - authorMetrics.descent, author)
            bottom -= authorMetrics.descent - authorMetrics.ascent + gap
        }

        // Body, centred in what is left.
        val area = (bottom - top).toInt()
        if (area > 0) {
            val quote = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                typeface = fonts(context).serif
                color = Color.WHITE
            }
            val maxSp = scaled(QUOTE_MAX_PER_SHORT_SIDE, QUOTE_MAX_SP_FLOOR, QUOTE_MAX_SP_CEIL)
            val layout = fitQuote(text.body, quote, contentWidth, area, sp(maxSp), sp(QUOTE_MIN_SP), sp(1f))
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

    // ---- Minimal and the small square --------------------------------------

    /**
     * Minimal quote: the quote in the serif and "— author" just under it, the
     * pair centred vertically, nothing else. The quote fits exactly as in
     * [textBitmap] (as large as the widget allows, shrinking until it fits).
     * The author is left out when the widget is too short to hold it and a
     * readable line of the quote (a 2x1), so the quote always wins.
     *
     * [shadow] false: white with alpha, tinted with the ink where shown, so it
     * follows day and night on the page. [shadow] true: for the transparent
     * background, already coloured (parchment) with a soft dark shadow, the
     * way launchers draw their own icon labels over any wallpaper.
     *
     * The bitmap is [sizeDp] at [scale] x the density: never stretched.
     */
    fun minimalBitmap(
            context: Context,
            body: String,
            author: String?,
            sizeDp: SizeF,
            scale: Float,
            shadow: Boolean,
    ): Bitmap {
        val metrics = context.resources.displayMetrics
        val pxPerDp = metrics.density * scale
        fun dp(v: Float) = v * pxPerDp
        fun sp(v: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, v, metrics) * scale

        val (width, height) = pixelSize(sizeDp, pxPerDp)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val shortDp = min(sizeDp.width, sizeDp.height)
        fun scaled(perShort: Float, lo: Float, hi: Float) = (shortDp * perShort).coerceIn(lo, hi)
        val side = dp(scaled(0.1f, 14f, 20f))
        // Shorter than the card's top and bottom margins, so a 2x1 still has room.
        val vertical = dp(scaled(0.085f, 6f, 18f))
        val gap = dp(scaled(0.04f, 4f, 10f))
        val contentWidth = max(1, (width - 2 * side).toInt())
        val area = (height - 2 * vertical).toInt()
        if (area <= 0) return bitmap

        fun TextPaint.ink(alpha: Int) {
            if (shadow) {
                color = INK_DARK
                this.alpha = alpha
                setShadowLayer(dp(2.5f), 0f, dp(0.75f), SHADOW)
            } else {
                color = Color.WHITE
                this.alpha = alpha
            }
        }

        val quote = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = fonts(context).serif
            ink(255)
        }
        val minPx = sp(QUOTE_MIN_SP)

        // The author, if there is room for it and at least one line of quote.
        var authorText: CharSequence? = null
        val authorPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
            textSize = sp(scaled(0.06f, 11f, 14f))
            ink(if (shadow) 225 else SECONDARY_ALPHA)
        }
        val authorMetrics = authorPaint.fontMetrics
        val authorHeight = authorMetrics.descent - authorMetrics.ascent
        if (!author.isNullOrEmpty()) {
            quote.textSize = minPx
            val oneLine = quoteLayout("A", quote, contentWidth, 1).height
            if (area - authorHeight - gap >= oneLine) {
                authorText = TextUtils.ellipsize(
                        context.getString(R.string.qotd_widget_author, author), authorPaint,
                        contentWidth.toFloat(), TextUtils.TruncateAt.END)
            }
        }
        val authorSpace = if (authorText != null) authorHeight + gap else 0f

        val maxSp = scaled(QUOTE_MAX_PER_SHORT_SIDE, QUOTE_MAX_SP_FLOOR, QUOTE_MAX_SP_CEIL)
        val layout = fitQuote(
                body, quote, contentWidth, max(1, (area - authorSpace).toInt()),
                sp(maxSp), minPx, sp(1f))
        val block = layout.height + authorSpace
        val top = vertical + max(0f, (area - block) / 2f)
        canvas.save()
        canvas.translate(side, top)
        layout.draw(canvas)
        canvas.restore()
        authorText?.let {
            val baseline = top + layout.height + gap - authorMetrics.ascent
            canvas.drawText(it, 0, it.length, side, baseline, authorPaint)
        }
        return bitmap
    }

    /** The minimal widget's text shadow over a transparent background. */
    private const val SHADOW = 0x8C000000.toInt() // black at 55%

    /** Below this shorter side (dp) the square is a 1x1: the mark alone. */
    const val SQUARE_COMPACT_DP = 90f

    /** The Quotely mark: Instrument Serif's opening quote. */
    private const val MARK = "“"

    /**
     * The small square: the Quotely mark (Instrument Serif's opening quote)
     * at the top left and [body] at the bottom, the quote's size fitted as in
     * [textBitmap]; [eyebrow], if any, sits just above [body] in the mono. A
     * 1x1 ([SQUARE_COMPACT_DP]) is too small to read a line in, so there the
     * mark is drawn alone, centred and large. White with alpha; tinted where
     * shown, so it follows day and night. Never stretched.
     */
    fun squareBitmap(
            context: Context,
            eyebrow: String?,
            body: String,
            sizeDp: SizeF,
            scale: Float,
    ): Bitmap {
        val metrics = context.resources.displayMetrics
        val pxPerDp = metrics.density * scale
        fun dp(v: Float) = v * pxPerDp
        fun sp(v: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, v, metrics) * scale

        val (width, height) = pixelSize(sizeDp, pxPerDp)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val shortDp = min(sizeDp.width, sizeDp.height)
        fun scaled(perShort: Float, lo: Float, hi: Float) = (shortDp * perShort).coerceIn(lo, hi)

        val mark = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = fonts(context).serif
            color = Color.WHITE
        }

        /** Draws the mark [glyphPx] tall with its ink's top left at ([x], [y]). */
        fun drawMark(glyphPx: Float, x: Float, y: Float): android.graphics.Rect {
            mark.textSize = 100f
            val probe = android.graphics.Rect()
            mark.getTextBounds(MARK, 0, MARK.length, probe)
            mark.textSize = 100f * glyphPx / max(1, probe.height())
            val bounds = android.graphics.Rect()
            mark.getTextBounds(MARK, 0, MARK.length, bounds)
            canvas.drawText(MARK, x - bounds.left, y - bounds.top, mark)
            return bounds
        }

        if (shortDp < SQUARE_COMPACT_DP) {
            val glyph = dp(shortDp * 0.36f)
            mark.textSize = 100f
            val probe = android.graphics.Rect()
            mark.getTextBounds(MARK, 0, MARK.length, probe)
            val glyphWidth = glyph * probe.width() / max(1, probe.height())
            drawMark(glyph, (width - glyphWidth) / 2f, (height - glyph) / 2f)
            return bitmap
        }

        val pad = dp(scaled(0.1f, 12f, 18f))
        val gap = dp(scaled(0.035f, 4f, 8f))
        val contentWidth = max(1, (width - 2 * pad).toInt())
        val markBounds = drawMark(dp(scaled(0.17f, 14f, 30f)), pad, pad)
        val top = pad + markBounds.height() + gap * 2
        val bottom = height - pad

        val quote = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = fonts(context).serif
            color = Color.WHITE
        }
        val eyebrowPaint = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = fonts(context).mono
            textSize = sp(scaled(0.06f, 8f, 10f))
            letterSpacing = 0.12f
            color = Color.WHITE
            alpha = SECONDARY_ALPHA
        }
        val eyebrowMetrics = eyebrowPaint.fontMetrics
        val eyebrowHeight = if (eyebrow.isNullOrEmpty()) 0f
                else eyebrowMetrics.descent - eyebrowMetrics.ascent + gap

        val area = (bottom - top - eyebrowHeight).toInt()
        if (area <= 0) return bitmap
        val maxSp = scaled(QUOTE_MAX_PER_SHORT_SIDE, QUOTE_MAX_SP_FLOOR, QUOTE_MAX_SP_CEIL)
        val layout = fitQuote(body, quote, contentWidth, area, sp(maxSp), sp(QUOTE_MIN_SP), sp(1f))
        // Bottom-aligned: the mark at the top, the words at the foot.
        val layoutTop = bottom - layout.height
        if (!eyebrow.isNullOrEmpty()) {
            val text = TextUtils.ellipsize(eyebrow, eyebrowPaint, contentWidth.toFloat(), TextUtils.TruncateAt.END)
            val baseline = layoutTop - gap - eyebrowMetrics.descent
            canvas.drawText(text, 0, text.length, pad, baseline, eyebrowPaint)
        }
        canvas.save()
        canvas.translate(pad, layoutTop)
        layout.draw(canvas)
        canvas.restore()
        return bitmap
    }

    // ---- Taps and analytics ----------------------------------------------

    /**
     * Opens the app at [uri], as home_widget's launch intent
     * (HomeWidgetLaunchIntent's action, with [uri] as the data) in a Glance
     * action. Its path is a Flutter route, so Flutter's own deep linking
     * lands there too; the `homeWidget` query marks it as a widget launch for
     * home_widget, and `kind` says which widget it was.
     */
    fun launch(context: Context, uri: String): Action =
            actionStartActivity<MainActivity>(context, Uri.parse(uri))

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
