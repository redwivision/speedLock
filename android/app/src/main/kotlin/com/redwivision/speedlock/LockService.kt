package com.redwivision.speedlock

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*

class LockService : Service() {

    private val serviceJob = SupervisorJob()
    private val serviceScope = CoroutineScope(Dispatchers.IO + serviceJob)
    private lateinit var usageStatsManager: UsageStatsManager
    private lateinit var prefs: SharedPreferences
    private var isScreenOn = true
    private var eventReceiver: EventReceiver? = null

    // Track which apps have been "unlocked" this session.
    // When user successfully enters PIN, the locked app gets added here.
    // When user navigates away from that app, it gets removed so it re-locks next time.
    private val unlockedApps = mutableSetOf<String>()
    private var previousTopApp: String? = null

    override fun onCreate() {
        super.onCreate()
        usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        prefs = getSharedPreferences("SpeedLockPrefs", Context.MODE_PRIVATE)

        startForeground(1, createNotification())

        eventReceiver = EventReceiver { screenOn ->
            isScreenOn = screenOn
            if (!screenOn) {
                // Screen off = re-lock everything
                unlockedApps.clear()
            }
        }
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }
        registerReceiver(eventReceiver, filter)

        startPolling()
    }

    private fun startPolling() {
        serviceScope.launch {
            while (isActive) {
                if (isScreenOn) {
                    val topApp = getTopApp()
                    if (topApp != null && topApp != packageName) {
                        val lockedApps = prefs.getStringSet("locked_apps", setOf()) ?: setOf()

                        if (lockedApps.contains(topApp)) {
                            if (!unlockedApps.contains(topApp)) {
                                // This app is locked AND not temporarily unlocked
                                launchLockScreen(topApp)
                            }
                        }

                        // If user navigated away from a previously unlocked app, re-lock it
                        if (previousTopApp != null && previousTopApp != topApp && unlockedApps.contains(previousTopApp)) {
                            unlockedApps.remove(previousTopApp)
                        }

                        previousTopApp = topApp
                    }
                }
                delay(500)
            }
        }
    }

    private fun getTopApp(): String? {
        val endTime = System.currentTimeMillis()
        val beginTime = endTime - 5000
        val usageEvents = usageStatsManager.queryEvents(beginTime, endTime)
        val event = UsageEvents.Event()
        var topPackage: String? = null
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                topPackage = event.packageName
            }
        }
        return topPackage
    }

    private fun launchLockScreen(lockedPackageName: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("locked_app", lockedPackageName)
            putExtra("show_lock", true)
        }
        startActivity(intent)
    }

    /** Called from MainActivity when user successfully unlocks */
    fun onAppUnlocked(packageName: String) {
        unlockedApps.add(packageName)
    }

    private fun createNotification(): Notification {
        val channelId = "speedlock_service"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "SpeedLock Protection",
                NotificationManager.IMPORTANCE_LOW
            ).apply { setShowBadge(false) }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("SpeedLock Active")
            .setContentText("Protecting your apps")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceJob.cancel()
        eventReceiver?.let { unregisterReceiver(it) }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
