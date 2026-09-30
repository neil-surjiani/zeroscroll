package com.apexventures.zeroscroll.db

import android.content.ContentValues
import android.content.Context
import android.content.SharedPreferences
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import com.apexventures.zeroscroll.model.NotificationItem
import com.apexventures.zeroscroll.model.NotificationType

/**
 * Native SQLite helper managing on-device persistence of captured notifications.
 * Operates independently of the Flutter runtime lifecycle to ensure background capture works.
 */
class NotificationDbHelper(private val context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        const val DATABASE_NAME = "zeroscroll_notifications.db"
        const val DATABASE_VERSION = 1

        const val TABLE_NOTIFICATIONS = "notifications"
        const val COLUMN_ID = "id"
        const val COLUMN_NOTIFICATION_KEY = "notification_key"
        const val COLUMN_TYPE = "type"
        const val COLUMN_TITLE = "title"
        const val COLUMN_TEXT = "text"
        const val COLUMN_SENDER = "sender"
        const val COLUMN_THREAD_ID = "thread_id"
        const val COLUMN_POSTED_AT = "posted_at"
        const val COLUMN_IS_READ = "is_read"

        const val PREFS_NAME = "zeroscroll_notification_prefs"
        const val PREF_STORAGE_ENABLED = "storage_enabled"
        const val PREF_RETENTION_DAYS = "retention_days"
        const val PREF_REPOST_ENABLED = "repost_enabled"
        const val PREF_DISMISS_ORIGINAL_ENABLED = "dismiss_original_enabled"
        const val PREF_MESSAGES_ONLY = "messages_only"

        const val DEFAULT_RETENTION_DAYS = 7

        @Volatile
        private var instance: NotificationDbHelper? = null

        fun getInstance(context: Context): NotificationDbHelper {
            return instance ?: synchronized(this) {
                instance ?: NotificationDbHelper(context.applicationContext).also { instance = it }
            }
        }
    }

    private val prefs: SharedPreferences by lazy {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    var isStorageEnabled: Boolean
        get() = prefs.getBoolean(PREF_STORAGE_ENABLED, true)
        set(value) = prefs.edit().putBoolean(PREF_STORAGE_ENABLED, value).apply()

    var retentionDays: Int
        get() = prefs.getInt(PREF_RETENTION_DAYS, DEFAULT_RETENTION_DAYS)
        set(value) = prefs.edit().putInt(PREF_RETENTION_DAYS, value).apply()

    var isRepostEnabled: Boolean
        get() = prefs.getBoolean(PREF_REPOST_ENABLED, false)
        set(value) = prefs.edit().putBoolean(PREF_REPOST_ENABLED, value).apply()

    var isDismissOriginalEnabled: Boolean
        get() = prefs.getBoolean(PREF_DISMISS_ORIGINAL_ENABLED, false)
        set(value) = prefs.edit().putBoolean(PREF_DISMISS_ORIGINAL_ENABLED, value).apply()

    var isMessagesOnly: Boolean
        get() = prefs.getBoolean(PREF_MESSAGES_ONLY, true)
        set(value) = prefs.edit().putBoolean(PREF_MESSAGES_ONLY, value).apply()

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE $TABLE_NOTIFICATIONS (
                $COLUMN_ID TEXT PRIMARY KEY,
                $COLUMN_NOTIFICATION_KEY TEXT,
                $COLUMN_TYPE TEXT NOT NULL,
                $COLUMN_TITLE TEXT,
                $COLUMN_TEXT TEXT,
                $COLUMN_SENDER TEXT,
                $COLUMN_THREAD_ID TEXT,
                $COLUMN_POSTED_AT INTEGER NOT NULL,
                $COLUMN_IS_READ INTEGER NOT NULL DEFAULT 0
            )
            """.trimIndent()
        )

        db.execSQL("CREATE INDEX IF NOT EXISTS idx_notifications_posted_at ON $TABLE_NOTIFICATIONS($COLUMN_POSTED_AT DESC)")
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_notifications_type ON $TABLE_NOTIFICATIONS($COLUMN_TYPE)")
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON $TABLE_NOTIFICATIONS($COLUMN_IS_READ)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        // Version 1 is baseline; migration logic added if schema evolves.
    }

    @Volatile
    private var lastPruneTime = 0L

    /**
     * Inserts or updates a captured notification if storage is enabled.
     * Periodically triggers retention cleanup for items older than retentionDays.
     */
    fun insertNotification(item: NotificationItem): Long {
        if (!isStorageEnabled) return -1L

        val now = System.currentTimeMillis()
        if (now - lastPruneTime > 6 * 60 * 60 * 1000L) {
            lastPruneTime = now
            pruneExpired(retentionDays)
        }

        val values = ContentValues().apply {
            put(COLUMN_ID, item.id)
            put(COLUMN_NOTIFICATION_KEY, item.notificationKey)
            put(COLUMN_TYPE, item.type.name)
            put(COLUMN_TITLE, item.title)
            put(COLUMN_TEXT, item.text)
            put(COLUMN_SENDER, item.sender)
            put(COLUMN_THREAD_ID, item.threadId)
            put(COLUMN_POSTED_AT, item.postedAt)
            put(COLUMN_IS_READ, if (item.isRead) 1 else 0)
        }

        return writableDatabase.insertWithOnConflict(
            TABLE_NOTIFICATIONS,
            null,
            values,
            SQLiteDatabase.CONFLICT_REPLACE
        )
    }

    /**
     * Retrieves stored notifications up to [limit], optionally filtered by [typeFilter].
     */
    fun getNotifications(limit: Int = 100, typeFilter: String? = null): List<NotificationItem> {
        val items = mutableListOf<NotificationItem>()
        val selection = if (typeFilter != null) "$COLUMN_TYPE = ?" else null
        val selectionArgs = if (typeFilter != null) arrayOf(typeFilter) else null

        val cursor = readableDatabase.query(
            TABLE_NOTIFICATIONS,
            null,
            selection,
            selectionArgs,
            null,
            null,
            "$COLUMN_POSTED_AT DESC",
            limit.toString()
        )

        cursor.use {
            while (it.moveToNext()) {
                items.add(cursorToItem(it))
            }
        }

        return items
    }

    /**
     * Marks a notification as read.
     */
    fun markAsRead(id: String): Int {
        val values = ContentValues().apply {
            put(COLUMN_IS_READ, 1)
        }
        return writableDatabase.update(
            TABLE_NOTIFICATIONS,
            values,
            "$COLUMN_ID = ?",
            arrayOf(id)
        )
    }

    /**
     * Marks all stored notifications as read.
     */
    fun markAllAsRead(): Int {
        val values = ContentValues().apply {
            put(COLUMN_IS_READ, 1)
        }
        return writableDatabase.update(TABLE_NOTIFICATIONS, values, null, null)
    }

    /**
     * Deletes a specific notification by ID.
     */
    fun deleteNotification(id: String): Int {
        return writableDatabase.delete(
            TABLE_NOTIFICATIONS,
            "$COLUMN_ID = ?",
            arrayOf(id)
        )
    }

    /**
     * Clears all stored notifications.
     */
    fun clearAll(): Int {
        return writableDatabase.delete(TABLE_NOTIFICATIONS, null, null)
    }

    /**
     * Returns the count of unread Direct Message (DM) notifications.
     */
    fun getUnreadDmCount(): Int {
        val cursor = readableDatabase.rawQuery(
            """
            SELECT COUNT(*) FROM $TABLE_NOTIFICATIONS 
            WHERE $COLUMN_TYPE = ? AND $COLUMN_IS_READ = 0
            """.trimIndent(),
            arrayOf(NotificationType.DM.name)
        )
        cursor.use {
            return if (it.moveToFirst()) it.getInt(0) else 0
        }
    }

    /**
     * Prunes notifications older than [days] days.
     */
    fun pruneExpired(days: Int = retentionDays): Int {
        if (days <= 0) return 0
        val cutoff = System.currentTimeMillis() - (days.toLong() * 24 * 60 * 60 * 1000L)
        return writableDatabase.delete(
            TABLE_NOTIFICATIONS,
            "$COLUMN_POSTED_AT < ?",
            arrayOf(cutoff.toString())
        )
    }

    private fun cursorToItem(cursor: Cursor): NotificationItem {
        return NotificationItem(
            id = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_ID)),
            notificationKey = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_NOTIFICATION_KEY)),
            type = NotificationType.fromString(cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_TYPE))),
            title = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_TITLE)),
            text = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_TEXT)),
            sender = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_SENDER)),
            threadId = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_THREAD_ID)),
            postedAt = cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_POSTED_AT)),
            isRead = cursor.getInt(cursor.getColumnIndexOrThrow(COLUMN_IS_READ)) == 1
        )
    }
}
