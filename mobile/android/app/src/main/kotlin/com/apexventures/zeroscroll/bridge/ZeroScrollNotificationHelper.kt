package com.apexventures.zeroscroll.bridge

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.apexventures.zeroscroll.MainActivity
import com.apexventures.zeroscroll.model.NotificationItem
import com.apexventures.zeroscroll.model.NotificationType

/**
 * Manages ZeroScroll's own local notification channel and re-posting of notifications.
 * Uses ZeroScroll's own brand identity and grouping by sender.
 */
object ZeroScrollNotificationHelper {
    const val CHANNEL_ID_MESSAGES = "zeroscroll_messages"
    const val CHANNEL_NAME_MESSAGES = "Messages"
    const val CHANNEL_DESC_MESSAGES = "Direct messages captured on-device"
    const val ACTION_OPEN_DM = "com.apexventures.zeroscroll.OPEN_DM"

    /**
     * Creates the "Messages" notification channel on Android O (API 26) and above.
     */
    fun createNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID_MESSAGES,
                CHANNEL_NAME_MESSAGES,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESC_MESSAGES
                enableLights(true)
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Re-posts a captured notification under ZeroScroll's own notification channel,
     * grouped by sender, with a PendingIntent targeting MainActivity.
     */
    fun repostNotification(context: Context, item: NotificationItem) {
        createNotificationChannels(context)

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val intent = Intent(context, MainActivity::class.java).apply {
            action = ACTION_OPEN_DM
            putExtra("id", item.id)
            putExtra("sender", item.sender)
            putExtra("thread_id", item.threadId)
            putExtra("type", item.type.name)
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            item.id.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val groupKey = "zeroscroll_group_" + (item.sender ?: "default")
        val displayTitle = item.sender ?: item.title ?: "New Message"
        val displayText = item.text ?: "New message received"

        val builder = NotificationCompat.Builder(context, CHANNEL_ID_MESSAGES)
            .setSmallIcon(android.R.drawable.ic_dialog_email)
            .setContentTitle(displayTitle)
            .setContentText(displayText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(displayText))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setGroup(groupKey)
            .setContentIntent(pendingIntent)
            .setWhen(item.postedAt)

        notificationManager.notify(item.id.hashCode(), builder.build())
    }
}
