package com.example.artful_aod // <<< Make sure this matches your package name

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.artfulaod.service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val serviceIntent = Intent(this, AodService::class.java)

            when (call.method) {
                "startService" -> {
                    // NEW: Get the arguments from Flutter and put them in the intent
                    val imagePaths = call.argument<ArrayList<String>>("imagePaths")
                    val frequency = call.argument<Int>("frequency")

                    serviceIntent.putStringArrayListExtra("imagePaths", imagePaths)
                    serviceIntent.putExtra("frequency", frequency)
                    
                    startService(serviceIntent)
                    result.success("Native AOD Service Started with data")
                }
                "stopService" -> {
                    stopService(serviceIntent)
                    result.success("Native AOD Service Stopped")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}