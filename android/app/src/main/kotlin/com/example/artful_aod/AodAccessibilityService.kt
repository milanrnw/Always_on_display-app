package com.example.artful_aod // Make sure this matches your package name

import android.accessibilityservice.AccessibilityService
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AodAccessibilityService : AccessibilityService() {

    private val screenStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    Log.d("AodAccessibilityService", "Screen OFF detected. Starting AOD Service.")
                    startAodService()
                }
                Intent.ACTION_USER_PRESENT -> {
                    Log.d("AodAccessibilityService", "User UNLOCKED. Stopping AOD Service.")
                    stopAodService()
                }
            }
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We don't need to handle specific window events for now,
        // the broadcast receiver is more reliable for screen on/off.
    }

    override fun onInterrupt() {
        // Called when the service is interrupted
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("AodAccessibilityService", "Service connected. Registering screen state receiver.")
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT) // This is more reliable than SCREEN_ON for unlock
        }
        registerReceiver(screenStateReceiver, filter)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("AodAccessibilityService", "Service destroyed. Unregistering receiver.")
        unregisterReceiver(screenStateReceiver)
    }

    private fun startAodService() {
        val intent = Intent(this, AodService::class.java).apply {
            action = AodService.ACTION_START
        }
        startService(intent)
    }

    private fun stopAodService() {
        val intent = Intent(this, AodService::class.java).apply {
            action = AodService.ACTION_STOP
        }
        startService(intent)
    }
}