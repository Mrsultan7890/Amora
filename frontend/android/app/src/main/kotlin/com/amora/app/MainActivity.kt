package com.amora.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.telephony.SmsManager
import android.provider.Settings
import android.os.PowerManager
import android.content.Context
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "amora/sms"
    private val REQUEST_CODE_PERMISSIONS = 1001
    private lateinit var bluetoothEmergencyManager: BluetoothEmergencyManager
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize Bluetooth emergency manager
        bluetoothEmergencyManager = BluetoothEmergencyManager(this)
        
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
                "startBackgroundService" -> {
                    startEmergencyBackgroundService()
                    result.success(true)
                }
                "stopBackgroundService" -> {
                    stopEmergencyBackgroundService()
                    result.success(true)
                }
                "isBluetoothEnabled" -> {
                    val enabled = bluetoothEmergencyManager.isBluetoothEnabled()
                    result.success(enabled)
                }
                "enableBluetooth" -> {
                    val enabled = bluetoothEmergencyManager.enableBluetooth()
                    result.success(enabled)
                }
                "broadcastEmergency" -> {
                    val emergencyData = call.arguments as Map<String, Any>
                    bluetoothEmergencyManager.broadcastEmergency(emergencyData)
                    result.success(true)
                }
                "startEmergencyListener" -> {
                    bluetoothEmergencyManager.startEmergencyListener()
                    result.success(true)
                }
                "stopEmergencyListener" -> {
                    bluetoothEmergencyManager.stopEmergencyListener()
                    result.success(true)
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
                println("Audio file not found: $audioFilePath")
                return false
            }
            
            println("Attempting to send voice message: ${audioFile.name} (${audioFile.length()} bytes)")
            
            // For Android, MMS is complex and requires carrier support
            // Most reliable approach is to send detailed SMS with file info
            val detailedMessage = """$message
            
🎤 EMERGENCY VOICE MESSAGE RECORDED
            
File: ${audioFile.name}
Duration: ${audioFile.length() / 1024}s (approx)
Size: ${audioFile.length()} bytes
            
⚠️ I cannot send the audio file directly via SMS.
            
PLEASE CALL ME BACK IMMEDIATELY!
            
This is a real emergency situation.
            
Time: ${java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(java.util.Date())}
            """.trimIndent()
            
            // Send enhanced SMS with voice message details
            sendSms(phoneNumber, detailedMessage)
        } catch (e: Exception) {
            println("MMS send error: ${e.message}")
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
    
    private fun startEmergencyBackgroundService() {
        val serviceIntent = Intent(this, EmergencyBackgroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
        println("🚨 Emergency background service started")
    }
    
    private fun stopEmergencyBackgroundService() {
        val serviceIntent = Intent(this, EmergencyBackgroundService::class.java)
        stopService(serviceIntent)
        println("🚨 Emergency background service stopped")
    }
}