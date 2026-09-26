import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hcportal/util/delete_after_exit.dart';

class _Probe extends GetxController {
  bool closed = false;

  @override
  void onClose() {
    closed = true;
    super.onClose();
  }
}

/// deleteAfterExit waits out the exit animation before deleting, and deletes
/// only the instance it was given (portal 2.0.86 TabBar null check,
/// 2026-09-23: a controller deleted while its page was still painting).
void main() {
  tearDown(Get.reset);

  test('the controller survives the exit animation, then is deleted',
      () async {
    final probe = Get.put(_Probe(), tag: 'a');
    final pending = deleteAfterExit(probe, tag: 'a');

    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(probe.closed, isFalse, reason: 'still on screen — must not close');

    await pending;
    expect(probe.closed, isTrue);
    expect(Get.isRegistered<_Probe>(tag: 'a'), isFalse);
  });

  test('a controller registered by a reopened page is left alone', () async {
    final old = Get.put(_Probe(), tag: 'b');
    final pending = deleteAfterExit(old, tag: 'b');

    // The page is reopened before the old one has finished leaving.
    await Get.delete<_Probe>(tag: 'b', force: true);
    final fresh = Get.put(_Probe(), tag: 'b');

    await pending;
    expect(fresh.closed, isFalse);
    expect(Get.isRegistered<_Probe>(tag: 'b'), isTrue);
  });
}
