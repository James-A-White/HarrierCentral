// E9.F1.S11/S12: what the portal's run chat sends. Above all, a chat photo
// leaves the portal with no EXIF — no GPS position.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hcportal/admin_pages/chat_page/chat_message_kinds.dart';
import 'package:image/image.dart' as img;

/// True when the JPEG has an APP1 "Exif" segment.
bool hasExifSegment(Uint8List jpeg) {
  var i = 2; // after SOI
  while (i + 4 <= jpeg.length && jpeg[i] == 0xFF) {
    final marker = jpeg[i + 1];
    if (marker == 0xDA) return false; // start of scan: no more headers
    final len = (jpeg[i + 2] << 8) | jpeg[i + 3];
    if (marker == 0xE1 &&
        String.fromCharCodes(jpeg.sublist(i + 4, i + 8)) == 'Exif') {
      return true;
    }
    i += 2 + len;
  }
  return false;
}

Uint8List jpegWithGps({int width = 64, int height = 48}) {
  final src = img.Image(width: width, height: height);
  src.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(51, 1);
  src.exif.imageIfd['Make'] = img.IfdValueAscii('TestCam');
  src.exif.imageIfd.orientation = 6; // rotated 90° — must be baked
  return img.encodeJpg(src);
}

void main() {
  test('the fixture really carries EXIF, so the next test can fail', () {
    final withGps = jpegWithGps();
    expect(hasExifSegment(withGps), isTrue);
    expect(img.decodeJpg(withGps)!.exif.gpsIfd.isEmpty, isFalse);
  });

  test('chatPhotoJpeg strips all EXIF, GPS included', () {
    final out = chatPhotoJpeg(jpegWithGps())!;
    expect(hasExifSegment(out), isFalse);
    expect(img.decodeJpg(out)!.exif.isEmpty, isTrue);
  });

  test('orientation is baked into the pixels before the EXIF goes', () {
    final out = img.decodeJpg(chatPhotoJpeg(jpegWithGps())!)!;
    expect(out.width, 48);
    expect(out.height, 64);
  });

  test('longest side is shrunk to 1600, aspect kept', () {
    final big = img.encodeJpg(img.Image(width: 3200, height: 2000));
    final out = img.decodeJpg(chatPhotoJpeg(big)!)!;
    expect(out.width, 1600);
    expect(out.height, 1000);
  });

  test('not an image gives null', () {
    expect(chatPhotoJpeg(Uint8List.fromList([1, 2, 3])), isNull);
  });

  test('location URL matches the server rule and round-trips', () {
    final url = chatLocationUrl(51.50740012, -0.1278)!;
    expect(
      url,
      'https://www.google.com/maps/search/?api=1&query=51.5074,-0.1278',
    );
    final p = parseChatLocationUrl(url)!;
    expect(p.lat, closeTo(51.5074, 1e-9));
    expect(p.lng, closeTo(-0.1278, 1e-9));
    expect(chatLocationUrl(91, 0), isNull);
  });

  test('photo URL rule', () {
    expect(isChatPhotoUrl('${chatPhotoUrlPrefix}2026/09/a-b.jpg'), isTrue);
    expect(
      isChatPhotoUrl('${chatPhotoUrlPrefix}2026/09/a-b.jpg?sig=x'),
      isFalse,
    );
    expect(isChatPhotoUrl('https://example.com/x.jpg'), isFalse);
  });
}
