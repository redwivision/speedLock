package com.redwivision.speedlock

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.os.Bundle

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.redwivision.speedlock/service"
    private var methodChannel: MethodChannel? = null
    private var pendingLockedApp: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val intent = Intent(this, LockService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(true)
                }
                "stopService" -> {
                    val intent = Intent(this, LockService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                "checkUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsageStatsPermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }
                "setLockedApps" -> {
                    val apps = call.argument<List<String>>("apps") ?: listOf()
                    val prefs = getSharedPreferences("SpeedLockPrefs", Context.MODE_PRIVATE)
                    prefs.edit().putStringSet("locked_apps", apps.toSet()).apply()
                    result.success(true)
                }
                "getLockedApps" -> {
                    val prefs = getSharedPreferences("SpeedLockPrefs", Context.MODE_PRIVATE)
                    val apps = prefs.getStringSet("locked_apps", setOf())?.toList() ?: listOf()
                    result.success(apps)
                }
                "getInstalledApps" -> {
                    val pm = packageManager
                    val intent = Intent(Intent.ACTION_MAIN, null).apply {
                        addCategory(Intent.CATEGORY_LAUNCHER)
                    }
                    val apps = pm.queryIntentActivities(intent, 0).map { ri ->
                        mapOf(
                            "packageName" to ri.activityInfo.packageName,
                            "appName" to ri.loadLabel(pm).toString()
                        )
                    }.sortedBy { it["appName"]?.lowercase() }
                    result.success(apps)
                }
                "unlockApp" -> {
                    val pkg = call.argument<String>("package") ?: ""
                    val intent = Intent(this, LockService::class.java).apply {
                        action = "ACTION_APP_UNLOCKED"
                        putExtra("package", pkg)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    // Moves SpeedLock to the background so user sees the unlocked app
                    moveTaskToBack(true)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        pendingLockedApp?.let {
            methodChannel?.invokeMethod("showLockScreen", it)
            pendingLockedApp = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (intent.getBooleanExtra("show_lock", false)) {
            val lockedApp = intent.getStringExtra("locked_app") ?: ""
            if (methodChannel != null) {
                methodChannel?.invokeMethod("showLockScreen", lockedApp)
            } else {
                pendingLockedApp = lockedApp
            }
            // Clear extras so rotation doesn't trigger it again
            intent.removeExtra("show_lock")
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
