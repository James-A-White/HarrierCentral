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
