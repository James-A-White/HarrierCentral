import SwiftUI

/// Single-screen watch UI: session stats up top, mark buttons below.
/// Everything is driven by `WatchConnectivityManager`'s mirrored state —
/// if the phone isn't tracking, the buttons aren't shown.
struct ContentView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var showOnInnConfirm = false
    @State private var showLostView = false

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if connectivity.isTracking {
                    statsHeader
                    markButtons
                } else {
                    idleView
                }
            }
            .padding(.horizontal, 4)
        }
        .confirmationDialog(
            "On Inn?",
            isPresented: $showOnInnConfirm,
            titleVisibility: .visible
        ) {
            Button("I'm On Inn — end run", role: .destructive) {
                connectivity.sendOnInn()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Marks On Inn and stops tracking on your phone.")
        }
        .sheet(isPresented: $showLostView) {
            LostView()
                .environmentObject(connectivity)
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            Text("Harrier Central")
                .font(.headline)
            Text(connectivity.isReachable
                 ? "Start tracking a run on your phone and it will appear here."
                 : "Waiting for your phone…")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
    }

    // MARK: - Stats

    private var statsHeader: some View {
        VStack(spacing: 2) {
            if !connectivity.eventName.isEmpty {
                Text(connectivity.eventName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(distanceText)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("km")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            Text(elapsedText)
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(connectivity.isPaused ? .yellow : .secondary)
            if connectivity.isPaused {
                Text("Paused")
                    .font(.footnote)
                    .foregroundStyle(.yellow)
            }
        }
    }

    private var distanceText: String {
        guard let km = connectivity.distanceKm else { return "—" }
        let prefix = connectivity.powerSaver ? "~" : ""
        return prefix + String(format: "%.2f", km)
    }

    private var elapsedText: String {
        let s = connectivity.elapsedSec
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%02d:%02d", m, sec)
    }

    // MARK: - Buttons

    private var markButtons: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                markButton("Check", systemImage: "circle.circle", tint: .orange) {
                    connectivity.sendMark("check")
                }
                markButton("False", systemImage: "xmark.circle", tint: .red) {
                    connectivity.sendMark("falseTrail")
                }
            }
            HStack(spacing: 6) {
                markButton("I'm Lost", systemImage: "location.north.line", tint: .blue) {
                    showLostView = true
                }
                markButton("On Inn", systemImage: "flag.checkered", tint: .green) {
                    showOnInnConfirm = true
                }
            }
        }
    }

    private func markButton(
        _ label: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(label)
                    .font(.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
        .tint(tint)
    }
}

/// Vector-back-to-trail view. Polls the phone for the latest lost-compass
/// fix every 2 seconds while visible. The phone answers with a bearing and
/// distance to the nearest known trail point, or a front-runner message
/// when there is no track ahead to point at.
struct LostView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 8) {
            if let bearing = connectivity.lostBearing {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(bearing))
                    .animation(.easeInOut(duration: 0.4), value: bearing)
                if let distance = connectivity.lostDistanceM {
                    Text(distanceLabel(distance))
                        .font(.title3)
                        .monospacedDigit()
                }
                if let name = connectivity.lostName, !name.isEmpty {
                    Text(name)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                Image(systemName: "binoculars")
                    .font(.system(size: 34))
                    .foregroundStyle(.orange)
                Text(connectivity.lostMessage
                     ?? "Asking your phone for a bearing…")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onAppear { connectivity.queryLost() }
        .onReceive(timer) { _ in connectivity.queryLost() }
    }

    private func distanceLabel(_ meters: Double) -> String {
        meters >= 1000
            ? String(format: "%.1f km", meters / 1000)
            : String(format: "%.0f m", meters)
    }
}
