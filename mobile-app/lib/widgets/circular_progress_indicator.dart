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
      child: _SpinKitCircle(
        size: size ?? 75.0,
        color1: color1 ?? themeAppBarBackground,
        color2: color2 ?? Colors.grey.shade400,
      ),
    );
  }
}

/// In-house port of the retired `flutter_spinkit` package's `SpinKitCircle`
/// (v5.2.2). The widget tree is reproduced faithfully so it looks and lays
/// out exactly as the package did:
///
/// * The outer [Center] expands to fill whatever the parent allows, so the
///   spinner floats mid-screen and any wrapping background stretches with it
///   (rather than shrink-wrapping a 75px box in the top-left corner).
/// * Each of the 12 items is a plain square [DecoratedBox] placed at the
///   centre of a quadrant that is rotated by `30° × index` about the widget
///   centre. That geometry always leaves the square at 45° to its radial
///   line — the "diamonds" look — so no `BoxShape.circle` here.
/// * Scale follows the package's `DelayTween`: a 0→1 sine wave with each
///   item delayed by `index / 12` of the 1200 ms cycle.
///
/// Self-contained animation — the sanctioned StatefulWidget case.
class _SpinKitCircle extends StatefulWidget {
  const _SpinKitCircle({
    required this.size,
    required this.color1,
    required this.color2,
  });

  final double size;
  final Color color1;
  final Color color2;

  @override
  State<_SpinKitCircle> createState() => _SpinKitCircleState();
}

class _SpinKitCircleState extends State<_SpinKitCircle>
    with SingleTickerProviderStateMixin {
  static const int _itemCount = 12;

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
    return Center(
      child: SizedBox.fromSize(
        size: Size.square(widget.size),
        child: Stack(
          children: List<Widget>.generate(_itemCount, (int index) {
            final double position = widget.size * .5;
            return Positioned.fill(
              left: position,
              top: position,
              child: Transform(
                transform: Matrix4.rotationZ(30.0 * index * math.pi / 180),
                child: Align(
                  alignment: Alignment.center,
                  child: ScaleTransition(
                    scale: _DelayTween(
                      begin: 0.0,
                      end: 1.0,
                      delay: index / _itemCount,
                    ).animate(_controller),
                    child: SizedBox.fromSize(
                      size: Size.square(widget.size * 0.15),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: index.isEven ? widget.color1 : widget.color2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Port of flutter_spinkit's `DelayTween`: maps the controller's linear 0→1
/// onto a sine wave shifted by [delay], so successive items pulse in a
/// travelling wave around the ring.
class _DelayTween extends Tween<double> {
  _DelayTween({super.begin, super.end, required this.delay});

  final double delay;

  @override
  double lerp(double t) =>
      super.lerp((math.sin((t - delay) * 2 * math.pi) + 1) / 2);

  @override
  double evaluate(Animation<double> animation) => lerp(animation.value);
}
