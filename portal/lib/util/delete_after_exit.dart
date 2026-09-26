import 'package:get/get.dart';

/// Delete a page's or dialog's controller once the route has finished
/// animating away — never while it is still on screen.
///
/// `await Get.to(...)` and `await Get.dialog(...)` complete when the route is
/// POPPED, which is the START of its exit animation. For about 300 ms the
/// route is still painted. Deleting its controller then disposes whatever the
/// controller owns — a TabController in particular — under widgets that are
/// still drawing, and the next paint of a TabBar dies in
/// `_IndicatorPainter.paint` on `controller.animation!` ("Null check operator
/// used on a null value", Kilty, portal 2.0.86, 2026-09-23). Deleting BEFORE
/// the pop is worse: the page is fully visible.
///
/// So: pop first, then `await deleteAfterExit(controller)`. Only [instance]
/// is deleted: if the page was reopened in the meantime and registered a new
/// controller under the same type and tag, that one is left alone.
Future<void> deleteAfterExit<S>(S instance, {String? tag}) async {
  final Duration exit = Get.defaultTransitionDuration >
          Get.defaultDialogTransitionDuration
      ? Get.defaultTransitionDuration
      : Get.defaultDialogTransitionDuration;
  // A margin over the longest transition: the last exit frame must be gone.
  await Future<void>.delayed(exit + const Duration(milliseconds: 150));
  if (Get.isRegistered<S>(tag: tag) &&
      identical(Get.find<S>(tag: tag), instance)) {
    await Get.delete<S>(tag: tag, force: true);
  }
}
