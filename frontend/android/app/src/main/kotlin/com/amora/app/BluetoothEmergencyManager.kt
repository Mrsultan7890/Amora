package com.amora.app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.app.NotificationManager
import android.app.NotificationChannel
import androidx.core.app.NotificationCompat
import android.net.Uri
import android.os.Build
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.*
import org.json.JSONObject

class BluetoothEmergencyManager(private val context: Context) {
    
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var serverSocket: BluetoothServerSocket? = null
    private var isListening = false
    
    companion object {
        private const val SERVICE_UUID = "550e8400-e29b-41d4-a716-446655440000"
        private const val SERVICE_NAME = "AmoraEmergency"
        private const val CHANNEL_ID = "bluetooth_emergency_channel"
        private const val NOTIFICATION_ID = 2001
    }
    
    private val deviceFoundReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            when (intent.action) {
                BluetoothDevice.ACTION_FOUND -> {
                    val device: BluetoothDevice? = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
                    device?.let { sendEmergencyToDevice(it) }
                }
            }
        }
    }
    
    fun isBluetoothEnabled(): Boolean {
        return bluetoothAdapter?.isEnabled == true
    }
    
    fun enableBluetooth(): Boolean {
        return try {
            if (bluetoothAdapter?.isEnabled == false) {
                val enableBtIntent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
                enableBtIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(enableBtIntent)
            }
            true
        } catch (e: Exception) {
            false
        }
    }
    
    fun broadcastEmergency(emergencyData: Map<String, Any>) {
        if (!isBluetoothEnabled()) {
            println("❌ Bluetooth not enabled")
            return
        }
        
        try {
            // Make device discoverable
            makeDiscoverable()
            
            // Start discovery to find nearby devices
            startDiscovery(emergencyData)
            
            println("🚨 Emergency broadcast started")
        } catch (e: Exception) {
            println("❌ Error broadcasting emergency: ${e.message}")
        }
    }
    
    private fun makeDiscoverable() {
        try {
            val discoverableIntent = Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE)
            discoverableIntent.putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300)
            discoverableIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(discoverableIntent)
        } catch (e: Exception) {
            println("Error making discoverable: ${e.message}")
        }
    }
    
    private fun startDiscovery(emergencyData: Map<String, Any>) {
        try {
            // Register receiver for device discovery
            val filter = IntentFilter(BluetoothDevice.ACTION_FOUND)
            context.registerReceiver(deviceFoundReceiver, filter)
            
            // Store emergency data for sending
            currentEmergencyData = emergencyData
            
            // Start discovery
            bluetoothAdapter?.startDiscovery()
            
            println("📡 Bluetooth discovery started")
        } catch (e: Exception) {
            println("Error starting discovery: ${e.message}")
        }
    }
    
    private var currentEmergencyData: Map<String, Any>? = null
    
    private fun sendEmergencyToDevice(device: BluetoothDevice) {
        Thread {
            try {
                val socket = device.createRfcommSocketToServiceRecord(UUID.fromString(SERVICE_UUID))
                socket.connect()
                
                val emergencyJson = JSONObject(currentEmergencyData ?: return@Thread)
                val message = emergencyJson.toString()
                
                socket.outputStream.write(message.toByteArray())
                socket.close()
                
                println("✅ Emergency sent to ${device.name}")
            } catch (e: Exception) {
                println("❌ Failed to send to ${device.name}: ${e.message}")
            }
        }.start()
    }
    
    fun startEmergencyListener() {
        if (isListening) return
        
        Thread {
            try {
                serverSocket = bluetoothAdapter?.listenUsingRfcommWithServiceRecord(
                    SERVICE_NAME, 
                    UUID.fromString(SERVICE_UUID)
                )
                
                isListening = true
                println("📡 Emergency listener started")
                
                while (isListening) {
                    try {
                        val socket = serverSocket?.accept()
                        socket?.let { handleIncomingEmergency(it) }
                    } catch (e: IOException) {
                        if (isListening) {
                            println("Error accepting connection: ${e.message}")
                        }
                        break
                    }
                }
            } catch (e: Exception) {
                println("Error starting listener: ${e.message}")
            }
        }.start()
    }
    
    private fun handleIncomingEmergency(socket: BluetoothSocket) {
        Thread {
            try {
                val buffer = ByteArray(1024)
                val bytes = socket.inputStream.read(buffer)
                val message = String(buffer, 0, bytes)
                
                val emergencyData = JSONObject(message)
                showEmergencyNotification(emergencyData)
                
                socket.close()
                println("📱 Emergency received and processed")
            } catch (e: Exception) {
                println("Error handling emergency: ${e.message}")
            }
        }.start()
    }
    
    private fun showEmergencyNotification(emergencyData: JSONObject) {
        try {
            createNotificationChannel()
            
            val phone = emergencyData.getString("phone")
            val message = emergencyData.getString("message")
            val latitude = emergencyData.getDouble("latitude")
            val longitude = emergencyData.getDouble("longitude")
            
            // Call intent
            val callIntent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$phone")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            
            // Location intent
            val locationIntent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("geo:$latitude,$longitude?q=$latitude,$longitude(Emergency Location)")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            
            val notification = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("🚨 EMERGENCY ALERT RECEIVED!")
                .setContentText("📞 $phone - $message")
                .setStyle(NotificationCompat.BigTextStyle()
                    .bigText("📞 Phone: $phone\n📍 Location: $latitude, $longitude\n💬 $message\n\nTap to call or view location"))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(false)
                .setOngoing(true)
                .addAction(android.R.drawable.ic_menu_call, "CALL NOW", 
                    android.app.PendingIntent.getActivity(context, 0, callIntent, 
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE))
                .addAction(android.R.drawable.ic_menu_mylocation, "VIEW LOCATION", 
                    android.app.PendingIntent.getActivity(context, 1, locationIntent, 
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE))
                .build()
            
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)
            
            println("🚨 Emergency notification shown")
        } catch (e: Exception) {
            println("Error showing notification: ${e.message}")
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Bluetooth Emergency Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Emergency alerts received via Bluetooth"
                enableVibration(true)
                setShowBadge(true)
            }
            
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    fun stopEmergencyListener() {
        try {
            isListening = false
            serverSocket?.close()
            bluetoothAdapter?.cancelDiscovery()
            
            try {
                context.unregisterReceiver(deviceFoundReceiver)
            } catch (e: Exception) {
                // Receiver might not be registered
            }
            
            println("📡 Emergency listener stopped")
        } catch (e: Exception) {
            println("Error stopping listener: ${e.message}")
        }
    }
}