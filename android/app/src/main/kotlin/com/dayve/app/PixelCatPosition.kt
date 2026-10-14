package com.dayve.app

import kotlin.math.roundToInt

internal object PixelCatPosition {
    const val PAW_ANCHOR_RATIO = 0.84f
    const val POSITION_STEPS = 10
    const val MEDIUM_WIDGET_MIN_TRACK_DP = 226f
    const val LARGE_WIDGET_MIN_TRACK_DP = 222f
    const val NOTIFICATION_MIN_TRACK_DP = 280f

    fun indexFor(progressPercent: Int): Int {
        return (progressPercent.coerceIn(0, 100) / 10.0)
            .roundToInt()
            .coerceIn(0, POSITION_STEPS)
    }

    fun translationDpFor(
        positionIndex: Int,
        catSizeDp: Float,
        minimumTrackWidthDp: Float,
    ): Float {
        val index = positionIndex.coerceIn(0, POSITION_STEPS)
        val progress = index.toFloat() / POSITION_STEPS
        val trackWidth = minimumTrackWidthDp.coerceAtLeast(catSizeDp)
        val travel = (trackWidth - catSizeDp).coerceAtLeast(0f)
        val slotLeft = travel * progress
        val progressEnd = trackWidth * progress
        val anchoredLeft = (progressEnd - catSizeDp * PAW_ANCHOR_RATIO)
            .coerceIn(0f, travel)
        return anchoredLeft - slotLeft
    }
}
