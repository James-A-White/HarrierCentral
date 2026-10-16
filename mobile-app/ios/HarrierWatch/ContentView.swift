import SwiftUI

/// Single-screen watch UI: session stats up top, mark buttons below.
/// Everything is driven by `WatchConnectivityManager`'s mirrored state —
/// if the phone isn't tracking, the buttons aren't shown.
///
/// THE TRACKING SCREEN NEVER SCROLLS (James, 2026-10-16, BT-2: on an Ultra 3
/// it needed scrolling). It is a fixed layout sized to the screen: a compact
/// header (your distance and checks, then the elapsed time) over a 2×2 grid
/// that takes the rest. Not scrolling is also what keeps taps honest: plain
/// ScrollView + Button on watchOS mis-maps tap coordinates when content is
/// partially scrolled (Check triggered I'm Lost), which is why this used to
/// be a `List`. A layout that cannot scroll has no partial offset. A fifth
/// button needs a new design, not a new row.
///
/// The idle and summary screens still use a `List` (no buttons mid-run, and
/// the summary can be taller than the screen).
struct ContentView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var showOnInnConfirm = false
    @State private var showLostView = false

    var body: some View {
        Group {
            if connectivity.isTracking {
                trackingView
            } else {
                List {
                    if connectivity.phase == "summary" {
                        summaryView
                            .listRowBackground(Color.clear)
                    } else {
                        idleView
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
            }
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

    // MARK: - Rows

    private typealias ActionSpec = (
        label: String, icon: String, tint: Color, action: () -> Void
    )

    /// The tracking screen: header, then the four buttons sharing whatever
    /// height is left, on every watch size. The text size is capped so a
    /// large accessibility setting cannot push the grid off the screen.
    private var trackingView: some View {
        VStack(spacing: 4) {
            statsHeader
            HStack(spacing: 4) {
                gridButton(
                    (connectivity.checkLabel ?? "Check", "circle.circle", .orange,
                     { connectivity.sendMark("check") }),
                    glyph: connectivity.checkGlyph, markText: connectivity.checkText)
                gridButton(
                    (connectivity.falseLabel ?? "False", "xmark.circle", .red,
                     { connectivity.sendMark("falseTrail") }),
                    glyph: connectivity.falseGlyph, markText: connectivity.falseText)
            }
            HStack(spacing: 4) {
                gridButton(("I'm Lost", "location.north.line", .blue,
                            { showLostView = true }))
                gridButton(("On Inn", "flag.checkered", .green,
                            { showOnInnConfirm = true }))
            }
        }
        .padding(.horizontal, 2)
        .dynamicTypeSize(...DynamicTypeSize.large)
        // Use the corners too: the clock sits over the top edge on its own.
        .ignoresSafeArea(edges: .bottom)
    }

    /// [glyph]/[markText] carry the kennel's own mark for this button, sent by
    /// the phone from its configured trail slots. A glyph wins, then a short
    /// text mark (e.g. "FT"), and only then the built-in SF Symbol — so a
    /// watch that has never received them, or is showing a kennel with no
    /// matching slot, looks exactly as it did before.
    private func gridButton(
        _ spec: ActionSpec,
        glyph: Data? = nil,
        markText: String? = nil
    ) -> some View {
        Button(action: spec.action) {
            VStack(spacing: 2) {
                Group {
                    if let glyph, let img = UIImage(data: glyph) {
                        // Mono glyphs are dark silhouettes with alpha, so
                        // template rendering tints them to the button colour.
                        Image(uiImage: img)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 22)
                    } else if let markText, !markText.trimmingCharacters(
                        in: .whitespaces).isEmpty {
                        Text(markText)
                            .font(.system(size: 17, weight: .heavy))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    } else {
                        Image(systemName: spec.icon)
                            .font(.title3)
                    }
                }
                Text(spec.label)
                    .font(.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: 12))
        .tint(spec.tint)
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 10) {
            Image("HashFoot")
                .resizable()
                .scaledToFit()
                .frame(height: 46)
            Text("Harrier Central")
                .font(.headline)
            Text(connectivity.isReachable
                 ? "Start tracking a run on your phone and it will appear here."
                 : "Waiting for your phone…")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    // MARK: - Stats

    /// Your distance and your checks so far on one line, the elapsed time
    /// under it. The run's name is left off mid-run: it cost a line and the
    /// runner knows which run they are on.
    private var statsHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(distanceText)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(distanceUnit)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 6)
                Image(systemName: "circle.circle")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.orange)
                Text("\(connectivity.sumChecks)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .accessibilityLabel("\(connectivity.sumChecks) checks")
            }
            HStack(spacing: 5) {
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
        .frame(maxWidth: .infinity)
    }

    private var distanceText: String {
        guard let km = connectivity.distanceKm else { return "—" }
        let prefix = connectivity.powerSaver ? "~" : ""
        return prefix + wristDistance(km * 1000, imperial: connectivity.imperial).value
    }

    private var distanceUnit: String {
        guard let km = connectivity.distanceKm else {
            return connectivity.imperial ? "mi" : "km"
        }
        return wristDistance(km * 1000, imperial: connectivity.imperial).unit
    }

    private var elapsedText: String {
        let s = connectivity.elapsedSec
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%02d:%02d", m, sec)
    }

    // MARK: - Summary (end of run)

    private var summaryView: some View {
        VStack(spacing: 6) {
            Text("On Inn! 🍺")
                .font(.headline)
            if !connectivity.eventName.isEmpty {
                Text(connectivity.eventName)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(distanceText)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text(distanceUnit)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            Text(elapsedText)
                .font(.body)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            VStack(spacing: 3) {
                summaryRow("Checks", connectivity.sumChecks)
                summaryRow("False trails", connectivity.sumFalses)
                if connectivity.sumOtherMarks > 0 {
                    summaryRow("Other marks", connectivity.sumOtherMarks)
                }
                if connectivity.sumPhotos > 0 {
                    summaryRow("Photos", connectivity.sumPhotos)
                }
            }
            .padding(.top, 2)
            Button("Done") {
                connectivity.dismissSummary()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private func summaryRow(_ label: String, _ count: Int) -> some View {
        HStack {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(count)")
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
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
        let d = wristDistance(meters, imperial: connectivity.imperial)
        return "\(d.value) \(d.unit)"
    }
}


/// The phone's distance rule (lib/util/distance_format.dart, 2026-09-27), for
/// the wrist: metres under 1 km, one-decimal km above; yards under a mile,
/// one-decimal miles above; whole numbers from 100.
func wristDistance(_ meters: Double, imperial: Bool) -> (value: String, unit: String) {
    let m = meters.isFinite ? max(0, meters) : 0
    func large(_ v: Double, _ unit: String) -> (value: String, unit: String) {
        let r = (v * 10).rounded() / 10
        return r >= 100 ? (String(format: "%.0f", r), unit) : (String(format: "%.1f", r), unit)
    }
    if imperial {
        if m < 1609.344 { return (String(format: "%.0f", m * 1.0936133), "yd") }
        return large(m / 1609.344, "mi")
    }
    if m < 1000 { return (String(format: "%.0f", m), "m") }
    return large(m / 1000, "km")
}
