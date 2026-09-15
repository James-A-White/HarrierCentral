/// Splits message text into plain runs and link runs.
///
/// Pure and tested. The chat bubble turns each link run into a tappable span;
/// hashruns.org runs open inside the app, everything else opens the browser.
class TextRun {
  const TextRun(this.text, {this.url});
  final String text;

  /// The parsed link, when this run is one. Null for plain text.
  final Uri? url;
  bool get isLink => url != null;

  @override
  String toString() => isLink ? 'Link($text)' : 'Text($text)';
}

/// http(s) URLs only. Bare "www." and email-ish tokens are left as text: a
/// wrong guess turns ordinary words into tappable nonsense, and every link
/// the app itself writes into a chat is a full https URL anyway.
///
/// Trailing punctuation that is almost never part of a URL — a full stop,
/// comma, or closing bracket at the end of a sentence — is handed back to
/// the text run so "see https://x.org/a." links to /a, not to "/a.".
final RegExp _urlPattern = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);
const String _trailingPunctuation = '.,;:!?)\]}\'"';

List<TextRun> splitLinks(String text) {
  final List<TextRun> runs = <TextRun>[];
  int last = 0;
  for (final RegExpMatch m in _urlPattern.allMatches(text)) {
    String raw = m.group(0)!;
    int end = m.end;
    while (raw.isNotEmpty && _trailingPunctuation.contains(raw[raw.length - 1])) {
      raw = raw.substring(0, raw.length - 1);
      end -= 1;
    }
    final Uri? uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasAuthority) continue;
    if (m.start > last) runs.add(TextRun(text.substring(last, m.start)));
    runs.add(TextRun(raw, url: uri));
    last = end;
  }
  if (last < text.length) runs.add(TextRun(text.substring(last)));
  return runs;
}
