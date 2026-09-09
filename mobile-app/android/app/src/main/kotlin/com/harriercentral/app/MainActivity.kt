package com.harriercentral.app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.TrafficStats
import android.os.BatteryManager
import android.os.Build
import android.os.Debug
import android.os.PowerManager
import android.os.Process
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Device metrics: one snapshot of memory, battery, power state and this
        // process's network counters on demand. Flutter folds it into the
        // [METRICS] session-log lines (DeviceMetricsService). No permissions.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "harrier_central/device_metrics")
            .setMethodCallHandler { call, result ->
                if (call.method == "snapshot") {
                    result.success(snapshot())
                } else {
                    result.notImplemented()
                }
            }
    }

    /**
     * Keys match the iOS AppDelegate snapshot so Dart reads one shape:
     *   availMem         bytes the OS reports as available (MemoryInfo.availMem)
     *   totalMem         physical RAM
     *   pssBytes         this process's proportional set size — the figure
     *                    Android itself judges the app by
     *   batteryLevel     0.0–1.0, or -1 when unknown
     *   batteryState     unplugged | charging | full | unknown
     *   chargeCounterUah battery charge counter in µAh, -1 if unsupported;
     *                    finer than the 1% level steps
     *   uidRx / uidTx    bytes this app's UID has received / sent since device
     *                    boot (TrafficStats), -1 if unsupported — includes
     *                    images and everything else, unlike the app-layer meter
     *   lowPower         Battery Saver on
     *   thermal          nominal | fair | serious | critical | unknown
     *   cpuTimeMs        CPU time this process has consumed
     *                    (Process.getElapsedCpuTime) — attributable to the
     *                    app alone, unlike the battery level
     *   diskFree         bytes available on the app's data volume
     */
    private fun snapshot(): Map<String, Any> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mem = ActivityManager.MemoryInfo()
        am.getMemoryInfo(mem)

        val pss = Debug.MemoryInfo()
        Debug.getMemoryInfo(pss)

        val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val capacity = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val chargeCounter = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)

        // Sticky broadcast: no receiver registration needed, no permission.
        val battery: Intent? = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val status = battery?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val state = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
            BatteryManager.BATTERY_STATUS_FULL -> "full"
            BatteryManager.BATTERY_STATUS_DISCHARGING,
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "unplugged"
            else -> "unknown"
        }

        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        val thermal = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            when (pm.currentThermalStatus) {
                PowerManager.THERMAL_STATUS_NONE, PowerManager.THERMAL_STATUS_LIGHT -> "nominal"
                PowerManager.THERMAL_STATUS_MODERATE -> "fair"
                PowerManager.THERMAL_STATUS_SEVERE -> "serious"
                PowerManager.THERMAL_STATUS_CRITICAL,
                PowerManager.THERMAL_STATUS_EMERGENCY,
                PowerManager.THERMAL_STATUS_SHUTDOWN -> "critical"
                else -> "unknown"
            }
        } else "unknown"

        val uid = applicationInfo.uid
        return mapOf(
            "availMem" to mem.availMem,
            "totalMem" to mem.totalMem,
            "pssBytes" to pss.totalPss.toLong() * 1024,
            "batteryLevel" to (if (capacity in 0..100) capacity / 100.0 else -1.0),
            "batteryState" to state,
            "chargeCounterUah" to (if (chargeCounter == Int.MIN_VALUE) -1L else chargeCounter.toLong()),
            "uidRx" to TrafficStats.getUidRxBytes(uid),
            "uidTx" to TrafficStats.getUidTxBytes(uid),
            "lowPower" to pm.isPowerSaveMode,
            "thermal" to thermal,
            "cpuTimeMs" to Process.getElapsedCpuTime(),
            "diskFree" to StatFs(filesDir.path).availableBytes,
        )
    }
}
