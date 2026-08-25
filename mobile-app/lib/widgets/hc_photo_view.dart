import 'package:flutter/material.dart';

/// In-house replacement for the `photo_view` package, built on Flutter's
/// native InteractiveViewer. API-compatible with the subset the app uses:
/// PhotoView(imageProvider/minScale/maxScale/backgroundDecoration) and
/// PhotoViewGallery with customChild page options (swipe pages at 1x, pan
/// the photo when zoomed).
class PhotoView extends StatelessWidget {
  const PhotoView({
    super.key,
    required this.imageProvider,
    this.minScale = 1.0,
    this.maxScale = 4.0,
    this.backgroundDecoration,
  });

  final ImageProvider imageProvider;
  final double minScale;
  final double maxScale;
  final BoxDecoration? backgroundDecoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: backgroundDecoration,
      child: InteractiveViewer(
        // InteractiveViewer requires minScale > 0 and sane bounds.
        minScale: minScale.clamp(0.1, 1.0),
        maxScale: maxScale.clamp(1.0, 100.0),
        child: Center(
          child: Image(image: imageProvider, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class PhotoViewGalleryPageOptions {
  PhotoViewGalleryPageOptions.customChild({
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 4.0,
  });

  final Widget child;
  final double minScale;
  final double maxScale;
}

class PhotoViewGallery extends StatefulWidget {
  const PhotoViewGallery({
    super.key,
    required this.pageOptions,
    this.pageController,
    this.onPageChanged,
    this.backgroundDecoration,
    this.scrollPhysics,
  });

  final List<PhotoViewGalleryPageOptions> pageOptions;
  final PageController? pageController;
  final void Function(int index)? onPageChanged;
  final BoxDecoration? backgroundDecoration;
  final ScrollPhysics? scrollPhysics;

  @override
  State<PhotoViewGallery> createState() => _PhotoViewGalleryState();
}

class _PhotoViewGalleryState extends State<PhotoViewGallery> {
  final Map<int, TransformationController> _transforms =
      <int, TransformationController>{};
  bool _zoomed = false;

  TransformationController _transformFor(int index) {
    return _transforms.putIfAbsent(index, () {
      final TransformationController c = TransformationController();
      c.addListener(() {
        // Swipe pages at 1x; once zoomed in, drags pan the photo instead.
        final bool zoomed = c.value.getMaxScaleOnAxis() > 1.01;
        if (zoomed != _zoomed && mounted) {
          setState(() => _zoomed = zoomed);
        }
      });
      return c;
    });
  }

  @override
  void dispose() {
    for (final TransformationController c in _transforms.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.backgroundDecoration,
      child: PageView.builder(
        controller: widget.pageController,
        onPageChanged: widget.onPageChanged,
        physics: _zoomed
            ? const NeverScrollableScrollPhysics()
            : (widget.scrollPhysics ?? const ClampingScrollPhysics()),
        itemCount: widget.pageOptions.length,
        itemBuilder: (BuildContext context, int index) {
          final PhotoViewGalleryPageOptions opts = widget.pageOptions[index];
          return InteractiveViewer(
            transformationController: _transformFor(index),
            minScale: opts.minScale.clamp(0.1, 1.0),
            maxScale: opts.maxScale.clamp(1.0, 100.0),
            child: Center(child: opts.child),
          );
        },
      ),
    );
  }
}
