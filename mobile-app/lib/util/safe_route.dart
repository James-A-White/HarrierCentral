import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:harrier_central/util/boot_logger.dart';

/// Replaces the current page in a way that also works when the navigator has
/// no history.
///
/// `Get.off` is `Navigator.pushReplacement`, and Flutter's
/// `_pushReplacementEntry` starts with `_history.lastWhere(...)` — which
/// throws `Bad state: No element` when the history is empty. The boot path can
/// find it empty: a notification tap that ran `Get.until` before `/main`
/// existed would clear it, and a device did exactly that on 2026-09-21
/// (3.0.12+1327, `AppBootService._handleExistingUser`). 3.1.0+1389 removed
/// that particular way of emptying the navigator, but nothing stops another.
///
/// The consequence was worse than the error: the boot sequence threw on its
/// way to the main page, so the app sat on the splash with nowhere to go.
///
/// `Get.offAll` builds a fresh stack rather than replacing the top of an
/// existing one, so it works from empty. Trying the cheap call first keeps the
/// normal path exactly as it was — the fallback only runs where the old code
/// would have thrown.
Future<void> safeReplaceRoute(
  Widget Function() page, {
  required String routeName,
}) async {
  try {
    await Get.off(page, routeName: routeName);
  } catch (e, s) {
    BootLogger.logError(
      '[ERROR][BOOT]',
      'Get.off($routeName) failed on an empty navigator; using offAll: $e',
      s,
    );
    await Get.offAll(page, routeName: routeName);
  }
}
