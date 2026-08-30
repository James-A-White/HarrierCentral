import SwiftUI

/// Single-screen watch UI: session stats up top, mark buttons below.
/// Everything is driven by `WatchConnectivityManager`'s mirrored state —
/// if the phone isn't tracking, the buttons aren't shown.
///
/// LAYOUT IS A `List` ON PURPOSE. Plain ScrollView + Button on watchOS
/// mis-maps tap coordinates when content is partially scrolled (taps at the
/// rest position landed one row below their visual target — Check triggered
/// I'm Lost; a NavigationStack wrapper did NOT cure it). List is the native
/// watch scroll container with correct hit-testing at every offset, and one
/// full-width button per row means a tap can never be ambiguous. New
/// buttons = new rows; the screen scrolls, so the field can grow freely.
struct ContentView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var showOnInnConfirm = false
    @State private var showLostView = false

    var body: some View {
        NavigationStack {
            List {
                if connectivity.isTracking {
                    statsHeader
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                    // Two buttons per row is fine INSIDE List rows: each
                    // Button carries an explicit style, so they hit-test
                    // individually — the old ScrollView bug was about row
                    // positioning, which List owns correctly.
                    buttonRow(
                        (connectivity.checkLabel ?? "Check", "circle.circle", .orange,
                         { connectivity.sendMark("check") }),
                        (connectivity.falseLabel ?? "False", "xmark.circle", .red,
                         { connectivity.sendMark("falseTrail") }),
                        leftGlyph: connectivity.checkGlyph, leftText: connectivity.checkText,
                        rightGlyph: connectivity.falseGlyph, rightText: connectivity.falseText
                    )
                    buttonRow(
                        ("I'm Lost", "location.north.line", .blue, { showLostView = true }),
                        ("On Inn", "flag.checkered", .green, { showOnInnConfirm = true })
                    )
                } else if connectivity.phase == "summary" {
                    summaryView
                        .listRowBackground(Color.clear)
                } else {
                    idleView
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
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

    /// A List row holding two side-by-side mark buttons — the 2×2 grid look,
    /// with List doing the scrolling.
    private func buttonRow(
        _ left: ActionSpec,
        _ right: ActionSpec,
        leftGlyph: Data? = nil, leftText: String? = nil,
        rightGlyph: Data? = nil, rightText: String? = nil
    ) -> some View {
        HStack(spacing: 6) {
            gridButton(left, glyph: leftGlyph, markText: leftText)
            gridButton(right, glyph: rightGlyph, markText: rightText)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
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
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.bordered)
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
        return prefix + String(format: "%.2f", km)
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
                Text("km")
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
        meters >= 1000
            ? String(format: "%.1f km", meters / 1000)
            : String(format: "%.0f m", meters)
    }
}
