package com.haruapp.haru_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class HaruLiveUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val manager = HaruLiveUpdateManager(context.applicationContext)
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> manager.restore()

            HaruLiveUpdateManager.ACTION_APPLY -> manager.applySerializedSnapshot(
                intent.getStringExtra(HaruLiveUpdateManager.EXTRA_SNAPSHOT),
            )
        }
    }
}
