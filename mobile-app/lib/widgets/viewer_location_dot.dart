import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:harrier_central/imports.dart';

/// The phone's own position on a map: a blue dot with a white ring, and a
/// wedge that points where the phone is facing when a compass heading is
/// available (null → dot only, so it degrades cleanly on a device without a
/// magnetometer).
///
/// Shared by the PackTrack map and the main Map tab (James, 2026-09-16: "be
/// sure and put a blue dot at the location where the phone is, including a
/// direction arrow pulled from the compass"). Its own Obx: the compass
/// updates many times a second, and reading the heading here means a change
/// repaints only this wedge — never the FlutterMap or a marker-cluster layer.
///
/// Put it in a Marker with `rotate: true` so the wedge stays a true bearing
/// when the map itself is rotated.
class ViewerLocationDot extends StatelessWidget {
  const ViewerLocationDot({super.key, required this.heading});

  /// Degrees clockwise from north, or null for no wedge.
  final RxnDouble heading;

  static const Color blue = Color(0xFF2A7FFF);
  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final double? h = heading.value;
      return Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: <Widget>[
          if (h != null)
            Transform.rotate(
              angle: h * math.pi / 180.0,
              child: SizedBox(
                width: size,
                height: size,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Icon(
                    Icons.navigation,
                    size: 16,
                    color: blue.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Colors.black26, blurRadius: 2),
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// A compass heading as an Rx, started and stopped by whoever shows a dot.
///
/// Ticks are dropped below two degrees of change — the magnetometer jitters,
/// and a sub-visible rebuild many times a second is battery for nothing.
/// Idempotent start; stop clears the heading so the wedge disappears rather
/// than freezing at its last value.
class CompassHeadingFeed {
  final RxnDouble heading = RxnDouble();
  StreamSubscription<CompassEvent>? _sub;

  static const double _thresholdDeg = 2.0;

  bool get isRunning => _sub != null;

  void start() {
    _sub ??= FlutterCompass.events?.listen((CompassEvent event) {
      final double? h = event.heading;
      if (h == null) return;
      final double? prev = heading.value;
      if (prev != null) {
        double diff = (h - prev).abs();
        if (diff > 180.0) diff = 360.0 - diff;
        if (diff < _thresholdDeg) return;
      }
      heading.value = h;
    });
  }

  void stop() {
    unawaited(_sub?.cancel());
    _sub = null;
    heading.value = null;
  }
}
