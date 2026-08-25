import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:harrier_central/util/styles.dart';

class HcAppCircularProgressIndicator extends StatelessWidget {
  const HcAppCircularProgressIndicator({
    this.color1,
    this.color2,
    this.size,
    super.key,
  });

  final Color? color1;
  final Color? color2;
  final double? size;

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isolates the spinner's ~60fps repaint from its
    // surroundings, so a loading gate (or several spinners in a list) doesn't
    // repaint the enclosing layer every frame.
    return RepaintBoundary(
      child: _PulsingDotCircle(
        size: size ?? 75.0,
        color1: color1 ?? themeAppBarBackground,
        color2: color2 ?? Colors.grey.shade400,
      ),
    );
  }
}

/// In-house replacement for the retired `flutter_spinkit` package's
/// SpinKitCircle: twelve dots on a ring, pulsing in a travelling wave,
/// alternating between the two theme colors. Self-contained animation —
/// the sanctioned StatefulWidget case.
class _PulsingDotCircle extends StatefulWidget {
  const _PulsingDotCircle({
    required this.size,
    required this.color1,
    required this.color2,
  });

  final double size;
  final Color color1;
  final Color color2;

  @override
  State<_PulsingDotCircle> createState() => _PulsingDotCircleState();
}

class _PulsingDotCircleState extends State<_PulsingDotCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int dots = 12;
    final double dotSize = widget.size / 5;
    final double radius = (widget.size - dotSize) / 2;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          return Stack(
            children: List<Widget>.generate(dots, (int i) {
              final double angle = 2 * math.pi * i / dots;
              // Travelling pulse: each dot leads the previous slightly.
              final double phase = (_controller.value - i / dots) % 1.0;
              final double pulse =
                  0.4 + 0.6 * (0.5 + 0.5 * math.cos(2 * math.pi * phase));
              return Positioned(
                left: widget.size / 2 + radius * math.cos(angle) - dotSize / 2,
                top: widget.size / 2 + radius * math.sin(angle) - dotSize / 2,
                child: Transform.scale(
                  scale: pulse,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i.isEven ? widget.color1 : widget.color2,
                    ),
                    child: SizedBox(width: dotSize, height: dotSize),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
