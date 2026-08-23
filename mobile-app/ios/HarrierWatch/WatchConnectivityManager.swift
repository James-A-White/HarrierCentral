import Foundation
import Combine
import WatchConnectivity
import WatchKit

/// Watch side of the phone↔watch bridge.
///
/// Protocol (dictionaries over WatchConnectivity):
/// - Phone → watch, via `updateApplicationContext` (latest-wins state):
///   { "tracking": Bool, "paused": Bool, "distanceKm": Double?,
///     "elapsedSec": Int, "eventName": String, "powerSaver": Bool }
/// - Watch → phone, via `sendMessage` (commands, reply = ack/refusal):
///   { "cmd": "mark", "type": "check" | "falseTrail" }
///   { "cmd": "onInn" }        — phone marks On Inn AND ends tracking
///   { "cmd": "lostQuery" }    — reply carries the latest lost-compass fix:
///   { "ok": Bool, "bearing": Double?, "distanceM": Double?,
///     "name": String?, "message": String? }
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // Mirrored session state (phone is the source of truth).
    @Published var isReachable = false
    @Published var isTracking = false
    @Published var isPaused = false
    @Published var distanceKm: Double?
    @Published var elapsedSec = 0
    @Published var eventName = ""
    @Published var powerSaver = false

    // Lost-compass vector (filled by lostQuery replies while LostView shows).
    @Published var lostBearing: Double?
    @Published var lostDistanceM: Double?
    @Published var lostName: String?
    @Published var lostMessage: String?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - Commands

    func sendMark(_ type: String) {
        sendCommand(["cmd": "mark", "type": type]) { ok in
            WKInterfaceDevice.current().play(ok ? .success : .failure)
        }
    }

    func sendOnInn() {
        sendCommand(["cmd": "onInn"]) { ok in
            WKInterfaceDevice.current().play(ok ? .success : .failure)
        }
    }

    func queryLost() {
        sendCommand(["cmd": "lostQuery"]) { _ in }
    }

    private func sendCommand(
        _ payload: [String: Any],
        completion: @escaping (Bool) -> Void
    ) {
        guard WCSession.default.isReachable else {
            completion(false)
            return
        }
        WCSession.default.sendMessage(payload, replyHandler: { reply in
            DispatchQueue.main.async {
                let ok = reply["ok"] as? Bool ?? false
                if payload["cmd"] as? String == "lostQuery" {
                    self.lostBearing = reply["bearing"] as? Double
                    self.lostDistanceM = reply["distanceM"] as? Double
                    self.lostName = reply["name"] as? String
                    self.lostMessage = reply["message"] as? String
                }
                completion(ok)
            }
        }, errorHandler: { _ in
            DispatchQueue.main.async { completion(false) }
        })
    }

    // MARK: - State ingestion

    private func apply(_ context: [String: Any]) {
        DispatchQueue.main.async {
            self.isTracking = context["tracking"] as? Bool ?? false
            self.isPaused = context["paused"] as? Bool ?? false
            self.distanceKm = context["distanceKm"] as? Double
            self.elapsedSec = context["elapsedSec"] as? Int ?? 0
            self.eventName = context["eventName"] as? String ?? ""
            self.powerSaver = context["powerSaver"] as? Bool ?? false
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
        // Pick up whatever state the phone last broadcast.
        apply(session.receivedApplicationContext)
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.isReachable = session.isReachable }
    }

    func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        apply(applicationContext)
    }
}
