import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:harrier_central/util/text_styles.dart';

/// One hasher's position relative to the viewer, resolved for drawing.
class RoseBlip {
  const RoseBlip({
    required this.userId,
    required this.name,
    required this.bearing,
    required this.distanceMeters,
    required this.isLost,
    required this.isStale,
  });

  final String userId;
  final String name;

  /// Degrees clockwise from true north, viewer → hasher.
  final double bearing;
  final double distanceMeters;

  /// This hasher has called for help / marked themselves lost.
  final bool isLost;

  /// Their last position is old enough that the blip may be wrong.
  final bool isStale;
}

/// Shared rose canvas. Used live (blips from the viewer's own GPS, heading from
/// the compass) and during replay (blips interpolated to the scrub position,
/// heading from the focus runner's direction of travel).
class RoseCanvas extends StatelessWidget {
  const RoseCanvas({
    super.key,
    required this.blips,
    required this.ringMetres,
    this.heading,
    this.facingDeg,
  });

  final List<RoseBlip> blips;
  final double ringMetres;

  /// Degrees clockwise from north that the rose is rotated to put "ahead" at
  /// the top. Null renders north-up.
  final double? heading;

  /// Direction the centre marker faces, degrees clockwise from north. Under
  /// heading-up rendering pass the same value as [heading] and the wedge sits
  /// at the top, exactly as before; under north-up rendering the rose stays
  /// put, so this is what lets the wedge show which way the hasher is facing.
  /// Null keeps the wedge pointing up.
  final double? facingDeg;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: RosePainter(
        blips: blips,
        ringMetres: ringMetres,
        heading: heading,
        facingDeg: facingDeg,
      ),
    );
  }
}

class RosePainter extends CustomPainter {
  RosePainter({
    required this.blips,
    required this.ringMetres,
    required this.heading,
    this.facingDeg,
  });

  final List<RoseBlip> blips;
  final double ringMetres;
  final double? heading;
  final double? facingDeg;

  /// Labels are placed nearest-first and skipped when they'd collide, so a
  /// crowded rose degrades into fewer labels rather than unreadable mush.
  static const int _maxLabels = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = math.min(size.width, size.height) / 2 - 34;
    if (R <= 0) return;

    final rot = heading ?? 0.0; // heading-up when we have a compass

    // Face + range rings. The two inner rings are quarter and half range.
    canvas.drawCircle(
      center,
      R,
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.28);
    for (final f in <double>[0.25, 0.5, 0.75]) {
      canvas.drawCircle(center, R * f, ringPaint);
    }
    canvas.drawCircle(
      center,
      R,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Colors.white.withValues(alpha: 0.55),
    );

    // Cardinals
    for (int deg = 0; deg < 360; deg += 90) {
      final a = ((deg - rot) - 90) * math.pi / 180;
      final label = <int, String>{0: 'N', 90: 'E', 180: 'S', 270: 'W'}[deg]!;
      _text(
        canvas,
        label,
        center + Offset(math.cos(a) * (R - 15), math.sin(a) * (R - 15)),
        color: deg == 0 ? Colors.yellow : Colors.white70,
        size: 13,
        weight: deg == 0 ? FontWeight.w800 : FontWeight.w500,
        anchor: _Anchor.center,
      );
    }

    // Viewer: facing wedge + dot. The wedge is drawn at the facing direction
    // relative to however the rose itself is rotated: heading-up passes
    // facing == rot so the wedge sits at the top; north-up passes rot == 0 so
    // the wedge swings to wherever the hasher is pointing.
    final wedgeDeg = (facingDeg == null ? 0.0 : facingDeg! - rot) - 90;
    final wa = wedgeDeg * math.pi / 180;
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: R * 0.26),
          wa - 0.3,
          0.6,
          false,
        )
        ..close(),
      Paint()..color = hc_blue.withValues(alpha: 0.22),
    );
    canvas.drawCircle(center, 7.5, Paint()..color = hc_blue);
    canvas.drawCircle(
      center,
      7.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white,
    );

    // Blips, nearest first so labels are budgeted to the ones that matter.
    final placed = <Rect>[];
    int labelled = 0;

    for (final b in blips) {
      final beyond = b.distanceMeters > ringMetres;
      final frac = beyond ? 1.0 : (b.distanceMeters / ringMetres);
      final a = ((b.bearing - rot) - 90) * math.pi / 180;
      final at =
          center + Offset(math.cos(a) * R * frac, math.sin(a) * R * frac);

      final Color colour = b.isLost
          ? const Color(0xFFE6510A)
          : b.isStale
          ? Colors.white38
          : Colors.yellow;

      if (beyond) {
        // Pinned to the rim: hollow chevron, so "further than the ring" reads
        // as a different thing from "exactly at the ring".
        canvas.save();
        canvas.translate(at.dx, at.dy);
        canvas.rotate(a + math.pi / 2);
        canvas.drawPath(
          Path()
            ..moveTo(0, -8)
            ..lineTo(6.5, 5)
            ..lineTo(0, 1.5)
            ..lineTo(-6.5, 5)
            ..close(),
          Paint()..color = colour.withValues(alpha: 0.85),
        );
        canvas.restore();
      } else {
        canvas.drawCircle(at, b.isLost ? 8.0 : 6.0, Paint()..color = colour);
        if (b.isLost) {
          canvas.drawCircle(
            at,
            12.0,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = colour.withValues(alpha: 0.7),
          );
        }
      }

      if (labelled >= _maxLabels) continue;
      final text = '${b.name}  ${_dist(b.distanceMeters)}';
      final tp = _painter(text, 11.5, FontWeight.w600, Colors.white);
      final right = math.cos(a) >= 0;
      final lx = at.dx + (right ? 11 : -11 - tp.width);
      final ly = at.dy - tp.height / 2 - 10;
      final rect = Rect.fromLTWH(lx, ly, tp.width, tp.height);
      if (placed.any((p) => p.overlaps(rect))) continue;
      placed.add(rect.inflate(2));
      // Shadow keeps names legible over the rings.
      _painter(
        text,
        11.5,
        FontWeight.w600,
        Colors.black87,
      ).paint(canvas, Offset(lx + 1, ly + 1));
      tp.paint(canvas, Offset(lx, ly));
      labelled++;
    }
  }

  String _dist(double m) =>
      m < 1000 ? '${m.round()}m' : '${(m / 1000).toStringAsFixed(1)}km';

  TextPainter _painter(String s, double size, FontWeight w, Color c) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(color: c, fontSize: size, fontWeight: w),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  void _text(
    Canvas canvas,
    String s,
    Offset at, {
    required Color color,
    required double size,
    required FontWeight weight,
    _Anchor anchor = _Anchor.topLeft,
  }) {
    final tp = _painter(s, size, weight, color);
    final o = anchor == _Anchor.center
        ? at - Offset(tp.width / 2, tp.height / 2)
        : at;
    tp.paint(canvas, o);
  }

  @override
  bool shouldRepaint(covariant RosePainter old) =>
      old.ringMetres != ringMetres ||
      old.heading != heading ||
      old.facingDeg != facingDeg ||
      old.blips != blips;
}

enum _Anchor { topLeft, center }
