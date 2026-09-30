package com.apexventures.zeroscroll.bridge

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.apexventures.zeroscroll.db.NotificationDbHelper
import com.apexventures.zeroscroll.model.NotificationItem
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles MethodChannel and EventChannel communication between Flutter and native Android
 * notification components.
 */
class NotificationChannelHandler(private val context: Context) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "com.apexventures.zeroscroll/notifications"
        const val EVENT_CHANNEL = "com.apexventures.zeroscroll/notifications_stream"
    }

    private val dbHelper = NotificationDbHelper.getInstance(context)
    private var initialNotificationData: Map<String, Any?>? = null

    fun setInitialNotification(intent: Intent?) {
        if (intent != null && intent.action == ZeroScrollNotificationHelper.ACTION_OPEN_DM) {
            initialNotificationData = mapOf(
                "id" to intent.getStringExtra("id"),
                "sender" to intent.getStringExtra("sender"),
                "threadId" to intent.getStringExtra("thread_id"),
                "type" to intent.getStringExtra("type")
            )
        }
    }

    fun registerWith(flutterEngine: FlutterEngine) {
        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        val eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isListenerEnabled" -> {
                result.success(isListenerEnabled())
            }

            "openListenerSettings" -> {
                openListenerSettings()
                result.success(true)
            }

            "openAppInfoSettings" -> {
                openAppInfoSettings()
                result.success(true)
            }

            "isPostNotificationsGranted" -> {
                result.success(isPostNotificationsGranted())
            }

            "requestPostNotificationsPermission" -> {
                requestPostNotificationsPermission()
                result.success(true)
            }

            "isBatteryOptimizationIgnored" -> {
                result.success(isBatteryOptimizationIgnored())
            }

            "openBatteryOptimizationSettings" -> {
                openBatteryOptimizationSettings()
                result.success(true)
            }

            "getAndroidSdkVersion" -> {
                result.success(Build.VERSION.SDK_INT)
            }

            "getNotifications" -> {
                val limit = call.argument<Int>("limit") ?: 100
                val type = call.argument<String>("type")
                val items = dbHelper.getNotifications(limit, type).map { it.toMap() }
                result.success(items)
            }

            "markRead" -> {
                val id = call.argument<String>("id")
                if (id != null) {
                    val count = dbHelper.markAsRead(id)
                    result.success(count > 0)
                } else {
                    result.error("INVALID_ARGUMENT", "Notification id is required", null)
                }
            }

            "markAllRead" -> {
                val count = dbHelper.markAllAsRead()
                result.success(count)
            }

            "deleteNotification" -> {
                val id = call.argument<String>("id")
                if (id != null) {
                    val count = dbHelper.deleteNotification(id)
                    result.success(count > 0)
                } else {
                    result.error("INVALID_ARGUMENT", "Notification id is required", null)
                }
            }

            "clearAll" -> {
                val count = dbHelper.clearAll()
                result.success(count)
            }

            "getUnreadDmCount" -> {
                result.success(dbHelper.getUnreadDmCount())
            }

            "getSettings" -> {
                val settings = mapOf(
                    "storageEnabled" to dbHelper.isStorageEnabled,
                    "retentionDays" to dbHelper.retentionDays,
                    "repostEnabled" to dbHelper.isRepostEnabled,
                    "dismissOriginalEnabled" to dbHelper.isDismissOriginalEnabled,
                    "messagesOnly" to dbHelper.isMessagesOnly
                )
                result.success(settings)
            }

            "updateSettings" -> {
                val storage = call.argument<Boolean>("storageEnabled")
                val retention = call.argument<Int>("retentionDays")
                val repost = call.argument<Boolean>("repostEnabled")
                val dismiss = call.argument<Boolean>("dismissOriginalEnabled")
                val messagesOnly = call.argument<Boolean>("messagesOnly")

                storage?.let { dbHelper.isStorageEnabled = it }
                retention?.let { dbHelper.retentionDays = it }
                repost?.let { dbHelper.isRepostEnabled = it }
                dismiss?.let { dbHelper.isDismissOriginalEnabled = it }
                messagesOnly?.let { dbHelper.isMessagesOnly = it }

                result.success(true)
            }

            "setNotificationFilter" -> {
                val messagesOnly = call.argument<Boolean>("messagesOnly") ?: true
                dbHelper.isMessagesOnly = messagesOnly
                result.success(true)
            }

            "getInitialNotification" -> {
                result.success(initialNotificationData)
                initialNotificationData = null
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        NotificationBroadcaster.attachSink(events)
    }

    override fun onCancel(arguments: Any?) {
        NotificationBroadcaster.detachSink()
    }

    private fun isListenerEnabled(): Boolean {
        val packageName = context.packageName
        val flat = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
        if (!flat.isNullOrEmpty()) {
            val names = flat.split(":")
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && cn.packageName == packageName) {
                    return true
                }
            }
        }
        val enabledPackages = NotificationManagerCompat.getEnabledListenerPackages(context)
        return enabledPackages.contains(packageName)
    }

    private fun openListenerSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    private fun openAppInfoSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", context.packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(intent)
    }

    private fun isPostNotificationsGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                android.Manifest.permission.POST_NOTIFICATIONS
            ) == android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestPostNotificationsPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (context is android.app.Activity) {
                ActivityCompat.requestPermissions(
                    context,
                    arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                    102
                )
            }
        }
    }

    private fun isBatteryOptimizationIgnored(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            pm?.isIgnoringBatteryOptimizations(context.packageName) ?: true
        } else {
            true
        }
    }

    private fun openBatteryOptimizationSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
            } catch (e: Exception) {
                openAppInfoSettings()
            }
        } else {
            openAppInfoSettings()
        }
    }
}
