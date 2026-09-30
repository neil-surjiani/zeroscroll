package com.apexventures.zeroscroll

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.webkit.WebView
import com.apexventures.zeroscroll.bridge.NotificationChannelHandler
import com.apexventures.zeroscroll.bridge.SecurityChannelHandler
import com.apexventures.zeroscroll.updater.FlavorUpdaterBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var channelHandler: NotificationChannelHandler? = null
    private var securityHandler: SecurityChannelHandler? = null
    private var updaterBridge: FlavorUpdaterBridge? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Disable WebView remote debugging in non-debug / release builds
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            WebView.setWebContentsDebuggingEnabled(BuildConfig.DEBUG)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channelHandler = NotificationChannelHandler(this).also {
            it.setInitialNotification(intent)
            it.registerWith(flutterEngine)
        }
        securityHandler = SecurityChannelHandler(this).also {
            it.registerWith(flutterEngine)
        }
        updaterBridge = FlavorUpdaterBridge(this).also {
            it.registerWith(flutterEngine)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        channelHandler?.setInitialNotification(intent)
    }
}
