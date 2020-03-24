import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class RotationY extends StatelessWidget {
  const RotationY({Key key, @required this.child, this.rotationY = 0}) : super(key: key);

  //Degrees to rads constant
  static const double degrees2Radians = math.pi / 180;

  final Widget child;
  final double rotationY;
  @override
  Widget build(BuildContext context) {
    return Transform(
        alignment: FractionalOffset.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) //These are magic numbers, just use them :)
          ..rotateY(rotationY * degrees2Radians),
        child: child);
  }
}

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({Key key, this.child}) : super(key: key);

  final Container child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: child.constraints.maxWidth,
      height: child.constraints.maxHeight,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      child: child,
    );
  }
}

class FlippableBox extends StatelessWidget {
  const FlippableBox({Key key, this.isFlipped = false, this.front, this.back}) : super(key: key);

  final Container front;
  final Container back;

  final bool isFlipped;
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0.0, end: isFlipped ? 180.0 : 0.0),
      builder: (BuildContext context, double value, Widget child) {
        final Container content = value >= 90 ? back : front;
        final Container offScreenContent = value >= 90 ? front : back;
        return Stack(
          children: <Widget>[
            RotationY(
              rotationY: value,
              child: RotationY(rotationY: value > 90 ? 180 : 0, child: content),
            ),
            // this ensures that we keep the original (front) widget in the tree so we preserve
            // it's state while it's out of view
            Container(
              child: offScreenContent,
              width: 0.0,
              height: 0.0,
            )
          ],
        );
      },
    );
  }
}
