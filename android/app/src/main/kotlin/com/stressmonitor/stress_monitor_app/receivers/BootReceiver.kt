package com.stressmonitor.stress_monitor_app.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import com.stressmonitor.stress_monitor_app.services.SensorForegroundService

/**
 * Receiver to optionally restart the foreground service on device boot
 * This ensures continuous monitoring if the user has enabled it
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Check if auto-start is enabled in preferences
            val prefs = context.getSharedPreferences("stress_monitor_prefs", Context.MODE_PRIVATE)
            val autoStart = prefs.getBoolean("auto_start_service", false)

            if (autoStart) {
                val serviceIntent = Intent(context, SensorForegroundService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
