import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// In-house replacement for the `flutter_linkify` package (last published
/// 2023): renders text with URLs turned into tappable links. API-compatible
/// with the subset the app uses (text/style/linkStyle/textAlign/onOpen).
class LinkableElement {
  LinkableElement(this.url, this.text);
  final String url;
  final String text;
}

class Linkify extends StatelessWidget {
  const Linkify({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
    this.textAlign = TextAlign.start,
    this.onOpen,
  });

  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final TextAlign textAlign;
  final void Function(LinkableElement link)? onOpen;

  static final RegExp _urlPattern = RegExp(
    r'(https?://[^\s<>()]+|www\.[^\s<>()]+)',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final List<InlineSpan> spans = <InlineSpan>[];
    int last = 0;
    for (final Match m in _urlPattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      // Trim trailing punctuation that's almost never part of the URL.
      String raw = m.group(0)!;
      final Match? trail = RegExp(r'[.,;:!?]+$').firstMatch(raw);
      String tail = '';
      if (trail != null) {
        tail = trail.group(0)!;
        raw = raw.substring(0, raw.length - tail.length);
      }
      final String url = raw.startsWith('www.') ? 'https://$raw' : raw;
      final LinkableElement element = LinkableElement(url, raw);
      spans.add(
        TextSpan(
          text: raw,
          style: linkStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onOpen?.call(element),
        ),
      );
      if (tail.isNotEmpty) spans.add(TextSpan(text: tail));
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return Text.rich(
      TextSpan(style: style, children: spans),
      textAlign: textAlign,
    );
  }
}
