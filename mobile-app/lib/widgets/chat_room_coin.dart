import 'package:harrier_central/imports.dart';

/// A platform-wide chat room's coin — a struck challenge-coin medallion whose
/// metal is the role: gold for the Grand Masters, copper for Hash Cash, and so
/// on.
///
/// The URL comes from the SERVER, on the room's own row out of
/// HC6.ChatRoomCatalog(). Nothing about the art is compiled in, for the same
/// reason nothing about the rooms is: a room added by a stored-procedure
/// deploy reaches phones that shipped before it existed, and it must arrive
/// with its picture, not as a hole. A room with no art yet sends null and
/// falls back to the glyph this app has always drawn.
///
/// Two rules the coin depends on:
///  - Draw it CONTAINED. It is already a circle with a bright raised rim, and
///    that rim is what makes it readable at 48 logical pixels.
///  - Never circle-mask it. A mask shaves the rim and the coin goes flat.
class ChatRoomCoin extends StatelessWidget {
  const ChatRoomCoin({super.key, required this.iconUrl, this.size = 44});

  /// Full URL from the room catalogue, or null when the room has no art.
  final String? iconUrl;
  final double size;

  bool get _hasArt => (iconUrl ?? '').startsWith('http');

  @override
  Widget build(BuildContext context) {
    if (!_hasArt) return _glyph();
    return SizedBox(
      width: size,
      height: size,
      child: CachedNetworkImage(
        imageUrl: iconUrl!,
        fit: BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 0),
        // A room the reader can see must never render as blank space, so both
        // the waiting state and the failed state fall back to the glyph.
        placeholder: (_, _) => _glyph(),
        errorWidget: (_, _, _) => _glyph(),
      ),
    );
  }

  Widget _glyph() => SizedBox(
    width: size,
    height: size,
    child: Icon(Icons.forum_outlined, color: hc_red, size: size * 0.66),
  );
}
