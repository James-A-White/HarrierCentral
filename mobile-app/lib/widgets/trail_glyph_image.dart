import 'package:harrier_central/imports.dart';

/// Draws a trail-marker glyph, falling back to blob storage for ids this build
/// has never heard of.
///
/// Why: the glyph library used to be fixed at build time. A kennel marking with
/// a glyph added after a user's version shipped got a "?" tile on their phone
/// (and, before 2026-08-30, nothing at all on the web). Now a new glyph can be
/// uploaded to the `trail-glyphs` container and every client renders it, with
/// no app release.
///
/// Resolution order — bundled assets always win, so the common path costs no
/// network at all and works offline:
///   1. `kTrailGlyphs` entry → `Image.asset` (unchanged behaviour).
///   2. no entry → `<id>.mono.png` from blob, tinted to [ink].
///   3. that 404s → `<id>.fixed.png` from blob, drawn in full colour.
///   4. offline or genuinely missing → the "?" tile, exactly as before.
///
/// Steps 2–3 go through `CachedNetworkImage`, so a glyph is fetched once and
/// then served from disk — including with no connection.
///
/// NOTE: this makes an unknown glyph RENDER. For a kennel to *choose* one it
/// must also appear in the slot picker, which reads `kTrailGlyphs`; that still
/// needs a release (or a future remote manifest). See docs/trail_markers/SPEC.md.
class TrailGlyphImage extends StatelessWidget {
  const TrailGlyphImage({
    super.key,
    required this.glyphId,
    required this.ink,
    this.fit = BoxFit.contain,
  });

  final String? glyphId;
  final Color ink;
  final BoxFit fit;

  static const Icon _unknown = Icon(Icons.help_outline);

  String _url(String suffix) => '$BASE_TRAIL_GLYPHS_URL$glyphId.$suffix.png';

  @override
  Widget build(BuildContext context) {
    final id = glyphId?.trim();
    if (id == null || id.isEmpty) return Icon(Icons.help_outline, color: ink);

    final TrailGlyph? bundled = glyphById(id);
    if (bundled != null) {
      return Image.asset(
        bundled.assetPath,
        fit: fit,
        color: bundled.fixed ? null : ink,
        colorBlendMode: bundled.fixed ? null : BlendMode.srcIn,
        // A bundled asset that fails to decode is a packaging fault, not a
        // missing glyph — don't reach for the network to paper over it.
        errorBuilder: (_, _, _) => const Icon(Icons.place, color: customRed),
      );
    }

    // Unknown id: a glyph newer than this build. Try mono, then fixed.
    return CachedNetworkImage(
      imageUrl: _url('mono'),
      fit: fit,
      color: ink,
      colorBlendMode: BlendMode.srcIn,
      // Nothing while it loads — a spinner inside a 72px marker is noise.
      placeholder: (_, _) => const SizedBox.shrink(),
      errorWidget: (_, _, _) => CachedNetworkImage(
        imageUrl: _url('fixed'),
        fit: fit,
        placeholder: (_, _) => const SizedBox.shrink(),
        errorWidget: (_, _, _) => Icon(_unknown.icon, color: ink),
      ),
    );
  }
}
