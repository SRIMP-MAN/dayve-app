package com.dayve.app

import org.junit.Assert.assertEquals
import org.junit.Test

class PixelCatPositionTest {
    @Test
    fun `quantizes supported progress values from the same source`() {
        val progressValues = listOf(0, 10, 25, 50, 75, 90, 100)
        val expected = listOf(0, 1, 3, 5, 8, 9, 10)

        assertEquals(expected, progressValues.map(PixelCatPosition::indexFor))
    }

    @Test
    fun `uses the paw anchor for interior positions and clamps both ends`() {
        val catSizeDp = 40f
        val trackWidthDp = 240f

        assertEquals(0f, PixelCatPosition.translationDpFor(0, catSizeDp, trackWidthDp), 0.001f)
        assertEquals(-20f, PixelCatPosition.translationDpFor(1, catSizeDp, trackWidthDp), 0.001f)
        assertEquals(-21.6f, PixelCatPosition.translationDpFor(3, catSizeDp, trackWidthDp), 0.001f)
        assertEquals(-13.6f, PixelCatPosition.translationDpFor(5, catSizeDp, trackWidthDp), 0.001f)
        assertEquals(-1.6f, PixelCatPosition.translationDpFor(8, catSizeDp, trackWidthDp), 0.001f)
        assertEquals(2.4f, PixelCatPosition.translationDpFor(9, catSizeDp, trackWidthDp), 0.001f)
        assertEquals(0f, PixelCatPosition.translationDpFor(10, catSizeDp, trackWidthDp), 0.001f)
    }

    @Test
    fun `clamps progress and position inputs`() {
        assertEquals(0, PixelCatPosition.indexFor(-20))
        assertEquals(10, PixelCatPosition.indexFor(140))
        assertEquals(0f, PixelCatPosition.translationDpFor(-2, 40f, 240f), 0.001f)
        assertEquals(0f, PixelCatPosition.translationDpFor(12, 40f, 240f), 0.001f)
    }
}
