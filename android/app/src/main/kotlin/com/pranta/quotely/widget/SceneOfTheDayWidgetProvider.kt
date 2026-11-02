package com.pranta.quotely.widget

import android.content.Context
import android.content.SharedPreferences
import com.pranta.quotely.R

/**
 * The "Scene of the Day" home-screen widget: today's scene line, with
 * "SCENE · <TITLE>" above it and the character and title below, over the
 * title's poster blurred and washed exactly as Quote of the Day's is.
 *
 * The app (SceneWidgetService in Dart) saves the scene and picks the poster:
 * the scene's own, else the app's fallback backdrop poster, else none, in
 * which case this draws the page with the day's glow. It never clears a
 * saved scene, so offline the widget keeps the last one.
 *
 * A tap opens Today, where the scene is.
 */
class SceneOfTheDayWidgetProvider : ArtWidgetProvider() {

    override val kind = "scene"
    override val launchUri = "quotely://widget/home?homeWidget&kind=scene"

    override fun content(context: Context, data: SharedPreferences): Content {
        val glow = WidgetArt.glowToday(data)
        val text = data.getString(KEY_TEXT, null)?.trim().orEmpty()
        val eyebrow = data.getString(KEY_EYEBROW, null)?.trim()?.ifEmpty { null }
                ?: context.getString(R.string.scene_widget_eyebrow)
        if (text.isEmpty()) {
            val hint = context.getString(R.string.scene_widget_empty)
            return Content(WidgetArt.Text(eyebrow, hint, null), hint, null, glow)
        }
        val character = data.getString(KEY_CHARACTER, null)?.trim().orEmpty()
        val title = data.getString(KEY_TITLE, null)?.trim().orEmpty()
        val footer = when {
            character.isNotEmpty() && title.isNotEmpty() ->
                context.getString(R.string.scene_widget_footer, character, title)
            else -> character.ifEmpty { title }.ifEmpty { null }
        }
        val description = if (character.isNotEmpty() && title.isNotEmpty()) {
            context.getString(R.string.scene_widget_a11y, text, character, title)
        } else {
            context.getString(R.string.scene_widget_a11y_short, listOfNotNull(text, footer).joinToString(" — "))
        }
        return Content(
                WidgetArt.Text(eyebrow, text, footer),
                description,
                WidgetArt.loadPoster(data, KEY_POSTER),
                glow,
        )
    }

    companion object {
        // Keep in sync with SceneWidgetService (lib/services/scene_widget_service.dart).
        private const val KEY_EYEBROW = "scene_eyebrow"
        private const val KEY_TEXT = "scene_text"
        private const val KEY_CHARACTER = "scene_character"
        private const val KEY_TITLE = "scene_title"
        private const val KEY_POSTER = "scene_poster"
    }
}
