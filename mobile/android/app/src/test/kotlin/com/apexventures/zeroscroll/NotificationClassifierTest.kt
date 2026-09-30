package com.apexventures.zeroscroll

import com.apexventures.zeroscroll.classifier.NotificationClassifier
import com.apexventures.zeroscroll.classifier.RawMessageItem
import com.apexventures.zeroscroll.classifier.RawNotificationData
import com.apexventures.zeroscroll.model.NotificationType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class NotificationClassifierTest {

    @Test
    fun `ignores non-instagram package notifications`() {
        val data = RawNotificationData(
            packageName = "com.whatsapp",
            channelId = "direct",
            title = "John",
            text = "Hello"
        )

        val result = NotificationClassifier.classify(data)
        assertNull("Non-Instagram packages must be ignored", result)
    }

    @Test
    fun `classifies DM by direct channel id`() {
        val data = RawNotificationData(
            packageName = NotificationClassifier.INSTAGRAM_PACKAGE,
            channelId = "direct_v2",
            title = "sarah_connor",
            text = "Are you coming to the party tonight?"
        )

        val result = NotificationClassifier.classify(data)
        assertNotNull(result)
        assertEquals(NotificationType.DM, result!!.type)
        assertEquals("sarah_connor", result.title)
        assertEquals("sarah_connor", result.sender)
        assertEquals("Are you coming to the party tonight?", result.text)
    }

    @Test
    fun `classifies DM by message category`() {
        val data = RawNotificationData(
            packageName = NotificationClassifier.INSTAGRAM_PACKAGE,
            category = "msg",
            title = "alex_99",
            text = "Hey check this"
        )

        val result = NotificationClassifier.classify(data)
        assertNotNull(result)
        assertEquals(NotificationType.DM, result!!.type)
        assertEquals("alex_99", result.sender)
    }

    @Test
    fun `classifies DM by content pattern`() {
        val data = RawNotificationData(
            packageName = NotificationClassifier.INSTAGRAM_PACKAGE,
            title = "Instagram",
            text = "jessica sent you a message."
        )

        val result = NotificationClassifier.classify(data)
        assertNotNull(result)
        assertEquals(NotificationType.DM, result!!.type)
        assertEquals("jessica", result.sender)
    }

    @Test
    fun `classifies DM with messaging style messages bundle`() {
        val data = RawNotificationData(
            packageName = NotificationClassifier.INSTAGRAM_PACKAGE,
            channelId = "ig_direct",
            messages = listOf(
                RawMessageItem(sender = "emma_w", text = "First message", timestamp = 1000L),
                RawMessageItem(sender = "emma_w", text = "Here is the second message", timestamp = 2000L)
            )
        )

        val result = NotificationClassifier.classify(data)
        assertNotNull(result)
        assertEquals(NotificationType.DM, result!!.type)
        assertEquals("Here is the second message", result.text)
        assertEquals("emma_w", result.sender)
    }

    @Test
    fun `extracts thread id from intent URI or extra strings`() {
        val data = RawNotificationData(
            packageName = NotificationClassifier.INSTAGRAM_PACKAGE,
            channelId = "direct",
            title = "david",
            text = "Hey",
            extraStrings = mapOf(
                "action_uri" to "instagram://direct_thread?id=3402823668417103009491281313"
            )
        )

        val result = NotificationClassifier.classify(data)
        assertNotNull(result)
        assertEquals(NotificationType.DM, result!!.type)
        assertEquals("3402823668417103009491281313", result.threadId)
    }

    @Test
    fun `classifies Activity for likes`() {
        val data = RawNotificationData(
            packageName = NotificationClassifier.INSTAGRAM_PACKAGE,
            channelId = "likes",
            title = "Instagram",
            text = "lucas and 3 others liked your photo."
        )

        val result = NotificationClassifier.classify(data)
        assertNotNull(result)
        assertEquals(NotificationType.ACTIVITY, result!!.type)
    }

    @Test
    fun `classifies Activity for comments and extracts sender`() {
        val data = RawNotificationData(
            packageName = NotificationClassifier.INSTAGRAM_PACKAGE,
            channelId = "comments",
            title = "Instagram",
            text = "sophia commented: Absolutely stunning!"
        )

        val result = NotificationClassifier.classify(data)
        assertNotNull(result)
        assertEquals(NotificationType.ACTIVITY, result!!.type)
        assertEquals("sophia", result.sender)
    }

    @Test
    fun `classifies Activity for new followers`() {
        val data = RawNotificationData(
            packageName = NotificationClassifier.INSTAGRAM_PACKAGE,
            channelId = "user_activity",
            title = "Instagram",
            text = "marcus started following you."
        )

        val result = NotificationClassifier.classify(data)
        assertNotNull(result)
        assertEquals(NotificationType.ACTIVITY, result!!.type)
        assertEquals("marcus", result.sender)
    }

    @Test
    fun `classifies fallback as Other`() {
        val data = RawNotificationData(
            packageName = NotificationClassifier.INSTAGRAM_PACKAGE,
            channelId = "security_alerts",
            title = "Security Alert",
            text = "A new login was detected from Chrome on Windows."
        )

        val result = NotificationClassifier.classify(data)
        assertNotNull(result)
        assertEquals(NotificationType.OTHER, result!!.type)
    }
}
