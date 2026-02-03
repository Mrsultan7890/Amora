package com.amora.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.telephony.SmsManager
import android.provider.Settings
import android.os.PowerManager
import android.content.Context
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "amora/sms"
    private val REQUEST_CODE_PERMISSIONS = 1001
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "sendSms" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val message = call.argument<String>("message")
                    
                    if (phoneNumber != null && message != null) {
                        val success = sendSms(phoneNumber, message)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Phone number and message are required", null)
                    }
                }
                "sendMmsWithAudio" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val audioFilePath = call.argument<String>("audioFilePath")
                    val message = call.argument<String>("message")
                    
                    if (phoneNumber != null && audioFilePath != null) {
                        val success = sendMmsWithAudio(phoneNumber, audioFilePath, message ?: "Emergency Voice Message")
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Phone number and audio file path are required", null)
                    }
                }
                "makeCall" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    
                    if (phoneNumber != null) {
                        val success = makeCall(phoneNumber)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENTS", "Phone number is required", null)
                    }
                }
                "requestSpecialPermissions" -> {
                    requestSpecialPermissions()
                    result.success(true)
                }
                "checkPermissions" -> {
                    val hasPermissions = checkAllPermissions()
                    result.success(hasPermissions)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun sendSms(phoneNumber: String, message: String): Boolean {
        return try {
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED) {
                val smsManager = SmsManager.getDefault()
                
                // Split long messages
                val parts = smsManager.divideMessage(message)
                if (parts.size > 1) {
                    smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
                } else {
                    smsManager.sendTextMessage(phoneNumber, null, message, null, null)
                }
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }
    
    private fun sendMmsWithAudio(phoneNumber: String, audioFilePath: String, message: String): Boolean {
        return try {
            val audioFile = File(audioFilePath)
            if (!audioFile.exists()) {
                return false
            }
            
            // For now, send SMS with file info since MMS is complex
            val fallbackMessage = "$message\n\nVoice message recorded but cannot be sent directly via MMS.\nFile: ${audioFile.name}\nSize: ${audioFile.length()} bytes\nPlease call back immediately!"
            
            sendSms(phoneNumber, fallbackMessage)
        } catch (e: Exception) {
            false
        }
    }
    
    private fun makeCall(phoneNumber: String): Boolean {
        return try {
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED) {
                val callIntent = Intent(Intent.ACTION_CALL)
                callIntent.data = Uri.parse("tel:$phoneNumber")
                callIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(callIntent)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }
    
    private fun requestSpecialPermissions() {
        // Request battery optimization exemption
        if (!isIgnoringBatteryOptimizations()) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        }
        
        // Request system alert window permission
        if (!Settings.canDrawOverlays(this)) {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        }
    }
    
    private fun isIgnoringBatteryOptimizations(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }
    
    private fun checkAllPermissions(): Boolean {
        val smsPermission = ActivityCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED
        val callPermission = ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED
        val batteryOptimization = isIgnoringBatteryOptimizations()
        val overlayPermission = Settings.canDrawOverlays(this)
        
        return smsPermission && callPermission && batteryOptimization && overlayPermission
    }
}