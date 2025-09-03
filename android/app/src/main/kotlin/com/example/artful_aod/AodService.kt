package com.example.artful_aod // <<< Make sure this matches your package name

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.TextView
import androidx.core.app.NotificationCompat

class AodService : Service() {

    private var windowManager: WindowManager? = null
    private var aodView: TextView? = null

    private var imagePaths: List<String>? = null
    private var frequency: Int = 5

    // --- NEW: Constants for the Foreground Service Notification ---
    private val NOTIFICATION_CHANNEL_ID = "artful_aod_service_channel"
    private val NOTIFICATION_ID = 1

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("AodService", "onStartCommand received")

        // --- NEW: Start the service in the foreground ---
        createNotificationChannel()
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        imagePaths = intent?.getStringArrayListExtra("imagePaths")
        frequency = intent?.getIntExtra("frequency", 5) ?: 5
        Log.d("AodService", "Data received: ${imagePaths?.size} images, $frequency min frequency")

        return START_STICKY
    }

    private val broadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            Log.d("AodService", "Broadcast received: ${intent?.action}")
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> showAodView()
                Intent.ACTION_USER_PRESENT -> hideAodView()
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d("AodService", "onCreate")
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(broadcastReceiver, filter)
    }


// In AodService.kt

    private fun showAodView() {
        Log.d("AodService", "showAodView called")
        if (aodView != null) return

        val textToShow = """
            AOD Active
            ${imagePaths?.size ?: 0} images selected
            Frequency: $frequency minutes
        """.trimIndent()

        aodView = TextView(this).apply {
            text = textToShow
            setTextColor(Color.WHITE)
            textSize = 24f
            gravity = Gravity.CENTER
            setLineSpacing(1.2f, 1.2f)
        }

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        
        // --- THIS IS THE FINAL AND CORRECT CONFIGURATION ---
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY, // Revert to the allowed type
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                    or WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                    or WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                    or WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD, // The key new flag
            PixelFormat.TRANSLUCENT
        )

        try {
            windowManager?.addView(aodView, params)
            Log.d("AodService", "AOD View added to WindowManager")
        } catch (e: Exception) {
            Log.e("AodService", "Error adding view to WindowManager", e)
        }
    }

    private fun hideAodView() {
        Log.d("AodService", "hideAodView called")
        if (aodView != null) {
            try {
                windowManager?.removeView(aodView)
                aodView = null
                Log.d("AodService", "AOD View removed from WindowManager")
            } catch (e: Exception) {
                Log.e("AodService", "Error removing view from WindowManager", e)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("AodService", "onDestroy")
        unregisterReceiver(broadcastReceiver)
        hideAodView()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // --- NEW: Methods for creating the persistent notification ---
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Artful AOD Service Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Artful AOD")
            .setContentText("Always-On Display service is active.")
            .setSmallIcon(R.mipmap.ic_launcher) // Uses the default app icon
            .build()
    }
}