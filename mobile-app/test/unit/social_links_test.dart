import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/services/kennels/kennel_social_links_service.dart';
import 'package:harrier_central/util/social_links.dart';

/// The kennel page's social and chat links (E12.F4.S4): what the app will
/// show from HC.Kennel.SocialLinksJson as hcapp_getKennelSocialLinks hands it
/// over. The parser is the app's last check before a tap opens another app.
void main() {
  group('socialLinksFromJson', () {
    test('null, empty, broken and non-array JSON are an empty list', () {
      expect(socialLinksFromJson(null), isEmpty);
      expect(socialLinksFromJson(''), isEmpty);
      expect(socialLinksFromJson('   '), isEmpty);
      expect(socialLinksFromJson('not json'), isEmpty);
      expect(socialLinksFromJson('[{"platform":"whatsapp",'), isEmpty);
      expect(socialLinksFromJson('{"platform":"facebook"}'), isEmpty);
      expect(socialLinksFromJson('[1, "x", null]'), isEmpty);
    });

    test('keeps good links in stored order, subdomains included', () {
      final List<SocialLink> l = socialLinksFromJson('''[
        {"platform":"instagram","url":"https://www.instagram.com/h3"},
        {"platform":"whatsapp","url":"https://chat.whatsapp.com/AbC","label":"Run chat","audience":"members"},
        {"platform":"facebook","url":"https://m.facebook.com/groups/1"}
      ]''');
      expect(l.map((SocialLink x) => x.platform), <String>[
        'instagram',
        'whatsapp',
        'facebook',
      ]);
      expect(l[1].label, 'Run chat');
      expect(l[1].displayName, 'Run chat (WhatsApp)');
    });

    test('drops a link whose host is not its platform, or not https', () {
      final List<SocialLink> l = socialLinksFromJson('''[
        {"platform":"whatsapp","url":"https://evil.example.com/chat"},
        {"platform":"whatsapp","url":"https://whatsapp.com.evil.io/x"},
        {"platform":"facebook","url":"http://facebook.com/h3"},
        {"platform":"telegram","url":"javascript:alert(1)"},
        {"platform":"youtube"},
        {"platform":"myspace","url":"https://myspace.com/h3"},
        {"platform":"telegram","url":"https://t.me/h3"}
      ]''');
      expect(l.length, 1);
      expect(l.single.url, 'https://t.me/h3');
    });

    test('"other" takes any https host, but still not http', () {
      final List<SocialLink> l = socialLinksFromJson('''[
        {"platform":"other","url":"https://h3.example.org/calendar","label":"Calendar"},
        {"platform":"other","url":"http://h3.example.org/"}
      ]''');
      expect(l.length, 1);
      expect(l.single.displayName, 'Calendar');
    });

    test('WeChat with only an ID and/or a QR image is kept, with no url', () {
      final List<SocialLink> l = socialLinksFromJson('''[
        {"platform":"wechat","handle":"h3_wechat","url":null},
        {"platform":"wechat","qrImageUrl":"https://harriercentral.blob.core.windows.net/qr.png"},
        {"platform":"wechat","handle":"h3b","url":"https://evil.example.com/"},
        {"platform":"wechat"},
        {"platform":"wechat","qrImageUrl":"http://insecure.example.com/qr.png"}
      ]''');
      expect(l.length, 3);
      expect(l[0].handle, 'h3_wechat');
      expect(l[0].opensDialog, isTrue);
      expect(l[1].qrImageUrl, isNotNull);
      // A bad url is stripped, the ID survives.
      expect(l[2].url, isNull);
      expect(l[2].handle, 'h3b');
    });

    test('audience: explicit wins; missing or odd takes the platform default', () {
      final List<SocialLink> l = socialLinksFromJson('''[
        {"platform":"whatsapp","url":"https://wa.me/1","audience":"members"},
        {"platform":"whatsapp","url":"https://wa.me/2"},
        {"platform":"whatsapp","url":"https://wa.me/3","audience":"everyone"},
        {"platform":"whatsapp","url":"https://wa.me/4","audience":"public"},
        {"platform":"facebook","url":"https://facebook.com/x"}
      ]''');
      expect(l.map((SocialLink x) => x.isMembersOnly), <bool>[
        true,
        true, // a chat group with no audience is members-only, as on the server
        true,
        false,
        false,
      ]);
    });
  });

  group('KennelSocialLinksService.parseReply', () {
    test('a members reply', () {
      final r = KennelSocialLinksService.parseReply(
        '[[{"socialLinksJson":"[{\\"platform\\":\\"line\\",\\"url\\":\\"https://line.me/x\\",\\"audience\\":\\"members\\"}]","includesMembers":1}]]',
      );
      expect(r, isNotNull);
      expect(r!.includesMembers, isTrue);
      expect(r.links.single.platform, 'line');
    });

    test('no links: NULL json is an empty list, not a failure', () {
      final r = KennelSocialLinksService.parseReply(
        '[[{"socialLinksJson":null,"includesMembers":0}]]',
      );
      expect(r, isNotNull);
      expect(r!.links, isEmpty);
      expect(r.includesMembers, isFalse);
    });

    test('an auth error row or an empty reply is null', () {
      expect(
        KennelSocialLinksService.parseReply(
          '[[{"errorId":"x","errorCode":1,"errorTitle":"t"}]]',
        ),
        isNull,
      );
      expect(KennelSocialLinksService.parseReply('[]'), isNull);
      expect(KennelSocialLinksService.parseReply('[[]]'), isNull);
    });
  });
}
