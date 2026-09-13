package com.haruapp.haru_app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

class HaruWidgetProvider : HomeWidgetProvider() {
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
            val views = RemoteViews(context.packageName, R.layout.haru_widget_medium)
            bindSnapshot(context, views, rawSnapshot)
            bindActions(context, views)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindSnapshot(
        context: Context,
        views: RemoteViews,
        rawSnapshot: String?,
    ) {
        if (rawSnapshot.isNullOrBlank()) {
            views.setTextViewText(R.id.widget_state, "HARU")
            views.setTextViewText(R.id.widget_headline, "앱을 열어 하루를 시작해 주세요")
            views.setViewVisibility(R.id.widget_budget_section, View.GONE)
            views.setViewVisibility(R.id.widget_progress_section, View.GONE)
            views.setTextViewText(R.id.widget_updated, "아직 저장된 정보가 없어요")
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
                if (showProgress) {
                    val progress = snapshot.optDouble("progress", 0.0).coerceIn(0.0, 1.0)
                    views.setViewVisibility(R.id.widget_progress_section, View.VISIBLE)
                    views.setProgressBar(R.id.widget_progress, 1000, (progress * 1000).toInt(), false)
                    val catIndex = (progress * (progressCatIds.size - 1)).toInt()
                    progressCatIds.forEachIndexed { index, viewId ->
                        views.setViewVisibility(
                            viewId,
                            if (index == catIndex) View.VISIBLE else View.INVISIBLE,
                        )
                    }
                } else {
                    views.setViewVisibility(R.id.widget_progress_section, View.GONE)
                }
                views.setTextViewText(R.id.widget_daily_budget, snapshot.optString("budgetAmountLabel"))
                views.setTextViewText(
                    R.id.widget_monthly_budget,
                    snapshot.optString("remainingBudgetLabel"),
                )
                views.setViewVisibility(R.id.widget_budget_section, View.VISIBLE)
                views.setTextViewText(R.id.widget_updated, snapshot.optString("updatedLabel"))
            }
            .onFailure {
                views.setTextViewText(R.id.widget_state, "HARU")
                views.setTextViewText(R.id.widget_headline, "위젯 정보를 새로고침해 주세요")
                views.setViewVisibility(R.id.widget_budget_section, View.GONE)
                views.setViewVisibility(R.id.widget_progress_section, View.GONE)
                views.setTextViewText(R.id.widget_updated, "저장된 정보를 읽을 수 없어요")
            }
    }

    private fun bindStale(views: RemoteViews) {
        views.setTextViewText(R.id.widget_state, "HARU · 갱신 중")
        views.setTextViewText(R.id.widget_headline, "최신 정보를 불러오고 있어요")
        views.setViewVisibility(R.id.widget_budget_section, View.GONE)
        views.setViewVisibility(R.id.widget_progress_section, View.GONE)
        views.setTextViewText(R.id.widget_updated, "이전 날짜 정보는 숨겼어요")
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
        views.setOnClickPendingIntent(R.id.widget_root, scheduleIntent)
    }
}
