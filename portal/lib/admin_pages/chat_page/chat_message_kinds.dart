// Chat message kinds — photo and location (E9.F1.S11/S12, 2026-09-29).
//
// HC.EventMessage.MessageKind: 0 text, 1 photo, 2 location. The content of a
// photo or location is a URL, so a build that predates the kind still shows a
// link. The server's rule is HC6.ChatMessageKindError; what this file builds
// must pass it, and what it parses is what that rule lets through.
// See docs/chat_photos_location_delete_plan.md.

import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// HC.EventMessage.MessageKind values.
const int chatKindText = 0;
const int chatKindPhoto = 1;
const int chatKindLocation = 2;

/// The only place a chat photo may live (HC6.ChatMessageKindError).
const String chatPhotoUrlPrefix =
    'https://harriercentral.blob.core.windows.net/chat-photos/';

/// The prefix of a location message's content.
const String chatLocationUrlPrefix =
    'https://www.google.com/maps/search/?api=1&query=';

/// Metadata key a location CustomMessage carries its maps URL under.
const String chatMetaKind = 'hcKind';
const String chatMetaUrl = 'url';
const String chatMetaLat = 'lat';
const String chatMetaLng = 'lng';
const String chatMetaLocation = 'location';

/// Is [url] a chat photo the server would have accepted? A row that fails
/// this is drawn as text rather than handed to Image.network.
bool isChatPhotoUrl(String url) =>
    url.startsWith(chatPhotoUrlPrefix) &&
    url.endsWith('.jpg') &&
    !url.contains(' ') &&
    !url.contains('?') &&
    !url.contains('#') &&
    !url.contains('..');

/// Coordinates to at most 6 decimals, '.' separator, trailing zeros dropped —
/// what DECIMAL(9,6) on the server can read.
String _coord(double v) {
  var s = v.toStringAsFixed(6);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  if (s == '-0') s = '0';
  return s;
}

/// The content of a location message, or null if the point is off the globe.
String? chatLocationUrl(double lat, double lng) {
  if (lat.isNaN || lng.isNaN) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return '$chatLocationUrlPrefix${_coord(lat)},${_coord(lng)}';
}

/// Parses a location message's content; null when it is not one.
({double lat, double lng})? parseChatLocationUrl(String content) {
  if (!content.startsWith(chatLocationUrlPrefix)) return null;
  return parseLatLng(content.substring(chatLocationUrlPrefix.length));
}

/// Parses "lat,lng" (spaces allowed) — also what a user pastes into the pin
/// picker. Null when it is not two numbers in range.
({double lat, double lng})? parseLatLng(String text) {
  final parts = text.split(',');
  if (parts.length != 2) return null;
  final lat = double.tryParse(parts[0].trim());
  final lng = double.tryParse(parts[1].trim());
  if (lat == null || lng == null) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  return (lat: lat, lng: lng);
}

/// "51.507400, -0.127800" style label for a location card.
String chatLocationLabel(double lat, double lng) =>
    '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

/// The longest side a chat photo is sent at.
const int chatPhotoMaxSide = 1600;

/// A picked image as the JPEG the chat sends: decoded, EXIF orientation baked
/// into the pixels, shrunk to at most [chatPhotoMaxSide] px on its longest
/// side, and re-encoded at quality 80 with NO metadata. Null when [bytes] is
/// not an image package:image can read (HEIC, for one).
///
/// Metadata: a decode + re-encode does NOT drop EXIF by itself. package:image
/// keeps the source EXIF on the Image (bakeOrientation copies it, minus the
/// orientation tag) and encodeJpg writes it back as APP1 — GPS position
/// included. Replacing it with an empty ExifData makes the encoder skip APP1,
/// and APP1 is the only metadata segment it writes (APP0 is the bare JFIF
/// header). test/chat_photo_jpeg_test.dart pins this.
Uint8List? chatPhotoJpeg(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    var image = img.bakeOrientation(decoded);
    if (image.width > chatPhotoMaxSide || image.height > chatPhotoMaxSide) {
      image = image.width >= image.height
          ? img.copyResize(image, width: chatPhotoMaxSide)
          : img.copyResize(image, height: chatPhotoMaxSide);
    }
    image.exif = img.ExifData();
    return img.encodeJpg(image, quality: 80);
  } on Object {
    return null;
  }
}
