package com.pranta.quotely.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.os.Build
import android.util.SizeF
import android.widget.RemoteViews
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.AndroidRemoteViews
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.LocalAppWidgetOptions
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.color.ColorProvider
import androidx.glance.currentState
import androidx.glance.layout.Box
import androidx.glance.layout.ContentScale
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.pranta.quotely.R
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/**
 * A Quotely home-screen widget in Glance: the app's fonts drawn into a
 * bitmap (see [WidgetArt] for why) over either the blurred poster under the
 * page-colour wash, the page with the day's glow, or the plain page.
 * Quote of the Day, From your saved and Scene of the Day are this, with their
 * own [content]; Minimal quote and the small square also draw their own text
 * layout ([textBitmap]), and Minimal can leave out the page ([Content.transparent]).
 *
 * Sizing: SizeMode.Exact composes the widget once for each size the launcher
 * reports, with that size in [LocalSize], and every bitmap is drawn at that
 * size in pixels, so it fills its box without being scaled. The sizes share
 * the bitmap budget ([WidgetArt.bitmapScale]).
 *
 * Dark mode: the text and glow are white masks tinted, and the page and wash
 * filled, with day/night ColorProviders. On Android 12+ Glance hands both
 * colours to the launcher (RemoteViews' night colours), which picks one by
 * the system theme, so they switch without the app running. Before Android
 * 12 Glance can only resolve a ColorProvider once, when it draws; there the
 * page and wash are drawables and the text and glow are small RemoteViews
 * layouts whose colours come from values-night, as the widgets were before.
 *
 * The data is what the app saved through home_widget, read in composition
 * from [HomeWidgetGlanceState], which home_widget renews on every update, so
 * an update from Dart (HomeWidget.updateWidget) redraws a running session too.
 */
abstract class ArtWidget : GlanceAppWidget() {

    /**
     * What to draw, and what TalkBack reads. No [glow]: the plain page.
     * [transparent]: no page at all, and the text bitmap is already coloured
     * (so it is shown untinted on every Android version).
     */
    class Content(
            val text: WidgetArt.Text,
            val description: String,
            val poster: Bitmap?,
            val glow: WidgetArt.Glow?,
            val transparent: Boolean = false,
    )

    /** Where a tap opens the app; see [WidgetArt.launch]. */
    protected abstract val launchUri: String

    /** Reads what the app saved. */
    protected abstract fun content(context: Context, data: SharedPreferences): Content

    /** [content] for one placed widget, for widgets with per-widget settings. */
    protected open fun content(context: Context, data: SharedPreferences, appWidgetId: Int): Content =
            content(context, data)

    /**
     * The text, as a bitmap of [sizeDp] at [scale] x the density. The card
     * layout (eyebrow, body, footer) unless a widget draws its own.
     */
    protected open fun textBitmap(context: Context, content: Content, sizeDp: SizeF, scale: Float): Bitmap =
            WidgetArt.textBitmap(context, content.text, sizeDp, scale)

    override val sizeMode: SizeMode = SizeMode.Exact

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = try {
            GlanceAppWidgetManager(context).getAppWidgetId(id)
        } catch (e: Exception) {
            AppWidgetManager.INVALID_APPWIDGET_ID
        }
        provideContent {
            val data = currentState<HomeWidgetGlanceState>().preferences
            Widget(context, content(context, data, appWidgetId))
        }
    }

    /** The widget at [LocalSize], one of the sizes sharing the bitmap budget. */
    @Composable
    private fun Widget(context: Context, content: Content) {
        val size = LocalSize.current
        val sizeDp = SizeF(size.width.value, size.height.value)
        val sizeCount = WidgetArt.sizeCount(LocalAppWidgetOptions.current)
        val scale = WidgetArt.bitmapScale(context, sizeDp, sizeCount)

        val box = GlanceModifier.fillMaxSize().let { if (content.transparent) it else it.page() }
        Box(box.clickable(WidgetArt.launch(context, launchUri))) {
            val poster = content.poster?.let { draw { WidgetArt.posterBitmap(context, it, sizeDp, scale) } }
            val glow = content.glow
            if (poster != null) {
                Image(
                        ImageProvider(poster),
                        contentDescription = null,
                        modifier = GlanceModifier.fillMaxSize(),
                        contentScale = ContentScale.FillBounds,
                )
                Box(GlanceModifier.fillMaxSize().wash()) {}
            } else if (glow != null) {
                draw { WidgetArt.glowMask(context, sizeDp) }?.let { Glow(context, it, glow) }
            }

            // If the full-size text can't be allocated, half the pixels still read.
            val text = draw { textBitmap(context, content, sizeDp, scale) }
                    ?: draw { textBitmap(context, content, sizeDp, scale * 0.5f) }
            if (text != null && content.transparent) {
                // Already coloured, with its shadow: shown as it is.
                Image(
                        ImageProvider(text),
                        contentDescription = content.description,
                        modifier = GlanceModifier.fillMaxSize(),
                        contentScale = ContentScale.Fit,
                )
            } else if (text != null) {
                Ink(context, text, content.description)
            } else {
                // Not even that: the quote in the system font, better than an error.
                Text(
                        content.text.body,
                        modifier = GlanceModifier.fillMaxSize().padding(16.dp),
                        style = TextStyle(
                                color = if (content.transparent) {
                                    ColorProvider(Color(WidgetArt.INK_DARK), Color(WidgetArt.INK_DARK))
                                } else {
                                    ColorProvider(Color(WidgetArt.INK_LIGHT), Color(WidgetArt.INK_DARK))
                                },
                                fontSize = 16.sp,
                        ),
                )
            }
        }
    }

    /** The page colour, rounded like the launcher's widgets. */
    private fun GlanceModifier.page(): GlanceModifier =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                background(ColorProvider(Color(WidgetArt.PAGE_LIGHT), Color(WidgetArt.PAGE_DARK)))
                        .cornerRadius(R.dimen.qotd_widget_radius)
            } else {
                background(ImageProvider(R.drawable.qotd_widget_background))
            }

    /** The page colour over the poster, so the type stays readable. */
    private fun GlanceModifier.wash(): GlanceModifier =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                background(ColorProvider(Color(WidgetArt.WASH_LIGHT), Color(WidgetArt.WASH_DARK)))
            } else {
                background(ImageProvider(R.drawable.qotd_widget_wash))
            }

    /** The glow [mask] in today's hue for the system theme. */
    @Composable
    private fun Glow(context: Context, mask: Bitmap, glow: WidgetArt.Glow) {
        val night = WidgetArt.glowNightTint(glow.dark)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Image(
                    ImageProvider(mask),
                    contentDescription = null,
                    modifier = GlanceModifier.fillMaxSize(),
                    contentScale = ContentScale.FillBounds,
                    colorFilter = ColorFilter.tint(ColorProvider(Color(glow.light), Color(night))),
            )
        } else {
            // One mask, tinted once per theme; values-night shows the right one.
            val views = RemoteViews(context.packageName, R.layout.widget_glow_layer)
            views.setImageViewBitmap(R.id.widget_glow_light, mask)
            views.setImageViewBitmap(R.id.widget_glow_dark, mask)
            views.setInt(R.id.widget_glow_light, "setColorFilter", glow.light)
            views.setInt(R.id.widget_glow_dark, "setColorFilter", night)
            AndroidRemoteViews(views, GlanceModifier.fillMaxSize())
        }
    }

    /** The [text] bitmap in ink (parchment at night), read by TalkBack as [description]. */
    @Composable
    private fun Ink(context: Context, text: Bitmap, description: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            Image(
                    ImageProvider(text),
                    contentDescription = description,
                    modifier = GlanceModifier.fillMaxSize(),
                    // Same aspect ratio as the box, so this never stretches.
                    contentScale = ContentScale.Fit,
                    colorFilter = ColorFilter.tint(
                            ColorProvider(Color(WidgetArt.INK_LIGHT), Color(WidgetArt.INK_DARK))),
            )
        } else {
            val views = RemoteViews(context.packageName, R.layout.widget_text_layer)
            views.setImageViewBitmap(R.id.widget_text, text)
            views.setContentDescription(R.id.widget_text, description)
            AndroidRemoteViews(views, GlanceModifier.fillMaxSize())
        }
    }

    /** [block]'s bitmap, or null if it could not be drawn (out of memory, say). */
    private fun draw(block: () -> Bitmap): Bitmap? = try {
        block()
    } catch (e: Exception) {
        null
    } catch (e: OutOfMemoryError) {
        null
    }
}

/**
 * The receiver for an [ArtWidget]. home_widget's Glance receiver: an update
 * from Dart (HomeWidget.updateWidget with this class's name) or from the
 * system renews the widget's [HomeWidgetGlanceState] and redraws it. Also logs
 * the first widget of [kind] placed and the last one removed, for analytics.
 */
abstract class ArtWidgetReceiver<T : ArtWidget> : HomeWidgetGlanceWidgetReceiver<T>() {

    /** QuotelyWidgetKind.id, for analytics. */
    protected abstract val kind: String

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetArt.recordEvent(context, kind, placed = true)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetArt.recordEvent(context, kind, placed = false)
    }
}
