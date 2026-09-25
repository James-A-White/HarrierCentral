import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:harrier_central/util/route_tag.dart';

/// Stands in for RunTabsController: owns something that must not be used
/// after onClose (the TabController / MapController in the real one).
class _PageController extends GetxController {
  bool closed = false;

  @override
  void onClose() {
    closed = true;
    super.onClose();
  }
}

/// Stands in for RunTabs: binds its controller by [tagFor] and records, under
/// its own [label], which controller instance it ended up with. By label, not
/// by order: the popped page rebuilds after the new one is pushed.
class _Page extends StatelessWidget {
  const _Page({required this.label, required this.tagFor, required this.seen});

  final String label;
  final String Function(BuildContext) tagFor;
  final Map<String, _PageController> seen;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<_PageController>(
      init: _PageController(),
      tag: tagFor(context),
      builder: (_PageController c) {
        seen[label] = c;
        return const SizedBox.shrink();
      },
    );
  }
}

/// Asks for the tag twice per build, as two widgets in one page would.
class _TagProbe extends StatelessWidget {
  const _TagProbe({required this.label, required this.tags});

  final String label;
  final Map<String, Set<String>> tags;

  @override
  Widget build(BuildContext context) {
    (tags[label] ??= <String>{})
      ..add(routeScopedTag(context, 'x'))
      ..add(routeScopedTag(context, 'x'));
    return const SizedBox.shrink();
  }
}

/// A notification tap on build 1401: pop the open run page and push a fresh
/// one for the SAME run in the same frame, then let the pop animation finish.
Future<_PageController> _popAndPushSameRun(
  WidgetTester tester,
  String Function(BuildContext) tagFor,
) async {
  await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
  final Map<String, _PageController> seen = <String, _PageController>{};

  Get.to<void>(() => _Page(label: 'old', tagFor: tagFor, seen: seen));
  await tester.pumpAndSettle();

  Get.back<void>();
  Get.to<void>(() => _Page(label: 'new', tagFor: tagFor, seen: seen));
  await tester.pumpAndSettle();

  return seen['new']!; // the controller the page on screen is using
}

void main() {
  tearDown(Get.reset);

  testWidgets('an id-only tag: the popped page deletes the live page\'s '
      'controller (the 1401 bug, kept as proof the test can fail)', (
    WidgetTester tester,
  ) async {
    final _PageController live = await _popAndPushSameRun(
      tester,
      (_) => 'runtabs-event-1',
    );
    expect(live.closed, isTrue);
  });

  testWidgets('a route-scoped tag: the page on screen keeps its controller', (
    WidgetTester tester,
  ) async {
    final _PageController live = await _popAndPushSameRun(
      tester,
      (BuildContext context) => routeScopedTag(context, 'runtabs-event-1'),
    );
    expect(live.closed, isFalse);
  });

  testWidgets('widgets in one page share a tag; two pages do not', (
    WidgetTester tester,
  ) async {
    final Map<String, Set<String>> tags = <String, Set<String>>{};

    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    Get.to<void>(() => _TagProbe(label: 'first', tags: tags));
    await tester.pumpAndSettle();
    Get.to<void>(
      () => _TagProbe(label: 'second', tags: tags),
      preventDuplicates: false,
    );
    await tester.pumpAndSettle();

    // Every build of a page, and every widget in it, gets one tag…
    expect(tags['first'], hasLength(1));
    expect(tags['second'], hasLength(1));
    // …and a second page gets a different one.
    expect(tags['second'], isNot(tags['first']));
  });
}
