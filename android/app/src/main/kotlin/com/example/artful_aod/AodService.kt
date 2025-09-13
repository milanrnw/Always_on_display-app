package com.example.artful_aod // Make sure this matches your package name

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.core.app.NotificationCompat
import android.graphics.PixelFormat

class AodService : Service() {

    companion object {
        const val ACTION_START = "ACTION_START"
        const val ACTION_STOP = "ACTION_STOP"
        private const val NOTIFICATION_ID = 1
        private const val NOTIFICATION_CHANNEL_ID = "AOD_SERVICE_CHANNEL"
    }

    private lateinit var windowManager: WindowManager
    private var overlayView: FrameLayout? = null
    private var imageView: ImageView? = null
    private var hasContent: Boolean = false // To track if we have an image

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        Log.d("AodService", "Service Created.")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startAod()
            ACTION_STOP -> stopAod()
        }
        return START_STICKY
    }

    private fun startAod() {
        if (overlayView != null) {
            Log.w("AodService", "AOD start called but view already exists.")
            return
        }
        Log.d("AodService", "Starting AOD...")

        startForeground(NOTIFICATION_ID, createNotification())

        // Create the view first
        overlayView = FrameLayout(this)
        imageView = ImageView(this).apply {
            scaleType = ImageView.ScaleType.CENTER_CROP
            // The red background is now REMOVED
        }
        overlayView!!.addView(imageView)

        // Now load the settings and apply the image
        loadSettingsAndApplyImage()
        
        // If we failed to load any content, don't show the window.
        if (!hasContent) {
            Log.e("AodService", "No image content found. Stopping service.")
            stopSelf()
            return
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            PixelFormat.TRANSLUCENT
        )

        try {
            windowManager.addView(overlayView, params)
            Log.d("AodService", "Overlay view added to WindowManager.")
        } catch (e: Exception) {
            Log.e("AodService", "Error adding view to WindowManager", e)
        }
    }

    private fun stopAod() {
        if (overlayView == null) {
            Log.w("AodService", "AOD stop called but no view exists.")
            return
        }
        Log.d("AodService", "Stopping AOD...")

        try {
            windowManager.removeView(overlayView)
        } catch (e: Exception) {
            Log.e("AodService", "Error removing view", e)
        }
        overlayView = null
        stopForeground(true)
        stopSelf()
    }

    private fun loadSettingsAndApplyImage() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        hasContent = false // Reset status
        try {
            val base64Image = prefs.getString("flutter.image_data_base64", null)
            if (base64Image != null) {
                Log.d("AodService", "Found image data in SharedPreferences. Decoding...")
                val imageBytes = android.util.Base64.decode(base64Image, android.util.Base64.DEFAULT)
                val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
                if (bitmap != null) {
                    // --- THIS LINE IS NOW ACTIVE ---
                    imageView?.setImageBitmap(bitmap)
                    hasContent = true // We have a valid image!
                    Log.d("AodService", "Successfully decoded AND SET bitmap from data!")
                } else {
                     Log.e("AodService", "Failed to decode bitmap from data.")
                }
            } else {
                 Log.e("AodService", "No image data found in SharedPreferences.")
            }
        } catch (e: Exception) {
            Log.e("AodService", "Failed to parse settings or decode bitmap", e)
        }
    }

    private fun createNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Artful AOD Service",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Artful AOD is active")
            .setContentText("Displaying images over your lock screen.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("AodService", "Service Destroyed.")
        if (overlayView != null) {
            try {
                windowManager.removeView(overlayView)
            } catch (e: Exception) {}
        }
    }
}