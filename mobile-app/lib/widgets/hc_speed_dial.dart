import 'package:flutter/material.dart';

/// In-house replacement for the `flutter_speed_dial` package (last published
/// 2023): an expanding FAB menu. API-compatible with the subset the app uses.
/// Self-contained animation state — the sanctioned StatefulWidget case.
class SpeedDialChild {
  SpeedDialChild({
    this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.label,
    this.labelStyle,
    this.labelBackgroundColor,
    this.onTap,
    this.shape,
  });

  final Widget? child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? label;
  final TextStyle? labelStyle;
  final Color? labelBackgroundColor;
  final VoidCallback? onTap;
  final ShapeBorder? shape;
}

class SpeedDial extends StatefulWidget {
  const SpeedDial({
    super.key,
    this.children = const <SpeedDialChild>[],
    this.child,
    this.animatedIcon,
    this.animatedIconTheme,
    this.visible = true,
    this.curve = Curves.easeOut,
    this.overlayColor = Colors.black,
    this.overlayOpacity = 0.5,
    this.onOpen,
    this.onClose,
    this.tooltip,
    this.heroTag,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 6.0,
    this.shape,
  });

  final List<SpeedDialChild> children;
  final Widget? child;
  final AnimatedIconData? animatedIcon;
  final IconThemeData? animatedIconTheme;
  final bool visible;
  final Curve curve;
  final Color overlayColor;
  final double overlayOpacity;
  final VoidCallback? onOpen;
  final VoidCallback? onClose;
  final String? tooltip;
  final Object? heroTag;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final ShapeBorder? shape;

  @override
  State<SpeedDial> createState() => _SpeedDialState();
}

class _SpeedDialState extends State<SpeedDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  bool get _isOpen => _entry != null;

  @override
  void dispose() {
    _removeEntry();
    _controller.dispose();
    super.dispose();
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    widget.onOpen?.call();
    _entry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_entry!);
    _controller.forward();
    setState(() {});
  }

  void _close() {
    widget.onClose?.call();
    _controller.reverse();
    _removeEntry();
    setState(() {});
  }

  Widget _buildOverlay(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Dimming barrier — tap anywhere to close.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            child: FadeTransition(
              opacity: _controller,
              child: Container(
                color: widget.overlayColor.withValues(
                  alpha: widget.overlayOpacity,
                ),
              ),
            ),
          ),
        ),
        // Action column anchored above the FAB.
        CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.bottomRight,
          offset: const Offset(0, -12),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _controller, curve: widget.curve),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final SpeedDialChild c in widget.children)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (c.label != null) ...<Widget>[
                          Material(
                            color: c.labelBackgroundColor ?? Colors.white,
                            elevation: 2,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Text(
                                c.label!,
                                style: c.labelStyle ??
                                    const TextStyle(color: Colors.black87),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        FloatingActionButton(
                          mini: true,
                          heroTag: null,
                          backgroundColor: c.backgroundColor,
                          foregroundColor: c.foregroundColor,
                          shape: c.shape,
                          onPressed: () {
                            _close();
                            c.onTap?.call();
                          },
                          child: c.child,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();
    return CompositedTransformTarget(
      link: _link,
      child: FloatingActionButton(
        heroTag: widget.heroTag,
        tooltip: widget.tooltip,
        backgroundColor: widget.backgroundColor,
        foregroundColor: widget.foregroundColor,
        elevation: widget.elevation,
        shape: widget.shape,
        onPressed: _toggle,
        child: widget.animatedIcon != null
            ? IconTheme.merge(
                data: widget.animatedIconTheme ?? const IconThemeData(),
                child: AnimatedIcon(
                  icon: widget.animatedIcon!,
                  progress: _controller,
                ),
              )
            : (widget.child ?? const Icon(Icons.add)),
      ),
    );
  }
}
