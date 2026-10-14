package com.dayve.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class HaruWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val WIDGET_PREFERENCES = "HomeWidgetPreferences"
        private const val MEDIUM_HEIGHT_DP = 110
        private const val LARGE_HEIGHT_DP = 230
    }

    private val progressCatIds = intArrayOf(
        R.id.widget_progress_cat_0,
        R.id.widget_progress_cat_1,
        R.id.widget_progress_cat_2,
        R.id.widget_progress_cat_3,
        R.id.widget_progress_cat_4,
        R.id.widget_progress_cat_5,
        R.id.widget_progress_cat_6,
        R.id.widget_progress_cat_7,
        R.id.widget_progress_cat_8,
        R.id.widget_progress_cat_9,
        R.id.widget_progress_cat_10,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val rawSnapshot = widgetData.getString("widget_snapshot", null)
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(
                widgetId,
                responsiveViews(context, appWidgetManager, widgetId, rawSnapshot),
            )
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val widgetData = context.getSharedPreferences(
            WIDGET_PREFERENCES,
            Context.MODE_PRIVATE,
        )
        val rawSnapshot = widgetData.getString("widget_snapshot", null)
        appWidgetManager.updateAppWidget(
            appWidgetId,
            responsiveViews(context, appWidgetManager, appWidgetId, rawSnapshot),
        )
    }

    private fun responsiveViews(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        rawSnapshot: String?,
    ): RemoteViews {
        val medium = createViews(context, R.layout.haru_widget_medium, rawSnapshot)
        val large = createViews(context, R.layout.haru_widget_large, rawSnapshot)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return RemoteViews(
                mapOf(
                    SizeF(250f, MEDIUM_HEIGHT_DP.toFloat()) to medium,
                    SizeF(250f, LARGE_HEIGHT_DP.toFloat()) to large,
                ),
            )
        }

        val minHeight = appWidgetManager.getAppWidgetOptions(widgetId)
            .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
        return if (minHeight >= LARGE_HEIGHT_DP) large else medium
    }

    private fun createViews(
        context: Context,
        layoutId: Int,
        rawSnapshot: String?,
    ): RemoteViews {
        return RemoteViews(context.packageName, layoutId).also { views ->
            bindSnapshot(
                context,
                views,
                rawSnapshot,
                compact = layoutId == R.layout.haru_widget_medium,
            )
            bindActions(context, views)
        }
    }

    private fun bindSnapshot(
        context: Context,
        views: RemoteViews,
        rawSnapshot: String?,
        compact: Boolean,
    ) {
        if (rawSnapshot.isNullOrBlank()) {
            bindEmpty(views, "앱을 열어 하루를 시작해 주세요", "아직 저장된 정보가 없어요")
            return
        }

        runCatching { JSONObject(rawSnapshot) }
            .onSuccess { snapshot ->
                val validUntil = snapshot.optLong("validUntilEpochMillis", 0L)
                if (validUntil > 0L && System.currentTimeMillis() >= validUntil) {
                    bindStale(views)
                    requestFlutterRefresh(context)
                    return@onSuccess
                }

                views.setTextViewText(R.id.widget_state, snapshot.optString("stateLabel"))
                views.setTextViewText(R.id.widget_headline, snapshot.optString("headline"))

                val state = snapshot.optString("state")
                val showProgress = state == "working" || state == "afterWork"
                views.setViewVisibility(
                    R.id.widget_progress_section,
                    if (showProgress) View.VISIBLE else View.GONE,
                )
                if (showProgress) {
                    val progressPercent = snapshot.optInt("progressPercent", 0)
                        .coerceIn(0, 100)
                    views.setTextViewText(R.id.widget_progress_percent, "$progressPercent%")
                    views.setProgressBar(
                        R.id.widget_progress,
                        100,
                        progressPercent,
                        false,
                    )
                    bindCatPosition(
                        context,
                        views,
                        progressPercent,
                        catSizeDp = if (compact) 34f else 40f,
                        minimumTrackWidthDp = if (compact) {
                            PixelCatPosition.MEDIUM_WIDGET_MIN_TRACK_DP
                        } else {
                            PixelCatPosition.LARGE_WIDGET_MIN_TRACK_DP
                        },
                    )
                    views.setTextViewText(
                        R.id.widget_progress_leading,
                        snapshot.optString("progressLeadingLabel"),
                    )
                    views.setTextViewText(
                        R.id.widget_progress_trailing,
                        snapshot.optString("progressTrailingLabel"),
                    )
                }

                val usagePercent = snapshot.optInt("monthlyUsagePercent", 0)
                    .coerceIn(0, 100)
                views.setViewVisibility(R.id.widget_section_divider, View.VISIBLE)
                views.setViewVisibility(R.id.widget_budget_section, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_monthly_usage,
                    snapshot.optString("monthlyUsageLabel", "이번 달 0% 사용 중"),
                )
                views.setTextViewText(
                    R.id.widget_monthly_spent,
                    snapshot.optString("monthlySpentLabel", "0원"),
                )
                views.setTextViewText(
                    R.id.widget_monthly_budget,
                    displayAmount(
                        "예산",
                        snapshot.optString("monthlyBudgetLabel", "0원"),
                        compact,
                    ),
                )
                views.setTextViewText(
                    R.id.widget_monthly_remaining,
                    displayAmount(
                        "남음",
                        snapshot.optString(
                            "monthlyRemainingLabel",
                            snapshot.optString("remainingBudgetLabel", "0원"),
                        ),
                        compact,
                    ),
                )
                views.setProgressBar(
                    R.id.widget_monthly_progress,
                    100,
                    usagePercent,
                    false,
                )
                views.setTextViewText(R.id.widget_updated, snapshot.optString("updatedLabel"))
            }
            .onFailure {
                bindEmpty(
                    views,
                    "위젯 정보를 새로고침해 주세요",
                    "저장된 정보를 읽을 수 없어요",
                )
            }
    }

    private fun displayAmount(prefix: String, amount: String, compact: Boolean): String {
        return if (compact) "$prefix $amount" else amount
    }

    private fun bindCatPosition(
        context: Context,
        views: RemoteViews,
        progressPercent: Int,
        catSizeDp: Float,
        minimumTrackWidthDp: Float,
    ) {
        val selected = PixelCatPosition.indexFor(progressPercent)
        val density = context.resources.displayMetrics.density
        progressCatIds.forEachIndexed { index, viewId ->
            val translationPx = PixelCatPosition.translationDpFor(
                index,
                catSizeDp,
                minimumTrackWidthDp,
            ) * density
            views.setFloat(viewId, "setTranslationX", translationPx)
            views.setViewVisibility(
                viewId,
                if (index == selected) View.VISIBLE else View.GONE,
            )
        }
    }

    private fun bindEmpty(views: RemoteViews, headline: String, updated: String) {
        views.setTextViewText(R.id.widget_state, "DAYVE")
        views.setTextViewText(R.id.widget_headline, headline)
        views.setViewVisibility(R.id.widget_section_divider, View.GONE)
        views.setViewVisibility(R.id.widget_budget_section, View.GONE)
        views.setViewVisibility(R.id.widget_progress_section, View.GONE)
        views.setTextViewText(R.id.widget_updated, updated)
    }

    private fun bindStale(views: RemoteViews) {
        bindEmpty(
            views,
            "최신 정보를 불러오고 있어요",
            "이전 날짜 정보는 숨겼어요",
        )
        views.setTextViewText(R.id.widget_state, "DAYVE · 갱신 중")
    }

    private fun requestFlutterRefresh(context: Context) {
        runCatching {
            HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("haru://refresh/stale"),
            ).send()
        }
    }

    private fun bindActions(context: Context, views: RemoteViews) {
        val homeIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("haru://widget/home"),
        )
        val spendIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("haru://widget/spend"),
        )
        val scheduleIntent = HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("haru://widget/schedule"),
        )
        views.setOnClickPendingIntent(R.id.widget_spend_action, spendIntent)
        views.setOnClickPendingIntent(R.id.widget_schedule_action, scheduleIntent)
        views.setOnClickPendingIntent(R.id.widget_root, homeIntent)
    }
}
