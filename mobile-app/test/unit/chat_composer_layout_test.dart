import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1428 wrapped the Composer in a Column to put the reply bar above it, and
/// every chat page failed to build (grey screen on James's and Tuna's
/// phones, 2026-10-01): the Composer returns a Positioned that must be a
/// direct child of the chat's Stack. The bar goes in Composer.topWidget.
Widget _chat(Widget Function(BuildContext) composer) {
  final core.InMemoryChatController c = core.InMemoryChatController();
  return MaterialApp(
    home: Scaffold(
      body: Chat(
        currentUserId: 'me',
        resolveUser: (String id) async => core.User(id: id, name: id),
        chatController: c,
        onMessageSend: (_) {},
        builders: core.Builders(composerBuilder: composer),
      ),
    ),
  );
}

/// The chat library leaves a short timer running; let it fire before the
/// test ends.
Future<void> _teardown(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 5));
  t.takeException();
}

void main() {
  testWidgets('reply bar in Composer.topWidget builds', (WidgetTester t) async {
    await t.pumpWidget(_chat((_) => const Composer(topWidget: Text('Replying to Opee'))));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text('Replying to Opee'), findsOneWidget);
    await _teardown(t);
  });

  testWidgets('wrapping the Composer in a Column is the bug this guards', (WidgetTester t) async {
    await t.pumpWidget(_chat((_) => const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[Text('bar'), Composer()],
        )));
    await t.pump();
    expect(t.takeException(), isNotNull);
    await _teardown(t);
  });
}
