// A page that owns its controller: GetBuilder(init:, global: false,
// dispose: onDelete). ChatPage relies on this (2026-09-28): each chat page
// closes its own controller and nobody else's. Before, one untagged
// Get.put was shared by every chat page, and closing any of them left the
// one on screen with a closed controller ("Cannot add new events after
// calling close", 1419).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Owned extends GetxController {
  _Owned(this.name);
  final String name;
  bool closed = false;

  @override
  void onClose() {
    closed = true;
    super.onClose();
  }
}

class _Page extends StatelessWidget {
  const _Page(this.name, this.seen);
  final String name;
  final Map<String, _Owned> seen;

  @override
  Widget build(BuildContext context) => GetBuilder<_Owned>(
    // Without this key, removing page a (unkeyed Column) reuses a's element
    // for b and b inherits a's controller. ChatPage keys on its thread.
    key: ValueKey<String>(name),
    init: _Owned(name),
    global: false,
    dispose: (state) => state.controller?.onDelete(),
    builder: (_Owned c) {
      seen[name] = c; // by page: which controller is driving it now
      return Text(name);
    },
  );
}

void main() {
  testWidgets('each page closes its own controller and no other', (
    WidgetTester tester,
  ) async {
    final Map<String, _Owned> seen = <String, _Owned>{};
    final ValueNotifier<bool> showA = ValueNotifier<bool>(true);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: showA,
          builder: (_, bool a, _) => Column(
            children: <Widget>[if (a) _Page('a', seen), _Page('b', seen)],
          ),
        ),
      ),
    );
    final _Owned a = seen['a']!;
    expect(Get.isRegistered<_Owned>(), isFalse);

    showA.value = false; // page a goes; b is still on screen
    await tester.pump();
    expect(a.closed, isTrue);
    final _Owned b = seen['b']!;
    expect(b.name, 'b'); // b did not inherit a's controller
    expect(b.closed, isFalse);

    await tester.pumpWidget(const SizedBox()); // b goes
    expect(b.closed, isTrue);
  });
}
