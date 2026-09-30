import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/services/chat_reactions/chat_reaction_service.dart';
import 'package:harrier_central/util/chat_message_kind.dart';

/// Chat reactions (E9.F1.S22): the fixed six, the JSON the server keeps
/// them in, and the one-line quote a reply carries (E9.F1.S21).
void main() {
  test('the palette is the fixed six, in order', () {
    expect(
      ChatReaction.all.map((r) => r.code).toList(),
      ['thumbs', 'heart', 'laugh', 'beer', 'run', 'fire'],
    );
    expect(ChatReaction.byCode('beer')!.emoji, '🍺');
    expect(ChatReaction.isKnown('wave'), isFalse);
  });

  test('parses the server JSON and lowercases every id', () {
    final m = parseChatReactions(
      '{"beer":["AAAA0000-1111-2222-3333-444455556666"],"thumbs":["b","C"]}',
    );
    expect(m['beer'], ['aaaa0000-1111-2222-3333-444455556666']);
    expect(m['thumbs'], ['b', 'c']);
  });

  test('null, empty, junk and empty lists all mean no reactions', () {
    expect(parseChatReactions(null), isEmpty);
    expect(parseChatReactions(''), isEmpty);
    expect(parseChatReactions('not json'), isEmpty);
    expect(parseChatReactions('[1,2]'), isEmpty);
    expect(parseChatReactions('{"beer":[]}'), isEmpty);
  });

  test('a decoded map is accepted too', () {
    expect(parseChatReactions({'fire': ['X']}), {'fire': ['x']});
  });

  test('quote snippets name a photo or a location, and keep text', () {
    expect(chatQuoteSnippet(ChatMessageKind.text, '  hi  '), 'hi');
    expect(chatQuoteSnippet(ChatMessageKind.photo, 'https://x/y.jpg'), '📷 Photo');
    expect(chatQuoteSnippet(ChatMessageKind.location, 'geo:1,2'), '📍 Location');
  });
}
