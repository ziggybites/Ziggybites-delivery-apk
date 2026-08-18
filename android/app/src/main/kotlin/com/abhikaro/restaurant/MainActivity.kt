package com.ziggybites.delivery

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ziggybites.delivery/geolocation"
    private val LOCATION_PERMISSION_REQUEST_CODE = 1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Geolocation channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkLocationPermission" -> {
                    val hasPermission = checkLocationPermission()
                    result.success(hasPermission)
                }
                "requestLocationPermission" -> {
                    requestLocationPermission()
                    result.success(true)
                }
                "bringToFront" -> {
                    val intent = packageManager.getLaunchIntentForPackage(packageName)
                    if (intent != null) {
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        startActivity(intent)
                        result.success(true)
                    } else {
                        // Fallback to existing activity if launch intent is null
                        val fallbackIntent = Intent(this, MainActivity::class.java)
                        fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        startActivity(fallbackIntent)
                        result.success(true)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestLocationPermission() {
        if (!checkLocationPermission()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ),
                LOCATION_PERMISSION_REQUEST_CODE
            )
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!checkLocationPermission()) {
            requestLocationPermission()
        }
    }
}
