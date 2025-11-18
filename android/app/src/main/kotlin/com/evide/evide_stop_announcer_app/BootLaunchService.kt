package com.evide.evide_stop_announcer_app

import android.app.Notification
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat

class BootLaunchService : Service() {
    override fun onCreate() {
        super.onCreate()

        val notification: Notification = NotificationCompat.Builder(this, "KioskModeChannel")
            .setContentTitle("Kiosk Starting")
            .setContentText("Launching kiosk app...")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .build()

        startForeground(2001, notification)

        Handler(Looper.getMainLooper()).postDelayed({
            try {
                val intent = Intent(this, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                }
                startActivity(intent)
                Log.d("BootLaunchService", "✅ MainActivity launched after boot")
            } catch (e: Exception) {
                Log.e("BootLaunchService", "❌ Error launching app: ${e.message}")
            } finally {
                stopSelf()
            }
        }, 4000)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
