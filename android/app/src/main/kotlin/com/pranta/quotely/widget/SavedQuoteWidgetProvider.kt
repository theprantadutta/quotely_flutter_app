package com.pranta.quotely.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import com.pranta.quotely.R
import org.json.JSONObject
import java.time.LocalDate
import java.time.ZoneId

/**
 * The "From your saved" home-screen widget: one of the person's own saved
 * quotes, a different one each day, over the page with the day's glow.
 * Entirely offline.
 *
 * The app (SavedWidgetService in Dart) saves the picks for the next 30 days,
 * so the quote can turn over at midnight without the app: this only indexes
 * today into them, wrapping round if the app hasn't run for longer. It
 * redraws at the first moment the device is awake after local midnight,
 * through an inexact, non-waking alarm (no WorkManager, no exact-alarm
 * permission), re-armed on every update. Reboots are covered because the
 * system sends every widget an update after boot.
 *
 * A tap opens the Saved tab.
 */
class SavedQuoteWidgetProvider : ArtWidgetProvider() {

    override val kind = "saved"
    override val launchUri = "quotely://widget/saved?homeWidget&kind=saved"

    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
            widgetData: SharedPreferences,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds, widgetData)
        scheduleMidnight(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        try {
            context.getSystemService(AlarmManager::class.java)?.cancel(midnightIntent(context))
        } catch (e: Exception) {
            // Nothing scheduled.
        }
    }

    override fun content(context: Context, data: SharedPreferences): Content {
        val glow = WidgetArt.glowToday(data)
        val eyebrow = context.getString(R.string.saved_widget_eyebrow)
        val pick = if (data.getInt(KEY_COUNT, 0) > 0) todaysPick(data) else null
        if (pick == null) {
            val hint = context.getString(R.string.saved_widget_empty)
            return Content(WidgetArt.Text(eyebrow, hint, null), hint, null, glow)
        }
        val (text, author) = pick
        val description = if (author.isEmpty()) {
            context.getString(R.string.saved_widget_a11y, text)
        } else {
            context.getString(R.string.saved_widget_a11y_author, text, author)
        }
        return Content(WidgetArt.Text(eyebrow, text, author.ifEmpty { null }), description, null, glow)
    }

    /** Today's saved quote and its author, or null if there is none. */
    private fun todaysPick(data: SharedPreferences): Pair<String, String>? = try {
        val json = JSONObject(data.getString(KEY_DAYS, null) ?: "{}")
        val quotes = json.getJSONArray("quotes")
        if (quotes.length() == 0) {
            null
        } else {
            val i = Math.floorMod(WidgetArt.daysSince(json.getString("start")), quotes.length())
            val q = quotes.getJSONObject(i)
            val text = q.optString("t").trim()
            if (text.isEmpty()) null else text to q.optString("a").trim()
        }
    } catch (e: Exception) {
        null
    }

    /** Redraw once the day has turned (a minute past midnight, inexact). */
    private fun scheduleMidnight(context: Context) {
        try {
            val alarms = context.getSystemService(AlarmManager::class.java) ?: return
            val zone = ZoneId.systemDefault()
            val next = LocalDate.now(zone).plusDays(1).atStartOfDay(zone).plusMinutes(1)
            alarms.set(AlarmManager.RTC, next.toInstant().toEpochMilli(), midnightIntent(context))
        } catch (e: Exception) {
            // The next app run or system update redraws it instead.
        }
    }

    private fun midnightIntent(context: Context): PendingIntent {
        val component = ComponentName(context, SavedQuoteWidgetProvider::class.java)
        val ids = AppWidgetManager.getInstance(context).getAppWidgetIds(component)
        val intent = Intent(context, SavedQuoteWidgetProvider::class.java)
                .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        return PendingIntent.getBroadcast(
                context, MIDNIGHT_REQUEST, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    companion object {
        // Keep in sync with SavedWidgetService (lib/services/saved_widget_service.dart).
        private const val KEY_DAYS = "saved_days"
        private const val KEY_COUNT = "saved_count"

        private const val MIDNIGHT_REQUEST = 7401
    }
}
