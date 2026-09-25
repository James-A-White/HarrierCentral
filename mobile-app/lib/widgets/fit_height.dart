import 'package:flutter/material.dart';

/// Keeps [child] at the full available width (so its text still wraps) and
/// scales it down only when it is TALLER than the space — a fixed-size tile
/// whose icon and two-line label outgrow it at a large text size. Where it
/// fits it is drawn unchanged.
class FitHeight extends StatelessWidget {
  const FitHeight({super.key, required this.child, this.alignment});

  final Widget child;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.maxWidth.isFinite || !constraints.maxHeight.isFinite) {
          return child;
        }
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment ?? Alignment.topCenter,
          child: SizedBox(width: constraints.maxWidth, child: child),
        );
      },
    );
  }
}

/// How much the user's text-size setting enlarges ordinary body text (1.0 at
/// the default, up to the app's 1.5 cap). Use it to grow a FIXED height that
/// holds text. Measured at 14 sp on purpose: Android 14+ scales text
/// non-linearly, so asking the scaler about a large number (a row height of
/// 84) returns nearly 84 and the box would not grow at all.
double bodyTextScale(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14.0) / 14.0;
