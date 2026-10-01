package com.harriercentral.app

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Bundle
import android.provider.OpenableColumns
import java.io.File
import android.net.TrafficStats
import android.os.BatteryManager
import android.os.Build
import android.os.Debug
import android.os.PowerManager
import android.os.Process
import android.os.StatFs
import android.app.PendingIntent
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.ActivityRecognitionResult
import com.google.android.gms.location.DetectedActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Device sleep / wake since launch. Screen off/on broadcasts can only be
    // received by a dynamically registered receiver, so they are counted for
    // as long as this activity exists — which, with the location foreground
    // service holding the process during a tracked run, is the whole run.
    private var sleepCount = 0L
    private var wakeCount = 0L
    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> sleepCount++
                Intent.ACTION_SCREEN_ON -> wakeCount++
            }
        }
    }

    // A file handed to the app (Open with / Share of a .gpx). Copied into the
    // cache and its path handed to Flutter over harrier_central/incoming_file:
    //   Flutter → native  takePending()      path that arrived before Flutter was ready, or null
    //   native → Flutter  incomingFile(path)  a file that arrived while running
    // Mirrors ios/Runner/IncomingFileBridge.swift; Flutter decides what to do.
    private var incomingFileChannel: MethodChannel? = null
    private var pendingIncomingFile: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createHelpChannel()
        handleIncomingIntent(intent)
    }

    // The channel a Send Help push arrives on (2026-09-30). On Android 8+ a
    // channel owns its sound, so the API naming "sos" in the payload is not
    // enough: the channel must exist with res/raw/sos attached, and it must
    // exist BEFORE the first such push, which is why it is made at launch.
    // Creating an existing channel again is a no-op.
    private fun createHelpChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val sound = Uri.parse("android.resource://" + packageName + "/raw/sos")
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION_EVENT)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(
            "hc_help",
            "Calls for help on trail",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "A hasher pressed Send Help on a run you are on"
            setSound(sound, attrs)
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 400, 200, 400, 200, 400)
        }
        manager.createNotificationChannel(channel)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent)
    }

    private fun handleIncomingIntent(intent: Intent?) {
        if (intent == null) return
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> @Suppress("DEPRECATION") intent.getParcelableExtra(Intent.EXTRA_STREAM)
            else -> null
        } ?: return
        val path = copyToInbox(uri!!) ?: return
        // Consume it so a configuration change does not import it twice.
        intent.action = null
        pendingIncomingFile = path
        incomingFileChannel?.invokeMethod("incomingFile", path)
    }

    private fun copyToInbox(uri: Uri): String? {
        return try {
            var name = "shared.gpx"
            contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
                if (c.moveToFirst()) { val n = c.getString(0); if (!n.isNullOrBlank()) name = n }
            }
            if (name == "shared.gpx" && uri.lastPathSegment != null) name = uri.lastPathSegment!!
            name = name.substringAfterLast('/')
            val dir = File(cacheDir, "incoming").apply { mkdirs() }
            val dst = File(dir, name)
            contentResolver.openInputStream(uri)?.use { input -> dst.outputStream().use { input.copyTo(it) } }
                ?: return null
            dst.absolutePath
        } catch (_: Exception) {
            null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Motion activity for auto start (E5.F1.S15): Play Services Activity
        // Recognition, delivered to a receiver registered here and passed to
        // Dart as {type, confidence}. Started only while auto start is armed.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "harrier_central/activity")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> result.success(startActivityUpdates())
                    "stop" -> { stopActivityUpdates(); result.success(null) }
                    else -> result.notImplemented()
                }
            }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "harrier_central/activity/events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink?) { activitySink = sink }
                override fun onCancel(args: Any?) { activitySink = null }
            })
        incomingFileChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "harrier_central/incoming_file").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "takePending") {
                    val p = pendingIncomingFile
                    pendingIncomingFile = null
                    result.success(p)
                } else {
                    result.notImplemented()
                }
            }
        }
        registerReceiver(screenReceiver, IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        })
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
        // PackTrack pre-flight (E5.F1.S13): is Doze allowed to pause us, and
        // the two Settings pages that put it right. A GPS tracker's core
        // function is what battery optimisation breaks, which is the case
        // Play policy allows the direct request for.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "harrier_central/power")
            .setMethodCallHandler { call, result ->
                val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                when (call.method) {
                    "isIgnoringBatteryOptimizations" ->
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    "requestIgnoreBatteryOptimizations" -> {
                        val direct = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            .setData(Uri.parse("package:$packageName"))
                        try {
                            startActivity(direct)
                        } catch (_: Exception) {
                            // No handler for the direct ask (some OEM builds):
                            // the list page still lets them find the app.
                            startActivity(Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                        }
                        result.success(null)
                    }
                    // The phone's own Date & time page (E1.F1.S7 clock notice).
                    "openDateSettings" -> {
                        try {
                            startActivity(Intent(android.provider.Settings.ACTION_DATE_SETTINGS))
                        } catch (_: Exception) {
                            startActivity(Intent(android.provider.Settings.ACTION_SETTINGS))
                        }
                        result.success(null)
                    }
                    "openBatterySaverSettings" -> {
                        try {
                            startActivity(Intent(android.provider.Settings.ACTION_BATTERY_SAVER_SETTINGS))
                        } catch (_: Exception) {
                            startActivity(Intent(android.provider.Settings.ACTION_SETTINGS))
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── Motion activity (E5.F1.S15) ──────────────────────────────────────────
    private var activitySink: EventChannel.EventSink? = null
    private var activityIntent: PendingIntent? = null
    private val activityAction get() = "$packageName.ACTIVITY_UPDATE"

    private val activityReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (!ActivityRecognitionResult.hasResult(intent)) return
            val r = ActivityRecognitionResult.extractResult(intent) ?: return
            val a = r.mostProbableActivity
            val type = when (a.type) {
                DetectedActivity.IN_VEHICLE -> "in_vehicle"
                DetectedActivity.ON_BICYCLE -> "cycling"
                DetectedActivity.ON_FOOT -> "on_foot"
                DetectedActivity.WALKING -> "walking"
                DetectedActivity.RUNNING -> "running"
                DetectedActivity.STILL -> "still"
                else -> "unknown"
            }
            activitySink?.success(mapOf("type" to type, "confidence" to a.confidence))
        }
    }

    /** True when updates were requested; false when the API or permission is missing. */
    private fun startActivityUpdates(): Boolean {
        if (activityIntent != null) return true
        return try {
            if (Build.VERSION.SDK_INT >= 33) {
                registerReceiver(activityReceiver, IntentFilter(activityAction), Context.RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(activityReceiver, IntentFilter(activityAction))
            }
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0)
            val pi = PendingIntent.getBroadcast(
                this, 7101, Intent(activityAction).setPackage(packageName), flags)
            ActivityRecognition.getClient(this).requestActivityUpdates(10_000L, pi)
            activityIntent = pi
            true
        } catch (_: SecurityException) {
            try { unregisterReceiver(activityReceiver) } catch (_: IllegalArgumentException) {}
            false
        } catch (_: Exception) {
            try { unregisterReceiver(activityReceiver) } catch (_: IllegalArgumentException) {}
            false
        }
    }

    private fun stopActivityUpdates() {
        val pi = activityIntent ?: return
        try { ActivityRecognition.getClient(this).removeActivityUpdates(pi) } catch (_: Exception) {}
        try { unregisterReceiver(activityReceiver) } catch (_: IllegalArgumentException) {}
        activityIntent = null
    }

    override fun onDestroy() {
        stopActivityUpdates()
        try { unregisterReceiver(screenReceiver) } catch (_: IllegalArgumentException) {}
        super.onDestroy()
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
     *   sleepCount       ACTION_SCREEN_OFF broadcasts seen since launch
     *   wakeCount        ACTION_SCREEN_ON broadcasts seen since launch
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
            "sleepCount" to sleepCount,
            "wakeCount" to wakeCount,
        )
    }
}
