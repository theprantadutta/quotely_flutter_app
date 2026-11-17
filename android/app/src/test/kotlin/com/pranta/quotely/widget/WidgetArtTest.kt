package com.pranta.quotely.widget

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

/** The parts of [WidgetArt] that are plain arithmetic (no Android framework). */
class WidgetArtTest {

    /** Blends [over] onto [under] with [alpha] (0..1), per channel, like SRC_OVER. */
    private fun over(under: Int, over: Int, alpha: Float): IntArray = intArrayOf(16, 8, 0).map {
        val u = (under shr it) and 0xFF
        val o = (over shr it) and 0xFF
        u * (1 - alpha) + o * alpha
    }.map { Math.round(it) }.toIntArray()

    @Test
    fun mixIsOpaqueAndHitsBothEnds() {
        val a = 0xFF102030.toInt()
        val b = 0x80F0E0D0.toInt()
        assertEquals(0xFF102030.toInt(), WidgetArt.mix(a, b, 0f))
        assertEquals(0xFFF0E0D0.toInt(), WidgetArt.mix(a, b, 1f))
        assertEquals(0xFF808080.toInt(), WidgetArt.mix(a, b, 0.5f))
    }

    @Test
    fun nightGlowTintGivesTheNightStrengthOnTheNightPage() {
        // The mask carries paper's k (0.5); at night the app paints k = 0.34.
        // The tinted mask over the night page must match the night hue at
        // 0.34 / 0.5 of the mask's alpha, for any alpha the mask has.
        val hue = 0xFFC0643F.toInt()
        val tint = WidgetArt.glowNightTint(hue)
        for (alpha in listOf(0.05f, 0.2f, 0.35f, 0.5f)) {
            val drawn = over(WidgetArt.PAGE_DARK, tint, alpha)
            val wanted = over(WidgetArt.PAGE_DARK, hue, alpha * 0.34f / 0.5f)
            for (c in 0..2) {
                assertTrue("alpha $alpha channel $c: ${drawn[c]} vs ${wanted[c]}",
                        abs(drawn[c] - wanted[c]) <= 1)
            }
        }
    }

    @Test
    fun bitmapsKeepTheBoxAspectRatio() {
        // Typical launcher sizes (dp) at common densities and budget scales.
        val boxes = listOf(250f to 110f, 110f to 110f, 320f to 180f, 411f to 257f, 180.5f to 73.25f)
        val scales = listOf(1f, 1.5f, 2.625f, 3f, 3.5f, 2.1f * 0.8f)
        for ((w, h) in boxes) {
            for (pxPerDp in scales) {
                val (pw, ph) = WidgetArt.pixelSize(w, h, pxPerDp)
                // Within one pixel of the exact size on each side, so a
                // ContentScale.Fit image fills the box to within a pixel.
                assertTrue(abs(pw - w * pxPerDp) <= 0.5f)
                assertTrue(abs(ph - h * pxPerDp) <= 0.5f)
            }
        }
    }

    @Test
    fun theSmallSquareIsCompactOnlyAtOneByOne() {
        // 1x1 on phones (~40-80dp) shows the mark alone; 2x2 (110dp+) the line.
        assertTrue(40f < WidgetArt.SQUARE_COMPACT_DP)
        assertTrue(80f < WidgetArt.SQUARE_COMPACT_DP)
        assertTrue(110f >= WidgetArt.SQUARE_COMPACT_DP)
    }

    @Test
    fun minimalBackgroundFlagIsPerWidget() {
        assertEquals("minimal_clear_42", MinimalQuoteWidget.clearKey(42))
        assertTrue(MinimalQuoteWidget.clearKey(1) != MinimalQuoteWidget.clearKey(11))
    }

    @Test
    fun pixelSizeIsNeverEmpty() {
        assertEquals(1 to 1, WidgetArt.pixelSize(0f, 0f, 3f))
    }
}
