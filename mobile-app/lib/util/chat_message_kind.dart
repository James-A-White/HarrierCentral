/// What a chat message's content IS (HC.EventMessage.MessageKind,
/// E9.F1.S11/S12, 2026-09-29). Pure and tested.
///
/// The content of every kind is a string a pre-feature build can show: text
/// is text, a photo is its blob URL, a location is a Google Maps link. So a
/// kind this build does not know is simply drawn as text — never dropped.
///
/// The server's rule for what each kind may hold is
/// `HC6.ChatMessageKindError` (db/hc6/app); the builders here produce exactly
/// what it accepts. See docs/chat_photos_location_delete_plan.md.
library;

/// 0 text, 1 photo, 2 location — the server's integers, never renumbered.
class ChatMessageKind {
  static const int text = 0;
  static const int photo = 1;
  static const int location = 2;

  /// A reader row's `messageKind`. Absent (an older SP) or not a number is
  /// text, so the bubble still says something.
  static int fromJson(Object? raw) => raw is num ? raw.toInt() : text;
}

/// The one prefix the server accepts for a location. Anything else sent as
/// kind 2 is refused with errorType 2.
const String kChatLocationUrlPrefix =
    'https://www.google.com/maps/search/?api=1&query=';

/// The prefix of every chat photo. The server refuses a kind 1 message whose
/// content does not start with it, so a client cannot post an arbitrary URL
/// as a "photo" — and this side draws nothing it would refuse.
const String kChatPhotoUrlPrefix =
    'https://harriercentral.blob.core.windows.net/chat-photos/';

/// A point sent as a chat location.
class ChatLocation {
  const ChatLocation(this.latitude, this.longitude);
  final double latitude;
  final double longitude;

  static bool _inRange(double lat, double lng) =>
      lat.isFinite &&
      lng.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lng >= -180 &&
      lng <= 180;

  /// The message content for this point, or null when it is not a place on
  /// Earth (NaN, or out of range — the server would refuse it anyway).
  ///
  /// At most 6 decimals (about 11 cm, and the server casts to DECIMAL(9,6)),
  /// `.` as the separator whatever the phone's locale, trailing zeros trimmed
  /// so the link reads cleanly when an old build shows it as text.
  static String? buildUrl(double latitude, double longitude) {
    if (!_inRange(latitude, longitude)) return null;
    return '$kChatLocationUrlPrefix'
        '${_coord(latitude)},${_coord(longitude)}';
  }

  static String _coord(double v) {
    String s = v.toStringAsFixed(6);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    // -0.0000001 rounds to "-0": say 0.
    if (s == '-0') s = '0';
    return s;
  }

  /// The point in a location message's content, or null when the content is
  /// not a location link this app would have sent.
  static ChatLocation? parseUrl(String? content) {
    if (content == null) return null;
    final String c = content.trim();
    if (!c.startsWith(kChatLocationUrlPrefix)) return null;
    final List<String> parts = c
        .substring(kChatLocationUrlPrefix.length)
        .split(',');
    if (parts.length != 2) return null;
    final double? lat = double.tryParse(parts[0]);
    final double? lng = double.tryParse(parts[1]);
    if (lat == null || lng == null || !_inRange(lat, lng)) return null;
    return ChatLocation(lat, lng);
  }

  /// "51.50740, -0.12780" — for the card. Five decimals is about a metre.
  String get display =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

/// Is [content] a photo this app should draw as one? A kind 1 row whose
/// content is anything else is drawn as text.
bool isChatPhotoUrl(String? content) =>
    content != null && content.startsWith(kChatPhotoUrlPrefix);
