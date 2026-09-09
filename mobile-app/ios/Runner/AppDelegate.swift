import UIKit
import Flutter
import MetricKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let metricKitChannelName = "harrier_central/metrickit"
  private let deviceMetricsChannelName = "harrier_central/device_metrics"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Apple Watch companion bridge — mirrors PackTrack session state to the
    // watch and executes mark commands sent from it. No-op when unsupported.
    if let controller = window?.rootViewController as? FlutterViewController {
      PhoneWatchBridge.shared.start(messenger: controller.binaryMessenger)
    }

    // MetricKit: capture crash / hang / CPU-disk exception diagnostics AND the
    // daily app-exit metrics (including memory-pressure / memory-limit "OOM"
    // terminations) that Xcode Organizer frequently does not surface. Payloads
    // are delivered on the launch AFTER the event; we persist them natively and
    // Flutter drains them into the server harvest at boot.
    if #available(iOS 14.0, *) {
      MetricKitReporter.shared.start()

      if let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(
          name: metricKitChannelName,
          binaryMessenger: controller.binaryMessenger
        )
        channel.setMethodCallHandler { call, result in
          if call.method == "drainDiagnostics" {
            result(MetricKitReporter.shared.drain())
          } else {
            result(FlutterMethodNotImplemented)
          }
        }
      }
    }

    // Device metrics: one snapshot of memory headroom, battery and power
    // state on demand. Flutter folds it into the [METRICS] session-log lines
    // (DeviceMetricsService). Cheap, synchronous, no permissions.
    if let controller = window?.rootViewController as? FlutterViewController {
      UIDevice.current.isBatteryMonitoringEnabled = true
      let channel = FlutterMethodChannel(
        name: deviceMetricsChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "snapshot" {
          result(DeviceMetricsSnapshot.take())
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// MARK: - Device metrics

/// What iOS will tell an app about its own footprint, in one dictionary.
/// Keys match the Android MainActivity snapshot so Dart reads one shape:
///   availMem        bytes the OS says this process may still allocate
///                   (os_proc_available_memory, iOS 13+) — the jetsam headroom
///   totalMem        physical RAM
///   pssBytes        -1 (Android-only concept; Dart uses RSS on iOS)
///   batteryLevel    0.0–1.0, or -1 when unknown (simulator)
///   batteryState    unplugged | charging | full | unknown
///   chargeCounterUah -1 (Android-only)
///   uidRx / uidTx   -1 — iOS has no per-app network counter
///   lowPower        Low Power Mode on
///   thermal         nominal | fair | serious | critical
enum DeviceMetricsSnapshot {
  static func take() -> [String: Any] {
    let device = UIDevice.current
    let info = ProcessInfo.processInfo

    var avail: Int64 = -1
    if #available(iOS 13.0, *) {
      avail = Int64(os_proc_available_memory())
    }

    let state: String
    switch device.batteryState {
    case .unplugged: state = "unplugged"
    case .charging: state = "charging"
    case .full: state = "full"
    default: state = "unknown"
    }

    let thermal: String
    switch info.thermalState {
    case .nominal: thermal = "nominal"
    case .fair: thermal = "fair"
    case .serious: thermal = "serious"
    case .critical: thermal = "critical"
    @unknown default: thermal = "unknown"
    }

    return [
      "availMem": avail,
      "totalMem": Int64(info.physicalMemory),
      "pssBytes": Int64(-1),
      "batteryLevel": Double(device.batteryLevel),
      "batteryState": state,
      "chargeCounterUah": Int64(-1),
      "uidRx": Int64(-1),
      "uidTx": Int64(-1),
      "lowPower": info.isLowPowerModeEnabled,
      "thermal": thermal,
    ]
  }
}

// MARK: - MetricKit

/// Subscribes to MetricKit and persists received diagnostic + metric payloads
/// (crashes, hangs, CPU/disk exceptions, and daily app-exit metrics including
/// memory-pressure / memory-limit terminations) as JSON lines to a file in the
/// caches directory. Flutter drains the file on boot via the
/// `harrier_central/metrickit` channel and ships each payload to the server
/// harvest (HC.ClientErrorLog). Delivery is one launch late — the same model as
/// the on-device breadcrumb harvest.
@available(iOS 14.0, *)
final class MetricKitReporter: NSObject, MXMetricManagerSubscriber {
  static let shared = MetricKitReporter()

  private var fileURL: URL {
    let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    return dir.appendingPathComponent("metrickit_pending.jsonl")
  }

  func start() {
    MXMetricManager.shared.add(self)
  }

  // Crashes, hangs, CPU/disk exceptions (iOS 14+).
  func didReceive(_ payloads: [MXDiagnosticPayload]) {
    for payload in payloads {
      append(payload.jsonRepresentation(), kind: "diagnostic")
    }
  }

  // Daily metrics, incl. applicationExitMetrics (memory-pressure / limit exits).
  func didReceive(_ payloads: [MXMetricPayload]) {
    for payload in payloads {
      append(payload.jsonRepresentation(), kind: "metric")
    }
  }

  private func append(_ data: Data, kind: String) {
    // jsonRepresentation() returns PRETTY-PRINTED (multi-line) JSON, but this
    // file is JSONL — one record per line. Re-serialize to compact single-line
    // JSON; if that fails, flatten newlines so a record can never span lines
    // (a multi-line record gets split into hundreds of fragment rows by drain()).
    var payloadData = data
    if let obj = try? JSONSerialization.jsonObject(with: data),
       let compact = try? JSONSerialization.data(withJSONObject: obj) {
      payloadData = compact
    }
    guard var json = String(data: payloadData, encoding: .utf8), !json.isEmpty else { return }
    json = json.replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "\r", with: " ")
    let line = "{\"kind\":\"\(kind)\",\"payload\":\(json)}\n"
    guard let bytes = line.data(using: .utf8) else { return }
    let url = fileURL
    if FileManager.default.fileExists(atPath: url.path),
       let handle = try? FileHandle(forWritingTo: url) {
      defer { try? handle.close() }
      handle.seekToEndOfFile()
      handle.write(bytes)
    } else {
      try? bytes.write(to: url)
    }
  }

  /// Returns all pending payload lines and clears the file.
  func drain() -> [String] {
    let url = fileURL
    guard let content = try? String(contentsOf: url, encoding: .utf8) else {
      return []
    }
    try? FileManager.default.removeItem(at: url)
    return content.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
  }
}
