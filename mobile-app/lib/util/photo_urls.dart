import 'package:harrier_central/imports.dart';

/// Widths the website's image optimizer will serve (its `PhotoWidth` in
/// public-web/lib/packtrack.ts). Any other value is refused with a 400.
const List<int> kPhotoThumbWidths = <int>[256, 640, 1080, 1920];

/// A resized rendition of a run-photo blob, served by the website's image
/// optimizer (`/_next/image`, sharp on the server): JPEG at quality 75,
/// [width] pixels wide, cached there for a month.
///
/// THUMBNAILS ONLY — grids, strips and map markers. A photo uploaded from the
/// app is already JPEG q70 at ≤1920 px, so a full-size view should fetch the
/// original from blob storage; routing it through the optimizer would only
/// add a hop and a second copy on the website. Non-blob URLs (assets,
/// bundle://, other hosts) are returned untouched, as is a width the
/// optimizer does not offer.
String photoThumbUrl(String url, {int width = 640}) {
  if (!kPhotoThumbWidths.contains(width)) return url;
  final Uri? u = Uri.tryParse(url);
  if (u == null || u.host != 'harriercentral.blob.core.windows.net') return url;
  return '${BASE_HASHRUNS_DOT_ORG_URL}_next/image'
      '?url=${Uri.encodeQueryComponent(url)}&w=$width&q=75';
}
