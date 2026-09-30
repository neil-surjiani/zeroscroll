package com.apexventures.zeroscroll.classifier

import android.app.Notification
import android.os.Build
import android.os.Bundle
import android.service.notification.StatusBarNotification
import android.util.Log
import com.apexventures.zeroscroll.model.NotificationItem
import com.apexventures.zeroscroll.model.NotificationType
import java.util.UUID

/**
 * Raw representation of notification fields decoupled from Android framework types
 * to enable deterministic JVM unit testing and resilient parsing.
 */
data class RawNotificationData(
    val packageName: String,
    val key: String? = null,
    val postTime: Long = System.currentTimeMillis(),
    val channelId: String? = null,
    val category: String? = null,
    val title: String? = null,
    val text: String? = null,
    val bigText: String? = null,
    val subText: String? = null,
    val conversationTitle: String? = null,
    val messages: List<RawMessageItem> = emptyList(),
    val extraStrings: Map<String, String> = emptyMap(),
    val rawKeys: Set<String> = emptySet()
)

data class RawMessageItem(
    val sender: String? = null,
    val text: String? = null,
    val timestamp: Long = 0L
)

/**
 * Classifier for Instagram notifications (`com.instagram.android`).
 * Categorizes notifications into DM, ACTIVITY, or OTHER using channel IDs, categories,
 * message contents, and resilient key inspection.
 */
object NotificationClassifier {
    private const val TAG = "NotificationClassifier"
    const val INSTAGRAM_PACKAGE = "com.instagram.android"

    /** Controls debug-only structural logging of unrecognized notifications */
    var isDebug: Boolean = false

    // DM channel patterns
    private val DM_CHANNELS = listOf(
        "direct", "direct_v2", "ig_direct", "messages", "chat", "direct_messages",
        "direct_share", "direct_video_call"
    )

    // Activity channel patterns
    private val ACTIVITY_CHANNELS = listOf(
        "comments", "likes", "activity", "user_activity", "social", "follow",
        "mentions", "tags", "notification"
    )

    // Phrases strongly indicative of Direct Messages
    private val DM_CONTENT_PATTERNS = listOf(
        "sent you a message",
        "sent a photo",
        "sent a video",
        "sent a reel",
        "shared a post",
        "shared a reel",
        "sent an attachment",
        "sent a voice message",
        "sent an audio message",
        "sent a link",
        "sent a disappearing",
        "reacted to your message",
        "liked your message",
        "in the conversation"
    )

    // Phrases strongly indicative of Activity (likes, follows, comments, mentions)
    private val ACTIVITY_CONTENT_PATTERNS = listOf(
        "liked your photo",
        "liked your reel",
        "liked your post",
        "liked your story",
        "liked your comment",
        "liked your video",
        "commented:",
        "commented on",
        "replied to your comment",
        "started following you",
        "requested to follow you",
        "accepted your follow request",
        "tagged you in",
        "mentioned you in"
    )

    /**
     * Extracts and classifies a notification from a [StatusBarNotification].
     * Returns null if the notification is not from com.instagram.android.
     */
    fun classify(sbn: StatusBarNotification): NotificationItem? {
        if (sbn.packageName != INSTAGRAM_PACKAGE) {
            return null
        }

        val data = extractRawData(sbn)
        return classify(data)
    }

    /**
     * Classifies a [RawNotificationData] instance into a [NotificationItem].
     * Returns null if [RawNotificationData.packageName] is not com.instagram.android.
     */
    fun classify(data: RawNotificationData): NotificationItem? {
        if (data.packageName != INSTAGRAM_PACKAGE) {
            return null
        }

        val type = determineType(data)
        val title = resolveTitle(data)
        val text = resolveText(data)
        val sender = resolveSender(data, title, text)
        val threadId = resolveThreadId(data)
        val id = data.key ?: "${data.packageName}_${data.postTime}_${UUID.randomUUID()}"

        // In debug builds, log unknown/unclassified structures for developer adjustment
        if (type == NotificationType.OTHER) {
            logUnknownStructure(data)
        }

        return NotificationItem(
            id = id,
            notificationKey = data.key,
            type = type,
            title = title,
            text = text,
            sender = sender,
            threadId = threadId,
            postedAt = data.postTime,
            isRead = false
        )
    }

    /**
     * Determines whether the notification represents a DM, Activity, or Other item.
     */
    private fun determineType(data: RawNotificationData): NotificationType {
        val channelLower = data.channelId?.lowercase() ?: ""
        val categoryLower = data.category?.lowercase() ?: ""
        val textLower = (data.bigText ?: data.text ?: "").lowercase()
        val titleLower = (data.conversationTitle ?: data.title ?: "").lowercase()
        val combinedContent = "$titleLower $textLower"

        // 1. Check for DM indicators
        val isDmChannel = DM_CHANNELS.any { channelLower.contains(it) }
        val isDmCategory = categoryLower == Notification.CATEGORY_MESSAGE.lowercase() || categoryLower == "msg"
        val hasMessagesBundle = data.messages.isNotEmpty()
        val isDmContent = DM_CONTENT_PATTERNS.any { combinedContent.contains(it) }

        if (isDmChannel || isDmCategory || hasMessagesBundle || isDmContent) {
            // Verify it is not an activity notification misclassified by broad categories
            val hasActivityContent = ACTIVITY_CONTENT_PATTERNS.any { combinedContent.contains(it) }
            val isActivityChannel = ACTIVITY_CHANNELS.any { channelLower.contains(it) }
            if (hasActivityContent || isActivityChannel) {
                return NotificationType.ACTIVITY
            }
            return NotificationType.DM
        }

        // 2. Check for Activity indicators (likes, comments, follows)
        val isActivityChannel = ACTIVITY_CHANNELS.any { channelLower.contains(it) }
        val isActivityCategory = categoryLower == Notification.CATEGORY_SOCIAL.lowercase() || categoryLower == "social"
        val isActivityContent = ACTIVITY_CONTENT_PATTERNS.any { combinedContent.contains(it) }

        if (isActivityChannel || isActivityCategory || isActivityContent) {
            return NotificationType.ACTIVITY
        }

        // 3. Fallback to Other
        return NotificationType.OTHER
    }

    private fun resolveTitle(data: RawNotificationData): String? {
        return data.conversationTitle
            ?: data.title
            ?: data.subText
    }

    private fun resolveText(data: RawNotificationData): String? {
        // If messaging style with message items, grab latest text
        if (data.messages.isNotEmpty()) {
            val latest = data.messages.lastOrNull { !it.text.isNullOrBlank() }
            if (latest?.text != null) return latest.text
        }
        return data.bigText ?: data.text
    }

    /**
     * Best-effort extraction of sender identity.
     */
    private fun resolveSender(data: RawNotificationData, title: String?, text: String?): String? {
        // 1. From MessagingStyle message sender
        if (data.messages.isNotEmpty()) {
            val latest = data.messages.lastOrNull { !it.sender.isNullOrBlank() }
            if (latest?.sender != null) return latest.sender
        }

        // 2. From conversation title or single title (if not generic "Instagram")
        if (!title.isNullOrBlank() && !isGenericBrandName(title)) {
            // E.g. "alex: Hey there" -> sender "alex"
            if (title.contains(":")) {
                val prefix = title.substringBefore(":").trim()
                if (prefix.isNotEmpty() && !isGenericBrandName(prefix)) {
                    return prefix
                }
            }
            return title.trim()
        }

        // 3. From text patterns like "username sent you a message" or "username: message"
        if (!text.isNullOrBlank()) {
            for (pattern in DM_CONTENT_PATTERNS + ACTIVITY_CONTENT_PATTERNS) {
                if (text.contains(pattern, ignoreCase = true)) {
                    val idx = text.indexOf(pattern, ignoreCase = true)
                    val candidate = text.substring(0, idx).trim()
                    if (candidate.isNotEmpty() && !isGenericBrandName(candidate) && candidate.length <= 40) {
                        return candidate
                    }
                }
            }

            if (text.contains(":")) {
                val prefix = text.substringBefore(":").trim()
                if (prefix.isNotEmpty() && !isGenericBrandName(prefix) && prefix.length <= 40) {
                    return prefix
                }
            }
        }

        return null
    }

    /**
     * Extracts thread ID or deep link reference if available.
     */
    private fun resolveThreadId(data: RawNotificationData): String? {
        // Check extraStrings for direct thread references
        for ((key, value) in data.extraStrings) {
            val keyLower = key.lowercase()
            if (keyLower.contains("thread_id") || keyLower.contains("threadid")) {
                return value
            }
            // Parse URI patterns like instagram://direct_thread?id=12345
            val uriMatch = Regex("""direct_thread\?id=([0-9a-zA-Z_]+)""").find(value)
            if (uriMatch != null) {
                return uriMatch.groupValues[1]
            }
            // Parse web path patterns like /direct/t/12345/
            val pathMatch = Regex("""/direct/t/([0-9a-zA-Z_]+)""").find(value)
            if (pathMatch != null) {
                return pathMatch.groupValues[1]
            }
        }
        return null
    }

    private fun isGenericBrandName(str: String): Boolean {
        val lower = str.lowercase().trim()
        return lower == "instagram" || lower == "zeroscroll" || lower == "direct" || lower == "messages"
    }

    /**
     * Converts an Android [StatusBarNotification] into [RawNotificationData].
     */
    fun extractRawData(sbn: StatusBarNotification): RawNotificationData {
        val notification = sbn.notification
        val extras = notification.extras ?: Bundle()
        val rawKeys = extras.keySet() ?: emptySet()

        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
        val conversationTitle = extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString()

        val messages = mutableListOf<RawMessageItem>()
        val messagesBundleArray = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
        if (messagesBundleArray != null) {
            for (item in messagesBundleArray) {
                if (item is Bundle) {
                    val mSender = item.getCharSequence("sender")?.toString()
                    val mText = item.getCharSequence("text")?.toString()
                    val mTime = item.getLong("time", 0L)
                    messages.add(RawMessageItem(sender = mSender, text = mText, timestamp = mTime))
                }
            }
        }

        val extraStrings = mutableMapOf<String, String>()
        for (key in rawKeys) {
            val value = extras.get(key)
            if (value is String) {
                extraStrings[key] = value
            } else if (value is CharSequence) {
                extraStrings[key] = value.toString()
            }
        }

        val channelId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notification.channelId
        } else {
            null
        }

        return RawNotificationData(
            packageName = sbn.packageName,
            key = sbn.key,
            postTime = sbn.postTime,
            channelId = channelId,
            category = notification.category,
            title = title,
            text = text,
            bigText = bigText,
            subText = subText,
            conversationTitle = conversationTitle,
            messages = messages,
            extraStrings = extraStrings,
            rawKeys = rawKeys
        )
    }

    private fun logUnknownStructure(data: RawNotificationData) {
        if (!isDebug) return
        try {
            // Note: Never log sensitive message text; log structural metadata only
            Log.d(
                TAG,
                "Unrecognized notification structure: channelId=${data.channelId}, " +
                    "category=${data.category}, rawKeys=${data.rawKeys}"
            )
        } catch (_: Throwable) {}
    }
}
