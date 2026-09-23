import 'package:harrier_central/imports.dart';

/// A snackbar that needs no BuildContext — for GetX controllers.
///
/// A controller has no context, and a context captured for later is a bug
/// (CLAUDE.md: the row that opened a snackbar is gone by the time it shows).
/// `Get.rawSnackbar` draws on the app overlay instead. It THROWS when that
/// overlay is not ready, and a GetX snackbar throwing around show/close has
/// crashed the app twice (11 and 12 Sep 2026), so it is guarded here once
/// rather than at every call site.
void hcSnack(String message, {bool error = false, int seconds = 3}) {
  try {
    Get.rawSnackbar(
      message: message,
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      duration: Duration(seconds: seconds),
      snackPosition: SnackPosition.BOTTOM,
    );
  } catch (e, s) {
    BootLogger.logError('[hcSnack] $message', e, s);
  }
}

/// `Get.closeAllSnackbars()`, without the async throw.
///
/// In GetX 4.7.3 `closeAllSnackbars` is `void` but starts an async
/// `_cancelAllJobs()` and discards its future. When a queued snackbar's
/// animation controller is already gone, that future fails with "Null check
/// operator used on a null value" in `AnimationController.stop` — AFTER the
/// call has returned, so a `try/catch` around it catches nothing and the error
/// lands as an uncaught `[ERROR][ASYNC]` (build 1394, 2026-09-23). A guarded
/// zone owns that discarded future, so its failure comes back here instead.
/// Closing is best-effort: failing to close a toast is not an app error.
void closeAllSnackbarsSafely() {
  runZonedGuarded(
    Get.closeAllSnackbars,
    (Object e, StackTrace s) =>
        BootLogger.logBreadcrumb('[hcSnack] closeAllSnackbars failed: $e'),
  );
}
