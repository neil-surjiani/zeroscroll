package com.apexventures.zeroscroll.bridge

import android.os.Handler
import android.os.Looper
import com.apexventures.zeroscroll.model.NotificationItem
import io.flutter.plugin.common.EventChannel

/**
 * Thread-safe broadcaster connecting the background NotificationListenerService
 * with Flutter's EventChannel on the main UI thread.
 */
object NotificationBroadcaster {
    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    @Synchronized
    fun attachSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    @Synchronized
    fun detachSink() {
        eventSink = null
    }

    /**
     * Dispatches a captured notification item to the active Flutter EventChannel sink.
     */
    fun emit(item: NotificationItem) {
        mainHandler.post {
            synchronized(this) {
                eventSink?.success(item.toMap())
            }
        }
    }
}
