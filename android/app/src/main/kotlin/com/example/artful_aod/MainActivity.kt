package com.example.artful_aod // Make sure this matches your package name

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.text.TextUtils
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.artfulaod.settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                "isAccessibilityServiceEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = "$packageName/${AodAccessibilityService::class.java.canonicalName}"
        Log.d("MainActivity", "Checking for service: $service")
        try {
            // This string can be null if no services are enabled.
            val enabledServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )

            // CRASH FIX: If the string is null or empty, we know our service isn't enabled.
            if (enabledServices.isNullOrEmpty()) {
                Log.d("MainActivity", "No accessibility services enabled.")
                return false
            }

            val splitter = TextUtils.SimpleStringSplitter(':')
            splitter.setString(enabledServices)
            while (splitter.hasNext()) {
                if (splitter.next().equals(service, ignoreCase = true)) {
                    Log.d("MainActivity", "Service is enabled.")
                    return true
                }
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error checking accessibility service", e)
        }
        Log.d("MainActivity", "Service is disabled.")
        return false
    }
}