import SwiftUI

/// Harrier Central's watchOS companion — a remote control for a PackTrack
/// session running on the paired iPhone. The watch never touches GPS or the
/// network itself: state flows phone → watch over WatchConnectivity, and
/// button taps flow back as commands the phone executes.
@main
struct HarrierWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivity)
        }
    }
}
