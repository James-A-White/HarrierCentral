import 'package:harrier_central/imports.dart';

/// The messaging app's own mark, in its own colour, so a button or menu row
/// reads as "WhatsApp" before the word does (James, 2026-09-16: "put the
/// WhatsApp logo in the button and use the logos of the respective chat apps
/// in the dropdown").
///
/// Four of the five are glyphs the icon font already carries. Signal's is
/// not in any font the app ships (Font Awesome added it in 6.2, and the app
/// is on 5), so it is drawn: the dashed ring around a speech bubble that IS
/// the Signal mark, in Signal blue. A drawn glyph also means no trademark
/// bitmap to age in `images/icons/` — see THIRD_PARTY_MARKS.md for how that
/// goes.
///
/// [onDisc] puts the glyph on a white disc so it keeps its brand colour on
/// the red button; on a white menu the bare glyph is right.
class MessagingPlatformGlyph extends StatelessWidget {
  const MessagingPlatformGlyph(
    this.platform, {
    super.key,
    this.size = 24,
    this.onDisc = false,
  });

  final MessagingPlatform platform;
  final double size;
  final bool onDisc;

  static Color brandColor(MessagingPlatform p) => switch (p) {
    MessagingPlatform.whatsApp => const Color(0xFF25D366),
    MessagingPlatform.telegram => const Color(0xFF26A5E4),
    MessagingPlatform.signal => const Color(0xFF3A76F0),
    MessagingPlatform.messenger => const Color(0xFF0084FF),
    MessagingPlatform.weChat => const Color(0xFF07C160),
  };

  @override
  Widget build(BuildContext context) {
    final Color color = brandColor(platform);
    final Widget glyph = switch (platform) {
      MessagingPlatform.whatsApp => Icon(
        FontAwesome5Brands.whatsapp,
        color: color,
        size: size,
      ),
      MessagingPlatform.telegram => Icon(
        FontAwesome5Brands.telegram,
        color: color,
        size: size,
      ),
      MessagingPlatform.messenger => Icon(
        FontAwesome5Brands.facebook_messenger,
        color: color,
        size: size,
      ),
      MessagingPlatform.weChat => Icon(
        FontAwesome5Brands.weixin,
        color: color,
        size: size,
      ),
      MessagingPlatform.signal => CustomPaint(
        size: Size.square(size),
        painter: _SignalMarkPainter(color),
      ),
    };
    if (!onDisc) {
      return SizedBox.square(
        dimension: size,
        child: Center(child: glyph),
      );
    }
    // The disc is a little larger than the glyph, as the brand marks are
    // drawn: a rounded square of colour behind a white glyph would be their
    // OWN presentation, but on our red button a white disc under the
    // coloured glyph is what keeps the colour honest.
    return Container(
      width: size + 8,
      height: size + 8,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: glyph,
    );
  }
}

/// Signal's mark: a dashed ring around a solid speech bubble whose tail
/// points to the lower left.
class _SignalMarkPainter extends CustomPainter {
  const _SignalMarkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2;

    // The ring: 16 dashes on a circle just inside the box.
    final Paint ring = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.16
      ..strokeCap = StrokeCap.round;
    const int dashes = 16;
    const double gapFraction = 0.42;
    final double step = 2 * pi / dashes;
    final Rect ringRect = Rect.fromCircle(center: c, radius: r * 0.92);
    for (int i = 0; i < dashes; i++) {
      canvas.drawArc(
        ringRect,
        i * step + step * gapFraction / 2,
        step * (1 - gapFraction),
        false,
        ring,
      );
    }

    // The bubble: a solid circle with a tail to the lower left.
    final Paint fill = Paint()..color = color;
    final double br = r * 0.58;
    canvas.drawCircle(c, br, fill);
    final Path tail = Path()
      ..moveTo(c.dx - br * 0.55, c.dy + br * 0.45)
      ..lineTo(c.dx - br * 1.05, c.dy + br * 1.05)
      ..lineTo(c.dx - br * 0.1, c.dy + br * 0.95)
      ..close();
    canvas.drawPath(tail, fill);
  }

  @override
  bool shouldRepaint(_SignalMarkPainter old) => old.color != color;
}
