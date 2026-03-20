import 'dart:ui_web' as ui_web;

import 'package:hcportal/imports.dart';
import 'package:web/web.dart' as web;

/// Network image widget with AVIF support.
///
/// Flutter's CanvasKit renderer uses Skia for image decoding, which does not
/// support AVIF. For .avif URLs, this widget uses a native HTML <img> element
/// via [HtmlElementView], letting the browser decode it directly. All other
/// formats are handled by [Image.network] as normal.
///
/// [loadingBuilder] is only applied for non-AVIF images; AVIF images are
/// decoded by the browser natively with no Flutter-level loading state.
class HcNetworkImage extends StatelessWidget {
  const HcNetworkImage(
    this.src, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final String src;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  static final Set<String> _registeredViews = {};

  static String _registerAvifView(String url, BoxFit? fit) {
    final viewType = '$url#${fit?.name ?? ''}';
    if (!_registeredViews.contains(viewType)) {
      _registeredViews.add(viewType);
      ui_web.platformViewRegistry.registerViewFactory(viewType, (_) =>
          (web.document.createElement('img') as web.HTMLImageElement)
            ..src = url
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = _cssFit(fit));
    }
    return viewType;
  }

  static String _cssFit(BoxFit? fit) => switch (fit) {
    BoxFit.contain => 'contain',
    BoxFit.cover => 'cover',
    BoxFit.fill => 'fill',
    BoxFit.fitWidth || BoxFit.fitHeight => 'contain',
    BoxFit.none => 'none',
    BoxFit.scaleDown => 'scale-down',
    _ => 'contain',
  };

  @override
  Widget build(BuildContext context) {
    if (src.toLowerCase().endsWith('.avif')) {
      final view = HtmlElementView(viewType: _registerAvifView(src, fit));
      if (width != null || height != null) {
        return SizedBox(width: width, height: height, child: view);
      }
      return view;
    }
    return Image.network(
      src,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
    );
  }
}
