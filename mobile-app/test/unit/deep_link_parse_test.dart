import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';

/// The parser decides which hashruns.org URLs the app opens and where. It is
/// pure, and every wrong answer is a dead end for someone who tapped a link,
/// so the shapes are pinned here.
void main() {
  DeepLinkTarget? p(String url) => DeepLinkService.parse(Uri.parse(url));

  group('DeepLinkService.parse', () {
    test('a run link opens the run on the check-in tab', () {
      final t = p('https://www.hashruns.org/lh3/2851');
      expect(t, isNotNull);
      expect(t!.kennelSlug, 'lh3');
      expect(t.runNumber, 2851);
      expect(t.tab, RunTab.rsvp, reason: 'check-in is the default landing');
      expect(t.isLegacy, isFalse);
    });

    test('both hosts are accepted; others are not', () {
      expect(p('https://hashruns.org/lh3/2851'), isNotNull);
      expect(p('https://www.hashruns.org/LH3/2851')!.kennelSlug, 'lh3');
      expect(p('https://example.com/lh3/2851'), isNull);
    });

    test('sub-pages land on their own tab', () {
      expect(p('https://www.hashruns.org/lh3/2851/packtrack')!.tab, RunTab.map);
      expect(p('https://www.hashruns.org/lh3/2851/photos')!.tab, RunTab.photos);
      expect(p('https://www.hashruns.org/lh3/2851/trail-tv')!.tab, RunTab.details,
          reason: 'no Trail TV in the app — the run page is the right landing');
    });

    test('the next-run link, in both spellings, is the kennel\'s next run', () {
      for (final String spelling in <String>['nextrun', 'next-run', 'NextRun']) {
        final t = p('https://www.hashruns.org/lh3/$spelling');
        expect(t, isNotNull, reason: spelling);
        expect(t!.nextRun, isTrue, reason: spelling);
        expect(t.kennelSlug, 'lh3');
        expect(t.runNumber, isNull);
      }
    });

    test("kennel pages are the website's, not runs", () {
      for (final String page in <String>[
        'songs', 'about', 'runs', 'events', 'legacy', 'photos',
      ]) {
        expect(p('https://www.hashruns.org/lh3/$page'), isNull, reason: page);
      }
    });

    test('root, a bare kennel, and nonsense run numbers are not ours', () {
      expect(p('https://www.hashruns.org/'), isNull);
      expect(p('https://www.hashruns.org/lh3'), isNull);
      expect(p('https://www.hashruns.org/lh3/'), isNull);
      expect(p('https://www.hashruns.org/lh3/0'), isNull);
      expect(p('https://www.hashruns.org/lh3/-5'), isNull);
      expect(p('https://www.hashruns.org/lh3/abc'), isNull);
    });

    test('the legacy QR form is read from the fragment', () {
      final t = p(
        'https://www.hashruns.org/#/RID?publicEventId=0CDBB109-215E-4B5F-A405-F6C9FBCB18EC',
      );
      expect(t, isNotNull);
      expect(t!.isLegacy, isTrue);
      expect(t.publicEventId, '0cdbb109-215e-4b5f-a405-f6c9fbcb18ec',
          reason: 'UUIDs are lowercase everywhere in this app');
      expect(p('https://www.hashruns.org/#/RID'), isNull);
      expect(p('https://www.hashruns.org/#/other?publicEventId=x'), isNull);
    });
  });
}
