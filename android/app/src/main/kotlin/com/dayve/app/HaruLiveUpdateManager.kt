package com.dayve.app

import android.Manifest
import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

class HaruLiveUpdateManager(private val context: Context) {
    companion object {
        const val ACTION_APPLY = "com.dayve.app.action.APPLY_LIVE_UPDATE"
        const val EXTRA_SNAPSHOT = "snapshot"

        private const val CHANNEL_ID = "haru_live_update"
        private const val NOTIFICATION_ID = 1100
        private const val PREFS = "haru_live_update"
        private const val PLAN_KEY = "flutter_generated_plan"
        private const val ALARM_COUNT_KEY = "alarm_count"
        private const val ALARM_REQUEST_CODE = 7100
        const val EXTRA_LIVE_ACTION = "haru_live_action"
        const val EXTRA_SCHEDULE_DATE = "haru_schedule_date"
    }

    private val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    private val catPositionIds = intArrayOf(
        R.id.notification_cat_position_0,
        R.id.notification_cat_position_1,
        R.id.notification_cat_position_2,
        R.id.notification_cat_position_3,
        R.id.notification_cat_position_4,
        R.id.notification_cat_position_5,
        R.id.notification_cat_position_6,
        R.id.notification_cat_position_7,
        R.id.notification_cat_position_8,
        R.id.notification_cat_position_9,
        R.id.notification_cat_position_10,
    )

    fun sync(arguments: Any?): Map<String, Any> {
        val plan = asJsonObject(arguments) ?: return capability("unsupported")
        preferences.edit().putString(PLAN_KEY, plan.toString()).apply()
        cancelTransitionAlarms()

        val current = plan.optJSONObject("current")
        val currentSnapshot = current?.optJSONObject("snapshot")
        val mode = if (currentSnapshot == null) {
            cancelNotification()
            "hidden"
        } else {
            render(currentSnapshot)
        }
        scheduleFutureTransitions(plan.optJSONArray("transitions") ?: JSONArray())
        return capability(mode)
    }

    fun disable(): Map<String, Any> {
        cancelTransitionAlarms()
        cancelNotification()
        preferences.edit().remove(PLAN_KEY).apply()
        return capability("hidden")
    }

    fun restore() {
        val raw = preferences.getString(PLAN_KEY, null) ?: return
        val plan = runCatching { JSONObject(raw) }.getOrNull() ?: return
        cancelTransitionAlarms()

        val now = System.currentTimeMillis()
        var applicable = plan.optJSONObject("current")
        val transitions = plan.optJSONArray("transitions") ?: JSONArray()
        for (index in 0 until transitions.length()) {
            val command = transitions.optJSONObject(index) ?: continue
            if (command.optLong("executeAtMillis", Long.MAX_VALUE) <= now) {
                applicable = command
            }
        }
        applicable?.optJSONObject("snapshot")?.let(::render) ?: cancelNotification()
        scheduleFutureTransitions(transitions)
    }

    fun applySerializedSnapshot(raw: String?) {
        val snapshot = raw?.let { runCatching { JSONObject(it) }.getOrNull() } ?: return
        render(snapshot)
    }

    fun capability(mode: String? = null): Map<String, Any> {
        val resolvedMode = mode ?: if (notificationsEnabled()) "standard" else "unsupported"
        return mapOf(
            "mode" to resolvedMode,
            "androidApi" to Build.VERSION.SDK_INT,
            "supportsLiveUpdate" to notificationsEnabled(),
            "canPromote" to false,
            "notificationsEnabled" to notificationsEnabled(),
        )
    }

    fun openPromotionSettings(): Boolean = false

    fun openNotificationSettings(): Boolean {
        return openSettingsIntent(notificationSettingsIntent())
    }

    fun openLockScreenSettings(): Boolean {
        return openSettingsIntent(notificationSettingsIntent())
    }

    private fun render(snapshot: JSONObject): String {
        val visible = snapshot.optBoolean("visible", false)
        val endsAt = if (snapshot.has("endTimeMillis")) {
            snapshot.optLong("endTimeMillis", 0L)
        } else {
            snapshot.optLong("endsAtMillis", 0L)
        }
        if (!visible || endsAt <= System.currentTimeMillis()) {
            cancelNotification()
            return "hidden"
        }
        if (!notificationsEnabled()) {
            cancelNotification()
            return "unsupported"
        }

        createChannel()
        val notification = buildNotification(snapshot, endsAt)
        runCatching { notificationManager.notify(NOTIFICATION_ID, notification) }
            .onFailure {
                cancelNotification()
                return "unsupported"
            }
        return "standard"
    }

    private fun buildNotification(
        snapshot: JSONObject,
        endsAt: Long,
    ): Notification {
        val title = snapshot.optString("title", "DAYVE")
        val headline = snapshot.optString("headline", snapshot.optString("body", ""))
        val progress = snapshot.optInt("progressPercent", 0).coerceIn(0, 100)
        val contentIntent = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            Notification.Builder(context)
        }
            .setSmallIcon(R.drawable.ic_haru_notification)
            .setContentTitle(title)
            .setContentText("$headline · 진행률 $progress%")
            .setContentIntent(contentIntent)
            .setCategory(Notification.CATEGORY_PROGRESS)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(true)
            .setWhen(endsAt)

        if (snapshot.optBoolean("showCheckoutActions", false)) {
            val scheduleDate = snapshot.optString("scheduleDate", "")
            builder.addAction(
                Notification.Action.Builder(
                    null,
                    "퇴근했어",
                    liveActionIntent("checkout", scheduleDate, 7201),
                ).build(),
            )
            builder.addAction(
                Notification.Action.Builder(
                    null,
                    "+30분",
                    liveActionIntent("overtime30", scheduleDate, 7202),
                ).build(),
            )
            builder.addAction(
                Notification.Action.Builder(
                    null,
                    "+1시간",
                    liveActionIntent("overtime60", scheduleDate, 7203),
                ).build(),
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder.setUsesChronometer(true).setChronometerCountDown(true)
        }

        val (collapsed, expanded) = customViews(snapshot, progress)
        builder.setCustomContentView(collapsed)
        builder.setCustomBigContentView(expanded)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder.setStyle(Notification.DecoratedCustomViewStyle())
        }

        val remaining = (endsAt - System.currentTimeMillis()).coerceAtLeast(0L)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setTimeoutAfter(remaining + 10 * 60 * 1000L)
        }
        return builder.build()
    }

    private fun customViews(
        snapshot: JSONObject,
        progress: Int,
    ): Pair<RemoteViews, RemoteViews> {
        val headline = snapshot.optString("headline", snapshot.optString("body", ""))

        val collapsed = RemoteViews(
            context.packageName,
            R.layout.haru_notification_collapsed,
        ).apply {
            setTextViewText(
                R.id.notification_collapsed_title,
                "DAYVE · 오늘의 일과",
            )
            setTextViewText(
                R.id.notification_collapsed_headline,
                "$headline · 진행률 $progress%",
            )
            setTextViewText(R.id.notification_collapsed_percent, "$progress%")
            setProgressBar(
                R.id.notification_collapsed_progress,
                100,
                progress,
                false,
            )
        }

        val expanded = RemoteViews(
            context.packageName,
            R.layout.lockscreen_dayve,
        ).apply {
            setTextViewText(R.id.notification_expanded_percent, "$progress%")
            setTextViewText(
                R.id.notification_expanded_encouragement,
                snapshot.optString("progressTrailingLabel", ""),
            )
            setProgressBar(
                R.id.notification_expanded_progress,
                100,
                progress,
                false,
            )
            bindCatPosition(this, progress)
            setTextViewText(
                R.id.notification_expanded_leading,
                snapshot.optString("progressLeadingLabel", ""),
            )
            setTextViewText(
                R.id.notification_expanded_end,
                headline,
            )
        }
        return collapsed to expanded
    }

    private fun bindCatPosition(views: RemoteViews, progress: Int) {
        val selected = PixelCatPosition.indexFor(progress)
        val density = context.resources.displayMetrics.density
        catPositionIds.forEachIndexed { index, id ->
            val translationPx = PixelCatPosition.translationDpFor(
                index,
                catSizeDp = 40f,
                minimumTrackWidthDp = PixelCatPosition.NOTIFICATION_MIN_TRACK_DP,
            ) * density
            views.setFloat(id, "setTranslationX", translationPx)
            views.setViewVisibility(id, if (index == selected) View.VISIBLE else View.GONE)
        }
    }

    fun diagnostics(): Map<String, Any?> {
        val now = System.currentTimeMillis()
        val plan = preferences.getString(PLAN_KEY, null)
            ?.let { runCatching { JSONObject(it) }.getOrNull() }
        val applicable = applicableCommand(plan, now)
        val snapshot = applicable?.optJSONObject("snapshot")
        val diagnosticSnapshot = snapshot ?: JSONObject().apply {
            put("visible", false)
            put("state", "unknown")
            put("title", "DAYVE · 진단")
            put("headline", "진단용 알림")
            put("progressPercent", 50)
            put("endTimeMillis", now + 60 * 60 * 1000L)
        }
        val endTime = snapshotEndTime(diagnosticSnapshot).takeIf { it > 0L }
            ?: now + 60 * 60 * 1000L
        val built = buildNotification(diagnosticSnapshot, endTime)
        val active = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            runCatching {
                notificationManager.activeNotifications
                    .firstOrNull { it.id == NOTIFICATION_ID }
                    ?.notification
            }.getOrNull()
        } else {
            null
        }
        val sdkFull = sdkIntFull()
        val channel = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationManager.getNotificationChannel(CHANNEL_ID)
        } else {
            null
        }
        val nextRefresh = plan?.optJSONArray("transitions")?.let { transitions ->
            (0 until transitions.length())
                .mapNotNull { transitions.optJSONObject(it) }
                .map { it.optLong("executeAtMillis", 0L) }
                .firstOrNull { it > now }
        }
        val template = built.extras.getString(Notification.EXTRA_TEMPLATE)
        val hasCustomViews = built.contentView != null ||
            built.bigContentView != null || built.headsUpContentView != null
        val title = built.extras.getCharSequence(Notification.EXTRA_TITLE)

        return mapOf(
            "androidVersion" to if (Build.VERSION.SDK_INT >= 33) {
                Build.VERSION.RELEASE_OR_PREVIEW_DISPLAY
            } else {
                Build.VERSION.RELEASE
            },
            "sdkInt" to Build.VERSION.SDK_INT,
            "sdkIntFull" to sdkFull,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            // One UI does not expose a stable public Android API. Intentionally omitted.
            "android16OrAbove" to (Build.VERSION.SDK_INT >= 36),
            "api361OrAbove" to (sdkFull != null && sdkFull >= baklavaOneFullCode()),
            "postNotificationsGranted" to postNotificationsGranted(),
            "notificationsEnabled" to notificationsEnabled(),
            "promotedPermissionDeclared" to promotedPermissionDeclared(),
            "promotedUserAllowed" to false,
            "canPostPromotedNotifications" to false,
            "hasPromotableCharacteristics" to false,
            "currentlyPromoted" to false,
            "ongoing" to ((built.flags and Notification.FLAG_ONGOING_EVENT) != 0),
            "hasContentTitle" to !title.isNullOrBlank(),
            "notificationStyle" to (template
                ?.substringAfterLast('.')
                ?.substringBefore('$') ?: "DAYVE Custom RemoteViews"),
            "progressStyle" to false,
            "customRemoteViews" to hasCustomViews,
            "colorized" to built.extras.getBoolean(Notification.EXTRA_COLORIZED, false),
            "channelId" to CHANNEL_ID,
            "channelImportance" to channel?.importance,
            "channelImportanceLabel" to importanceLabel(channel?.importance),
            "visibility" to visibilityLabel(built.visibility),
            "foregroundService" to (
                (built.flags and Notification.FLAG_FOREGROUND_SERVICE) != 0
            ),
            "currentState" to diagnosticSnapshot.optString("state", "unknown"),
            "liveUpdateActive" to (active != null),
            "headline" to diagnosticSnapshot.optString("headline", ""),
            "progress" to diagnosticSnapshot.optDouble(
                "progress",
                diagnosticSnapshot.optInt("progressPercent", 0) / 100.0,
            ),
            "startTimeMillis" to diagnosticSnapshot.optLong("startTimeMillis", 0L),
            "endTimeMillis" to snapshotEndTime(diagnosticSnapshot),
            "lastUpdatedMillis" to diagnosticSnapshot.optLong("updatedAtMillis", 0L),
            "nextScheduledRefreshMillis" to nextRefresh,
            "canOpenNotificationSettings" to canResolveNotificationSettings(),
            "canOpenLockScreenSettings" to canResolveNotificationSettings(),
            "canOpenPromotionSettings" to false,
        )
    }

    private fun applicableCommand(plan: JSONObject?, now: Long): JSONObject? {
        if (plan == null) return null
        var applicable = plan.optJSONObject("current")
        val transitions = plan.optJSONArray("transitions") ?: return applicable
        for (index in 0 until transitions.length()) {
            val command = transitions.optJSONObject(index) ?: continue
            if (command.optLong("executeAtMillis", Long.MAX_VALUE) <= now) {
                applicable = command
            }
        }
        return applicable
    }

    private fun snapshotEndTime(snapshot: JSONObject): Long {
        return if (snapshot.has("endTimeMillis")) {
            snapshot.optLong("endTimeMillis", 0L)
        } else {
            snapshot.optLong("endsAtMillis", 0L)
        }
    }

    private fun sdkIntFull(): Int? {
        if (Build.VERSION.SDK_INT < 36) return null
        return runCatching {
            Build.VERSION::class.java.getField("SDK_INT_FULL").getInt(null)
        }.getOrNull()
    }

    private fun baklavaOneFullCode(): Int {
        return runCatching {
            Class.forName("android.os.Build\$VERSION_CODES_FULL")
                .getField("BAKLAVA_1")
                .getInt(null)
        }.getOrDefault(3_600_001)
    }

    private fun promotedPermissionDeclared(): Boolean {
        val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.packageManager.getPackageInfo(
                context.packageName,
                PackageManager.PackageInfoFlags.of(
                    PackageManager.GET_PERMISSIONS.toLong(),
                ),
            )
        } else {
            @Suppress("DEPRECATION")
            context.packageManager.getPackageInfo(
                context.packageName,
                PackageManager.GET_PERMISSIONS,
            )
        }
        return info.requestedPermissions?.contains(
            "android.permission.POST_PROMOTED_NOTIFICATIONS",
        ) == true
    }

    private fun postNotificationsGranted(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun importanceLabel(importance: Int?): String = when (importance) {
        NotificationManager.IMPORTANCE_NONE -> "NONE"
        NotificationManager.IMPORTANCE_MIN -> "MIN"
        NotificationManager.IMPORTANCE_LOW -> "LOW"
        NotificationManager.IMPORTANCE_DEFAULT -> "DEFAULT"
        NotificationManager.IMPORTANCE_HIGH -> "HIGH"
        null -> "NOT_CREATED"
        else -> importance.toString()
    }

    private fun visibilityLabel(visibility: Int): String = when (visibility) {
        Notification.VISIBILITY_PUBLIC -> "PUBLIC"
        Notification.VISIBILITY_PRIVATE -> "PRIVATE"
        Notification.VISIBILITY_SECRET -> "SECRET"
        else -> "UNKNOWN"
    }

    private fun canResolveNotificationSettings(): Boolean {
        return canResolve(notificationSettingsIntent())
    }

    private fun notificationSettingsIntent(): Intent {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            }
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:${context.packageName}")
            }
        }
    }

    private fun canResolve(intent: Intent): Boolean =
        intent.resolveActivity(context.packageManager) != null

    private fun openSettingsIntent(intent: Intent): Boolean {
        if (!canResolve(intent)) return false
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        return true
    }

    private fun liveActionIntent(
        action: String,
        scheduleDate: String,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            this.action = "com.dayve.app.action.LIVE_UPDATE_$action"
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(EXTRA_LIVE_ACTION, action)
            putExtra(EXTRA_SCHEDULE_DATE, scheduleDate)
        }
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun scheduleFutureTransitions(transitions: JSONArray) {
        val now = System.currentTimeMillis()
        var scheduledCount = 0
        for (index in 0 until transitions.length()) {
            val command = transitions.optJSONObject(index) ?: continue
            val executeAt = command.optLong("executeAtMillis", 0L)
            val snapshot = command.optJSONObject("snapshot") ?: continue
            if (executeAt <= now) continue
            val intent = Intent(context, HaruLiveUpdateReceiver::class.java).apply {
                action = ACTION_APPLY
                putExtra(EXTRA_SNAPSHOT, snapshot.toString())
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                ALARM_REQUEST_CODE + scheduledCount,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    executeAt,
                    pendingIntent,
                )
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, executeAt, pendingIntent)
            }
            scheduledCount += 1
        }
        preferences.edit().putInt(ALARM_COUNT_KEY, scheduledCount).apply()
    }

    private fun cancelTransitionAlarms() {
        val count = preferences.getInt(ALARM_COUNT_KEY, 0)
        for (index in 0 until count) {
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                ALARM_REQUEST_CODE + index,
                Intent(context, HaruLiveUpdateReceiver::class.java).apply {
                    action = ACTION_APPLY
                },
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
            )
            if (pendingIntent != null) alarmManager.cancel(pendingIntent)
        }
        preferences.edit().putInt(ALARM_COUNT_KEY, 0).apply()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "DAYVE 실시간 상태",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "근무와 퇴근 후 남은 시간을 표시합니다."
            setSound(null, null)
            enableVibration(false)
        }
        notificationManager.createNotificationChannel(channel)
    }

    private fun notificationsEnabled(): Boolean {
        if (!notificationManager.areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = notificationManager.getNotificationChannel(CHANNEL_ID)
            if (channel != null && channel.importance == NotificationManager.IMPORTANCE_NONE) {
                return false
            }
        }
        return true
    }

    private fun cancelNotification() {
        notificationManager.cancel(NOTIFICATION_ID)
    }

    private fun asJsonObject(value: Any?): JSONObject? {
        @Suppress("UNCHECKED_CAST")
        return when (value) {
            is Map<*, *> -> JSONObject(value as Map<String, Any?>)
            is String -> runCatching { JSONObject(value) }.getOrNull()
            else -> null
        }
    }
}
