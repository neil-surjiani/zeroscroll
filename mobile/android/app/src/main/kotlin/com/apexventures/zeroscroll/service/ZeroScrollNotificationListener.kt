package com.apexventures.zeroscroll.service

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.apexventures.zeroscroll.bridge.NotificationBroadcaster
import com.apexventures.zeroscroll.bridge.ZeroScrollNotificationHelper
import com.apexventures.zeroscroll.classifier.NotificationClassifier
import com.apexventures.zeroscroll.db.NotificationDbHelper
import com.apexventures.zeroscroll.model.NotificationType

/**
 * Android NotificationListenerService that captures only Instagram notifications.
 * Persists captured items to native SQLite, optionally reposts as ZeroScroll alerts,
 * and streams events to Flutter when the app is active.
 */
class ZeroScrollNotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "ZeroScrollListener"
    }

    private val dbHelper: NotificationDbHelper by lazy {
        NotificationDbHelper.getInstance(applicationContext)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        if (com.apexventures.zeroscroll.BuildConfig.DEBUG) {
            Log.d(TAG, "ZeroScrollNotificationListener connected.")
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        if (com.apexventures.zeroscroll.BuildConfig.DEBUG) {
            Log.d(TAG, "ZeroScrollNotificationListener disconnected.")
        }
    }

    private val dbExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()

    override fun onDestroy() {
        super.onDestroy()
        dbExecutor.shutdown()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        // 1. Strict filtering: process ONLY com.instagram.android notifications
        if (sbn.packageName != NotificationClassifier.INSTAGRAM_PACKAGE) {
            return
        }

        // Ignore ongoing / non-clearable system notifications (e.g. active upload foreground service)
        if (sbn.isOngoing) {
            return
        }

        // 2. Classify and extract notification data
        val item = NotificationClassifier.classify(sbn) ?: return

        // 2b. Mindful filter: If user chose Messages Only, ignore activity (likes/follows/comments)
        if (dbHelper.isMessagesOnly && item.type != NotificationType.DM) {
            return
        }

        // 3. Persist to native SQLite asynchronously on background thread (no binder stall, works if Flutter dead)
        if (dbHelper.isStorageEnabled) {
            dbExecutor.execute {
                try {
                    dbHelper.insertNotification(item)
                } catch (e: Exception) {
                    if (com.apexventures.zeroscroll.BuildConfig.DEBUG) {
                        Log.w(TAG, "Failed to persist notification: ${e.message}")
                    }
                }
            }
        }

        // 4. Stream to Flutter in real-time if active
        NotificationBroadcaster.emit(item)

        // 5. Optional ZeroScroll notification re-posting (grouped by sender under own channel)
        if (dbHelper.isRepostEnabled && item.type == NotificationType.DM) {
            ZeroScrollNotificationHelper.repostNotification(applicationContext, item)
        }

        // 6. Optional original notification dismissal (default off)
        if (dbHelper.isDismissOriginalEnabled && sbn.key != null) {
            try {
                cancelNotification(sbn.key)
            } catch (e: Exception) {
                if (com.apexventures.zeroscroll.BuildConfig.DEBUG) {
                    Log.w(TAG, "Failed to dismiss original notification: ${e.message}")
                }
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        // Nothing required to remove from local archive when cleared from system tray
    }
}
