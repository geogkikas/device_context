package com.geogkikas.device_context

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.LocationManager
import android.os.*
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import kotlin.math.abs
import kotlin.math.sqrt
import android.provider.Settings

class DeviceContextPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "max.device.collector/context")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "getSensorData") {
            val map = HashMap<String, Any?>()

            val batteryIntent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1

            // Process Synchronous Categories
            if (call.argument<Boolean>("fetchDeviceInfo") == true) fetchDeviceInfo(map)
            if (call.argument<Boolean>("fetchBasic") == true) fetchBasicInfo(map, batteryIntent, status)
            if (call.argument<Boolean>("fetchThermal") == true) fetchThermalInfo(map, batteryIntent)

            if (call.argument<Boolean>("fetchElectrical") == true) fetchElectricalInfo(map, batteryIntent, batteryManager, status)

            if (call.argument<Boolean>("fetchHealth") == true) fetchHealthInfo(map, batteryIntent, batteryManager)
            if (call.argument<Boolean>("fetchLocation") == true) fetchLocationInfo(map)

            // Process Asynchronous Sensors
            val fetchEnv = call.argument<Boolean>("fetchEnvironment") == true
            val fetchMotion = call.argument<Boolean>("fetchMotion") == true

            if (fetchEnv || fetchMotion) {
                fetchSensorsAsync(map, fetchEnv, fetchMotion, result)
            } else {
                result.success(map)
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // --- SYNCHRONOUS FETCHERS ---

    private fun fetchDeviceInfo(map: HashMap<String, Any?>) {
        map["manufacturer"] = Build.MANUFACTURER
        map["model"] = Build.MODEL
        map["brand"] = Build.BRAND
        map["board"] = Build.BOARD
        map["hardware"] = Build.HARDWARE
        map["osName"] = "Android"
        map["osVersion"] = Build.VERSION.RELEASE
        map["deviceId"] = Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID)
    }

    private fun fetchBasicInfo(map: HashMap<String, Any?>, intent: Intent?, status: Int) {
        map["status"] = status
        map["batteryLevel"] = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        map["pluggedStatus"] = intent?.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
    }

    private fun fetchThermalInfo(map: HashMap<String, Any?>, intent: Intent?) {
        val temp = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -10000) ?: -10000
        if (temp != -10000) map["batteryTemp"] = temp / 10.0

        readCpuTemp()?.let { map["cpuTemp"] = it }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            map["thermalStatus"] = pm.currentThermalStatus
        }
    }

    private fun fetchElectricalInfo(map: HashMap<String, Any?>, intent: Intent?, bm: BatteryManager, status: Int) {
        val voltage = intent?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1) ?: -1
        if (voltage != -1) map["voltage"] = voltage

        val curApi = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW)
        if (curApi != Int.MIN_VALUE && curApi != 0) {
            map["currentNow_mA"] = enforceStandardSign(normalizeToMilliAmps(curApi), status)
        } else {
            readCurrentSysfs()?.let { map["currentNow_mA"] = enforceStandardSign(it, status) }
        }
    }

    private fun fetchHealthInfo(map: HashMap<String, Any?>, intent: Intent?, bm: BatteryManager) {
        map["health"] = intent?.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            map["cycleCount"] = intent?.getIntExtra(BatteryManager.EXTRA_CYCLE_COUNT, -1)
        }
        val charge = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)
        if (charge != Int.MIN_VALUE && charge != 0) map["chargeCounter_mAh"] = charge / 1000
    }

    private fun fetchLocationInfo(map: HashMap<String, Any?>) {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
            val loc = lm.getLastKnownLocation(LocationManager.PASSIVE_PROVIDER)
            loc?.let {
                map["latitude"] = it.latitude
                map["longitude"] = it.longitude
                map["altitude"] = it.altitude
            }
        }
    }

    // --- ASYNCHRONOUS SENSOR HANDLER ---

    private fun fetchSensorsAsync(map: HashMap<String, Any?>, fetchEnv: Boolean, fetchMotion: Boolean, result: Result) {
        var isResultSent = false
        val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        val checklist = mutableSetOf<Int>()

        if (fetchEnv) sensorManager.getDefaultSensor(Sensor.TYPE_LIGHT)?.let { checklist.add(Sensor.TYPE_LIGHT) }
        if (fetchMotion) {
            sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)?.let { checklist.add(Sensor.TYPE_ACCELEROMETER) }
            sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)?.let { checklist.add(Sensor.TYPE_PROXIMITY) }
        }

        if (checklist.isEmpty()) {
            result.success(map)
            return
        }

        // Helper to safely return result on main thread
        fun sendResultSafely() {
            if (isResultSent) return
            isResultSent = true
            Handler(Looper.getMainLooper()).post {
                try {
                    result.success(map)
                } catch (e: Exception) {
                    // Ignore if already replied
                }
            }
        }

        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent?) {
                if (isResultSent || event == null) return
                when (event.sensor.type) {
                    Sensor.TYPE_LIGHT -> map["light_lux"] = event.values[0]
                    Sensor.TYPE_PROXIMITY -> {
                        map["proximity_cm"] = event.values[0]
                        map["isCovered"] = event.values[0] < 2.0
                    }
                    Sensor.TYPE_ACCELEROMETER -> {
                        val x = event.values[0]; val y = event.values[1]; val z = event.values[2]
                        map["accelX"] = x; map["accelY"] = y; map["accelZ"] = z
                        map["posture"] = when {
                            z > 7.5 -> "Face Up"
                            z < -7.5 -> "Face Down"
                            y > 7.5 -> "Portrait"
                            else -> "Other"
                        }
                        val mag = sqrt((x*x + y*y + z*z).toDouble())
                        map["motionState"] = if (abs(mag - 9.81) > 1.0) "Moving" else "Still"
                    }
                }
                checklist.remove(event.sensor.type)
                if (checklist.isEmpty()) {
                    sensorManager.unregisterListener(this)
                    sendResultSafely()
                }
            }
            override fun onAccuracyChanged(s: Sensor?, a: Int) {}
        }

        checklist.forEach { sensorManager.registerListener(listener, sensorManager.getDefaultSensor(it), SensorManager.SENSOR_DELAY_UI) }

        // 500ms Failsafe Timeout
        Handler(Looper.getMainLooper()).postDelayed({
            if (!isResultSent) {
                sensorManager.unregisterListener(listener)
                sendResultSafely()
            }
        }, 500)
    }

    // --- MATH & HARDWARE HELPERS ---

    private fun normalizeToMilliAmps(raw: Int): Int = if (abs(raw) > 20000) raw / 1000 else raw

    private fun enforceStandardSign(ma: Int, s: Int): Int {
        val charging = (s == BatteryManager.BATTERY_STATUS_CHARGING || s == BatteryManager.BATTERY_STATUS_FULL)
        return if (charging && ma < 0) ma * -1 else if (!charging && ma > 0) ma * -1 else ma
    }

    private fun readCurrentSysfs(): Int? {
        val paths = arrayOf("/sys/class/power_supply/battery/current_now", "/sys/class/power_supply/battery/BatteryAverageCurrent")
        for (p in paths) { try { val f = File(p); if (f.exists()) return normalizeToMilliAmps(f.readText().trim().toInt()) } catch (e: Exception) {} }
        return null
    }

    private fun readCpuTemp(): Double? {
        try { val f = File("/sys/class/thermal/thermal_zone0/temp"); if (f.exists()) return f.readText().trim().toDouble() / 1000.0 } catch (e: Exception) {}
        return null
    }
}