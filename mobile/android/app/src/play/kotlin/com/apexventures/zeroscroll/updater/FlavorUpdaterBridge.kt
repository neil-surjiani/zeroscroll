package com.apexventures.zeroscroll.updater

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Play Store build flavor updater bridge.
 * In accordance with Google Play Store policies and ZeroScroll guidelines,
 * all in-app APK updating, PackageInstaller invocations, and REQUEST_INSTALL_PACKAGES
 * are strictly excluded from the Play Store flavor.
 */
class FlavorUpdaterBridge(private val activity: Activity) {
    fun registerWith(flutterEngine: FlutterEngine) {
        // No-op for Google Play builds: No updater channel, no package installer.
    }
}
