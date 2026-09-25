import 'package:flutter/material.dart';

/// A row of controls that scrolls sideways when it is wider than the screen,
/// and lays out exactly as before when it fits (James, 2026-09-25: things
/// that flow off a small screen horizontally should scroll, not clip).
///
/// Give it the row as [child] (a Row without Expanded / Flexible children).
/// Where the row fits it is stretched to the full width, so its own
/// mainAxisAlignment (centre, spaceBetween...) still applies; where it does
/// not, it keeps its natural width and scrolls.
class HorizontalOverflowScroll extends StatelessWidget {
  const HorizontalOverflowScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (!constraints.maxWidth.isFinite) return child;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
