import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/util/link_text.dart';

void main() {
  group('splitLinks', () {
    test('plain text is one plain run', () {
      final r = splitLinks('On on, see you at the pub');
      expect(r.length, 1);
      expect(r.single.isLink, isFalse);
    });

    test('a link in a sentence becomes text, link, text', () {
      final r = splitLinks('Run notice: https://www.hashruns.org/lh3/2851 — RSVP!');
      expect(r.map((x) => x.isLink).toList(), [false, true, false]);
      expect(r[1].url.toString(), 'https://www.hashruns.org/lh3/2851');
      expect(r[2].text, ' — RSVP!');
    });

    test('sentence punctuation is not swallowed into the link', () {
      final r = splitLinks('Details: https://www.hashruns.org/lh3/2851.');
      expect(r[1].url.toString(), 'https://www.hashruns.org/lh3/2851');
      expect(r.last.text, '.');
      final b = splitLinks('(see https://example.com/a)');
      expect(b[1].url.toString(), 'https://example.com/a');
      expect(b.last.text, ')');
    });

    test('a query string and fragment survive intact', () {
      final r = splitLinks('https://www.hashruns.org/#/RID?publicEventId=abc-123');
      expect(r.single.isLink, isTrue);
      expect(r.single.url!.fragment, '/RID?publicEventId=abc-123');
    });

    test('bare www and non-http schemes stay as text', () {
      expect(splitLinks('www.hashruns.org is the site').single.isLink, isFalse);
      expect(splitLinks('ftp://old.example.com/file').single.isLink, isFalse);
    });

    test('several links in one message each get their own run', () {
      final r = splitLinks('a https://one.org b https://two.org c');
      expect(r.where((x) => x.isLink).length, 2);
      expect(r.length, 5);
    });
  });
}
