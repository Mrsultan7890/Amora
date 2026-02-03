package com.amora.app

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.content.Context
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import androidx.core.app.NotificationCompat
import android.os.Build
import kotlin.math.sqrt

class EmergencyBackgroundService : Service(), SensorEventListener {
    
    private lateinit var sensorManager: SensorManager
    private var accelerometer: Sensor? = null
    private var lastShakeTime: Long = 0
    private val shakeThreshold = 15.0
    private val shakeCooldown = 30000L // 30 seconds
    
    companion object {
        const val CHANNEL_ID = "emergency_service_channel"
        const val NOTIFICATION_ID = 1001
    }
    
    override fun onCreate() {
        super.onCreate()
        println("🚨 EmergencyBackgroundService: Service created")
        
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())
        
        // Register sensor listener
        accelerometer?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
            println("🚨 EmergencyBackgroundService: Accelerometer registered")
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        println("🚨 EmergencyBackgroundService: Service started")
        return START_STICKY // Restart if killed
    }
    
    override fun onDestroy() {
        super.onDestroy()
        println("🚨 EmergencyBackgroundService: Service destroyed")
        sensorManager.unregisterListener(this)
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onSensorChanged(event: SensorEvent?) {
        event?.let {
            if (it.sensor.type == Sensor.TYPE_ACCELEROMETER) {
                val acceleration = sqrt(
                    (it.values[0] * it.values[0] + 
                     it.values[1] * it.values[1] + 
                     it.values[2] * it.values[2]).toDouble()
                )
                
                if (acceleration > shakeThreshold) {
                    val currentTime = System.currentTimeMillis()
                    
                    if (currentTime - lastShakeTime > shakeCooldown) {
                        lastShakeTime = currentTime
                        println("🚨 BACKGROUND SHAKE DETECTED! Acceleration: $acceleration")
                        triggerEmergency()
                    }
                }
            }
        }
    }
    
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not needed
    }
    
    private fun triggerEmergency() {
        println("🚨 BACKGROUND EMERGENCY TRIGGERED!")
        
        // Launch main app to handle emergency
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        launchIntent?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            putExtra("emergency_trigger", true)
            startActivity(this)
        }
        
        // Also trigger native emergency actions
        // This would call the same SMS/Call methods from MainActivity
        // For now, just log
        println("🚨 Background emergency actions would be triggered here")
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Emergency Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Amora emergency shake detection service"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("Amora Emergency Active")
        .setContentText("Shake detection is running in background")
        .setSmallIcon(android.R.drawable.ic_menu_compass)
        .setOngoing(true)
        .setAutoCancel(false)
        .build()
}