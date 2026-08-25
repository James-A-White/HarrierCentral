import 'package:flutter/material.dart' hide Badge;

/// In-house replacement for the `badges` package — a badge is a Stack with a
/// positioned colored bubble. API-compatible with the subset the app uses
/// (Badge/BadgePosition.topEnd/BadgeStyle), imported `as badges`.
class BadgePosition {
  const BadgePosition._({this.top, this.end, this.bottom});

  factory BadgePosition.topEnd({double top = -8, double end = -10}) =>
      BadgePosition._(top: top, end: end);

  factory BadgePosition.bottomEnd({double bottom = -8, double end = -10}) =>
      BadgePosition._(bottom: bottom, end: end);

  final double? top;
  final double? end;
  final double? bottom;
}

class BadgeStyle {
  const BadgeStyle({
    this.badgeColor = Colors.red,
    this.padding = const EdgeInsets.all(5.0),
    this.elevation = 2,
  });

  final Color badgeColor;
  final EdgeInsetsGeometry padding;
  final double elevation;
}

class Badge extends StatelessWidget {
  const Badge({
    super.key,
    this.child,
    this.badgeContent,
    this.position,
    this.badgeStyle = const BadgeStyle(),
    this.showBadge = true,
  });

  final Widget? child;
  final Widget? badgeContent;
  final BadgePosition? position;
  final BadgeStyle badgeStyle;
  final bool showBadge;

  Widget _bubble() {
    return Material(
      color: badgeStyle.badgeColor,
      elevation: badgeStyle.elevation,
      shape: const CircleBorder(),
      child: Padding(
        padding: badgeStyle.padding,
        child: badgeContent ?? const SizedBox(width: 4, height: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child ?? const SizedBox.shrink();
    // No child: the badge is a standalone bubble (positioned by the caller).
    if (child == null) return _bubble();
    final BadgePosition pos = position ?? BadgePosition.topEnd();
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        child!,
        PositionedDirectional(
          top: pos.top,
          end: pos.end,
          bottom: pos.bottom,
          child: _bubble(),
        ),
      ],
    );
  }
}
