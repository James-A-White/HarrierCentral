import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/chat_message_kind.dart';

void main() {
  group('ChatLocation.buildUrl', () {
    test('builds the maps link the server accepts', () {
      expect(
        ChatLocation.buildUrl(51.5074, -0.1278),
        'https://www.google.com/maps/search/?api=1&query=51.5074,-0.1278',
      );
    });

    test('never more than 6 decimals', () {
      final String url = ChatLocation.buildUrl(51.123456789, -0.987654321)!;
      expect(url.endsWith('51.123457,-0.987654'), isTrue);
    });

    test('whole numbers drop the decimal point', () {
      expect(ChatLocation.buildUrl(10, -20)!.endsWith('query=10,-20'), isTrue);
    });

    test('a value that rounds to minus zero is written as 0', () {
      expect(
        ChatLocation.buildUrl(-0.0000001, 0.0000001)!.endsWith('query=0,0'),
        isTrue,
      );
    });

    test('the extremes are allowed', () {
      expect(ChatLocation.buildUrl(90, 180), isNotNull);
      expect(ChatLocation.buildUrl(-90, -180), isNotNull);
    });

    test('out of range or not a number gives null', () {
      expect(ChatLocation.buildUrl(90.1, 0), isNull);
      expect(ChatLocation.buildUrl(0, -180.5), isNull);
      expect(ChatLocation.buildUrl(double.nan, 0), isNull);
      expect(ChatLocation.buildUrl(0, double.infinity), isNull);
    });

    test('stays within the server length check (100)', () {
      expect(
        ChatLocation.buildUrl(-89.123456, -179.123456)!.length,
        lessThanOrEqualTo(100),
      );
    });
  });

  group('ChatLocation.parseUrl', () {
    test('round-trips what buildUrl makes', () {
      final ChatLocation? p = ChatLocation.parseUrl(
        ChatLocation.buildUrl(-33.868820, 151.209296),
      );
      expect(p, isNotNull);
      expect(p!.latitude, closeTo(-33.86882, 1e-9));
      expect(p.longitude, closeTo(151.209296, 1e-9));
    });

    test('refuses anything that is not our maps link', () {
      expect(ChatLocation.parseUrl(null), isNull);
      expect(ChatLocation.parseUrl('On on!'), isNull);
      expect(ChatLocation.parseUrl('https://maps.apple.com/?q=1,2'), isNull);
      expect(
        ChatLocation.parseUrl('$kChatLocationUrlPrefix${'51.5'}'),
        isNull,
      );
      expect(
        ChatLocation.parseUrl('${kChatLocationUrlPrefix}91,0'),
        isNull,
      );
      expect(
        ChatLocation.parseUrl('${kChatLocationUrlPrefix}a,b'),
        isNull,
      );
      expect(
        ChatLocation.parseUrl('${kChatLocationUrlPrefix}1,2,3'),
        isNull,
      );
    });

    test('display is five decimals', () {
      expect(const ChatLocation(51.5074, -0.1278).display, '51.50740, -0.12780');
    });
  });

  group('ChatMessageKind.fromJson', () {
    test('reads the server integer', () {
      expect(ChatMessageKind.fromJson(1), ChatMessageKind.photo);
      expect(ChatMessageKind.fromJson(2.0), ChatMessageKind.location);
    });

    test('absent or odd is text', () {
      expect(ChatMessageKind.fromJson(null), ChatMessageKind.text);
      expect(ChatMessageKind.fromJson('1'), ChatMessageKind.text);
    });
  });

  group('isChatPhotoUrl', () {
    test('only our chat-photos container', () {
      expect(
        isChatPhotoUrl(
          'https://harriercentral.blob.core.windows.net/chat-photos/2026/09/a-b.jpg',
        ),
        isTrue,
      );
      expect(isChatPhotoUrl('https://example.com/x.jpg'), isFalse);
      expect(isChatPhotoUrl(null), isFalse);
    });
  });
}
