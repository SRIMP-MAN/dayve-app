package com.haruapp.haru_app

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.CalendarContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val calendarChannel = "haru/calendar"
    private val liveUpdateChannel = "haru/live_update"
    private val calendarPermissionRequest = 4201
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, calendarChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> requestCalendarPermission(result)
                    "writableCalendars" -> result.success(writableCalendars())
                    "addEvent" -> result.success(
                        addEvent(
                            calendarId = call.argument<String>("calendarId"),
                            title = call.argument<String>("title"),
                            startMillis = call.argument<Number>("startMillis")?.toLong(),
                            endMillis = call.argument<Number>("endMillis")?.toLong(),
                        ),
                    )
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, liveUpdateChannel)
            .setMethodCallHandler { call, result ->
                val manager = HaruLiveUpdateManager(applicationContext)
                when (call.method) {
                    "sync" -> result.success(manager.sync(call.arguments))
                    "disable" -> result.success(manager.disable())
                    "capability" -> result.success(manager.capability())
                    "openPromotionSettings" ->
                        result.success(manager.openPromotionSettings())
                    "openNotificationSettings" ->
                        result.success(manager.openNotificationSettings())
                    "openLockScreenSettings" ->
                        result.success(manager.openLockScreenSettings())
                    "diagnostics" -> result.success(manager.diagnostics())
                    "consumeAction" -> result.success(consumeLiveUpdateAction())
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun consumeLiveUpdateAction(): Map<String, String>? {
        val currentIntent = intent ?: return null
        val action = currentIntent.getStringExtra(
            HaruLiveUpdateManager.EXTRA_LIVE_ACTION,
        ) ?: return null
        val scheduleDate = currentIntent.getStringExtra(
            HaruLiveUpdateManager.EXTRA_SCHEDULE_DATE,
        ) ?: return null
        currentIntent.removeExtra(HaruLiveUpdateManager.EXTRA_LIVE_ACTION)
        currentIntent.removeExtra(HaruLiveUpdateManager.EXTRA_SCHEDULE_DATE)
        currentIntent.action = null
        return mapOf("action" to action, "scheduleDate" to scheduleDate)
    }

    private fun hasCalendarPermission(): Boolean =
        checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED &&
            checkSelfPermission(Manifest.permission.WRITE_CALENDAR) == PackageManager.PERMISSION_GRANTED

    private fun requestCalendarPermission(result: MethodChannel.Result) {
        if (hasCalendarPermission()) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.success(false)
            return
        }
        pendingPermissionResult = result
        requestPermissions(
            arrayOf(
                Manifest.permission.READ_CALENDAR,
                Manifest.permission.WRITE_CALENDAR,
            ),
            calendarPermissionRequest,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != calendarPermissionRequest) return
        pendingPermissionResult?.success(hasCalendarPermission())
        pendingPermissionResult = null
    }

    private fun writableCalendars(): List<Map<String, String>> {
        if (!hasCalendarPermission()) return emptyList()
        val calendars = mutableListOf<Map<String, String>>()
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
        )
        val selection =
            "${CalendarContract.Calendars.VISIBLE}=1 AND " +
                "${CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL}>=?"
        val args = arrayOf(CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR.toString())
        contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            selection,
            args,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                calendars.add(
                    mapOf(
                        "id" to cursor.getLong(0).toString(),
                        "name" to cursor.getString(1).orEmpty(),
                    ),
                )
            }
        }
        return calendars
    }

    private fun addEvent(
        calendarId: String?,
        title: String?,
        startMillis: Long?,
        endMillis: Long?,
    ): Boolean {
        if (!hasCalendarPermission()) return false
        val id = calendarId?.toLongOrNull() ?: return false
        if (title == null || startMillis == null || endMillis == null) return false
        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, id)
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DTSTART, startMillis)
            put(CalendarContract.Events.DTEND, endMillis)
            put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
        }
        return contentResolver.insert(CalendarContract.Events.CONTENT_URI, values) != null
    }
}
