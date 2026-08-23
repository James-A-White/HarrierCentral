import Flutter
import Foundation
import WatchConnectivity

/// Phone side of the watch companion bridge.
///
/// Dart ↔ native over the `harrier_central/watch` method channel:
/// - Dart → `updateState(map)`: broadcast session state to the watch via
///   `updateApplicationContext` (latest-wins; safe to call when no watch).
/// - Dart → `isPaired()`: whether a paired watch has the app installed.
/// - Native → Dart `watchCommand(map)`: a button tap on the watch. Dart's
///   returned map is relayed verbatim as the watch's reply (must contain
///   at least `ok: bool`; lostQuery replies add bearing/distance fields).
final class PhoneWatchBridge: NSObject {
    static let shared = PhoneWatchBridge()
    private var channel: FlutterMethodChannel?

    func start(messenger: FlutterBinaryMessenger) {
        guard WCSession.isSupported() else { return }
        channel = FlutterMethodChannel(
            name: "harrier_central/watch",
            binaryMessenger: messenger
        )
        channel?.setMethodCallHandler { [weak self] call, result in
            self?.handleFromFlutter(call, result: result)
        }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    private func handleFromFlutter(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "updateState":
            guard WCSession.default.activationState == .activated,
                  let args = call.arguments as? [String: Any] else {
                result(false)
                return
            }
            do {
                try WCSession.default.updateApplicationContext(args)
                result(true)
            } catch {
                // No paired watch / app not installed — not an error worth surfacing.
                result(false)
            }
        case "isPaired":
            result(WCSession.default.isPaired && WCSession.default.isWatchAppInstalled)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

extension PhoneWatchBridge: WCSessionDelegate {
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        // Channel calls must happen on the main thread; the watch's
        // sendMessage timeout is generous enough to absorb the hop.
        DispatchQueue.main.async {
            guard let channel = self.channel else {
                replyHandler(["ok": false])
                return
            }
            channel.invokeMethod("watchCommand", arguments: message) { response in
                if let dict = response as? [String: Any] {
                    replyHandler(dict)
                } else if let anyDict = response as? [AnyHashable: Any] {
                    var out: [String: Any] = [:]
                    for (k, v) in anyDict { out[String(describing: k)] = v }
                    replyHandler(out)
                } else if let ok = response as? Bool {
                    replyHandler(["ok": ok])
                } else {
                    replyHandler(["ok": false])
                }
            }
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate after a watch switch so the new watch keeps working.
        session.activate()
    }
}
