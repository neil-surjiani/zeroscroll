package com.apexventures.zeroscroll.updater

import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Sideload distribution updater bridge.
 * Exclusively provides APK installation, signature verification, and unknown app
 * permission checks for self-hosted updates.
 */
class FlavorUpdaterBridge(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL_NAME = "com.apexventures.zeroscroll/updater"
    }

    private var channel: MethodChannel? = null

    fun registerWith(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canRequestPackageInstalls" -> {
                result.success(checkCanRequestPackageInstalls())
            }
            "openInstallPermissionSettings" -> {
                result.success(openInstallPermissionSettings())
            }
            "verifyApkSignature" -> {
                val filePath = call.argument<String>("filePath")
                if (filePath == null) {
                    result.error("INVALID_ARGUMENT", "filePath is required", null)
                    return
                }
                result.success(verifyApkSignature(filePath))
            }
            "installApk" -> {
                val filePath = call.argument<String>("filePath")
                if (filePath == null) {
                    result.error("INVALID_ARGUMENT", "filePath is required", null)
                    return
                }
                installApk(filePath, result)
            }
            "getAvailableStorageBytes" -> {
                try {
                    val usable = activity.cacheDir.usableSpace
                    result.success(usable)
                } catch (e: Exception) {
                    result.error("STORAGE_ERROR", e.localizedMessage, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun checkCanRequestPackageInstalls(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun openInstallPermissionSettings(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                    data = Uri.parse("package:${activity.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                activity.startActivity(intent)
                true
            } catch (e: Exception) {
                false
            }
        } else {
            true
        }
    }

    private fun verifyApkSignature(apkFilePath: String): Boolean {
        try {
            val apkFile = File(apkFilePath)
            if (!apkFile.exists()) {
                return false
            }

            // Extract installed app's signing certificates
            val installedSignatures: List<ByteArray>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val pkgInfo = activity.packageManager.getPackageInfo(
                    activity.packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
                pkgInfo.signingInfo?.apkContentsSigners?.map { it.toByteArray() }
            } else {
                @Suppress("DEPRECATION")
                val pkgInfo = activity.packageManager.getPackageInfo(
                    activity.packageName,
                    PackageManager.GET_SIGNATURES
                )
                @Suppress("DEPRECATION")
                pkgInfo.signatures?.map { it.toByteArray() }
            }

            // Extract downloaded archive's signing certificates
            val archiveSignatures: List<ByteArray>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val archiveInfo = activity.packageManager.getPackageArchiveInfo(
                    apkFilePath,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
                archiveInfo?.signingInfo?.apkContentsSigners?.map { it.toByteArray() }
            } else {
                @Suppress("DEPRECATION")
                val archiveInfo = activity.packageManager.getPackageArchiveInfo(
                    apkFilePath,
                    PackageManager.GET_SIGNATURES
                )
                @Suppress("DEPRECATION")
                archiveInfo?.signatures?.map { it.toByteArray() }
            }

            if (installedSignatures.isNullOrEmpty() || archiveSignatures.isNullOrEmpty()) {
                return false
            }

            // Verify that the archive has at least one signature matching the current installed app
            return archiveSignatures.any { archiveCert ->
                installedSignatures.any { installedCert ->
                    archiveCert.contentEquals(installedCert)
                }
            }
        } catch (e: Exception) {
            return false
        }
    }

    private fun installApk(apkFilePath: String, result: MethodChannel.Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !activity.packageManager.canRequestPackageInstalls()) {
                result.success(
                    mapOf(
                        "success" to false,
                        "status" to "permission_required"
                    )
                )
                return
            }

            val apkFile = File(apkFilePath)
            if (!apkFile.exists()) {
                result.error("FILE_NOT_FOUND", "APK file does not exist at $apkFilePath", null)
                return
            }

            val authority = "${activity.packageName}.sideload.fileprovider"
            val apkUri = FileProvider.getUriForFile(activity, authority, apkFile)

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            activity.startActivity(intent)
            result.success(
                mapOf(
                    "success" to true,
                    "status" to "installer_launched"
                )
            )
        } catch (e: Exception) {
            result.error("INSTALL_ERROR", e.localizedMessage, null)
        }
    }
}
