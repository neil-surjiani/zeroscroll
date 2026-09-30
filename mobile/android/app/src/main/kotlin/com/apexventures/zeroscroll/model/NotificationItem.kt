package com.apexventures.zeroscroll.model

enum class NotificationType {
    DM,
    ACTIVITY,
    OTHER;

    companion object {
        fun fromString(value: String): NotificationType {
            return when (value.uppercase()) {
                "DM" -> DM
                "ACTIVITY" -> ACTIVITY
                else -> OTHER
            }
        }
    }
}

/**
 * On-device representation of a captured Instagram notification.
 * Strictly stored locally and never transmitted externally.
 */
data class NotificationItem(
    val id: String,
    val notificationKey: String? = null,
    val type: NotificationType,
    val title: String? = null,
    val text: String? = null,
    val sender: String? = null,
    val threadId: String? = null,
    val postedAt: Long,
    val isRead: Boolean = false
) {
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "id" to id,
            "notificationKey" to notificationKey,
            "type" to type.name,
            "title" to title,
            "text" to text,
            "sender" to sender,
            "threadId" to threadId,
            "postedAt" to postedAt,
            "isRead" to isRead
        )
    }

    companion object {
        fun fromMap(map: Map<String, Any?>): NotificationItem {
            return NotificationItem(
                id = map["id"] as? String ?: "",
                notificationKey = map["notificationKey"] as? String,
                type = NotificationType.fromString(map["type"] as? String ?: "OTHER"),
                title = map["title"] as? String,
                text = map["text"] as? String,
                sender = map["sender"] as? String,
                threadId = map["threadId"] as? String,
                postedAt = (map["postedAt"] as? Number)?.toLong() ?: System.currentTimeMillis(),
                isRead = map["isRead"] as? Boolean ?: false
            )
        }
    }
}
