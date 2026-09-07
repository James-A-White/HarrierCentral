import 'package:harrier_central/imports.dart';

/// Reports its child's laid-out size after every frame in which it changes.
///
/// For overlays that must sit clear of another overlay whose height is not a
/// constant — the PackTrack playback panel grows and shrinks with its content,
/// so the only honest way to position something above it is to measure it.
class MeasuredSize extends StatefulWidget {
  const MeasuredSize({
    super.key,
    required this.child,
    required this.onChange,
  });

  final Widget child;
  final ValueChanged<Size> onChange;

  @override
  State<MeasuredSize> createState() => _MeasuredSizeState();
}

class _MeasuredSizeState extends State<MeasuredSize> {
  final GlobalKey _key = GlobalKey();
  Size? _last;

  @override
  void initState() {
    super.initState();
    // Post-frame: the render object does not have a size until the frame it is
    // laid out in, so measuring during build reads null.
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  void _measure(Duration _) {
    if (!mounted) return;
    final RenderObject? box = _key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    if (box.size != _last) {
      _last = box.size;
      widget.onChange(box.size);
    }
    // Keep watching: the panel changes height when runners load or the
    // carousel appears, and neither is a rebuild of THIS widget.
    WidgetsBinding.instance.addPostFrameCallback(_measure);
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(key: _key, child: widget.child);
}
