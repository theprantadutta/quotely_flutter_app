package com.pranta.quotely.widget

import android.app.Activity
import android.app.AlertDialog
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.content.res.Configuration
import android.os.Bundle
import com.pranta.quotely.R
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * The Minimal quote widget's one setting: the page (default) or a
 * transparent background. A small dialog, not a Flutter screen, so it opens
 * instantly from the launcher.
 *
 * On Android 12+ the widget is placed with the page straight away
 * (`configuration_optional`) and this opens from the launcher's widget
 * settings (`reconfigurable`). Before Android 12 the launcher opens it when
 * the widget is placed; any way out of it (even back) keeps the widget, with
 * the page unless "Transparent" was chosen.
 */
class MinimalWidgetConfigureActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        appWidgetId = intent?.extras?.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
                ?: AppWidgetManager.INVALID_APPWIDGET_ID
        // Only our own Minimal widgets: this activity is exported for the launcher.
        val provider = try {
            AppWidgetManager.getInstance(this).getAppWidgetInfo(appWidgetId)?.provider
        } catch (e: Exception) {
            null
        }
        if (provider != ComponentName(this, MinimalQuoteWidgetProvider::class.java)) {
            setResult(RESULT_CANCELED)
            finish()
            return
        }
        // Placing the widget succeeds however this is left.
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId))

        val prefs = HomeWidgetPlugin.getData(this)
        val key = MinimalQuoteWidget.clearKey(appWidgetId)
        val current = if (prefs.getBoolean(key, false)) 1 else 0
        val night = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                Configuration.UI_MODE_NIGHT_YES
        val theme = if (night) {
            android.R.style.Theme_DeviceDefault_Dialog_Alert
        } else {
            android.R.style.Theme_DeviceDefault_Light_Dialog_Alert
        }
        AlertDialog.Builder(this, theme)
                .setTitle(R.string.minimal_widget_configure_title)
                .setSingleChoiceItems(
                        arrayOf(
                                getString(R.string.minimal_widget_background_page),
                                getString(R.string.minimal_widget_background_clear),
                        ),
                        current,
                ) { dialog, which ->
                    prefs.edit().putBoolean(key, which == 1).apply()
                    redraw()
                    dialog.dismiss()
                }
                .setOnDismissListener { finish() }
                .show()
    }

    /** Redraws this widget (the receiver's update renews its state). */
    private fun redraw() {
        val update = Intent(this, MinimalQuoteWidgetProvider::class.java)
                .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        sendBroadcast(update)
    }
}
