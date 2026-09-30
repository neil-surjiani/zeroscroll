package com.apexventures.zeroscroll.bridge

import android.app.Activity
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles security-related native Android operations:
 * - FLAG_SECURE management (blocking screenshots and recents screen previews)
 */
class SecurityChannelHandler(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val METHOD_CHANNEL = "com.apexventures.zeroscroll/security"
    }

    private var channel: MethodChannel? = null

    fun registerWith(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setSecureFlag" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setSecureFlag(enabled)
                result.success(true)
            }
            "isSecureFlagEnabled" -> {
                result.success(isSecureFlagEnabled())
            }
            else -> result.notImplemented()
        }
    }

    fun setSecureFlag(enabled: Boolean) {
        activity.runOnUiThread {
            if (enabled) {
                activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
    }

    fun isSecureFlagEnabled(): Boolean {
        val flags = activity.window.attributes.flags
        return (flags and WindowManager.LayoutParams.FLAG_SECURE) != 0
    }
}
