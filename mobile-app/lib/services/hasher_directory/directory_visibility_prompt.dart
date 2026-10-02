import 'package:harrier_central/imports.dart';

/// Asks "Can other hashers find you?" once per hasher (E9.F1.S26).
///
/// The server holds the answer, so "once" is per hasher, not per phone: a
/// second phone, or a reinstall, does not ask again. A failed check asks
/// nothing — a dropped call is not "not asked". The question waits until
/// the main screen is up and there is an overlay to draw on (the clock
/// notice's lesson, 2026-10-01), and is never raised by the on-device
/// screen walk, which cannot answer it.
class DirectoryVisibilityPrompt {
  const DirectoryVisibilityPrompt._();

  static bool _running = false;

  static Future<void> askIfUnanswered() async {
    if (kUiTest || _running) return;
    _running = true;
    try {
      // Let the boot's own prompts (location, notifications) go first.
      await Future<void>.delayed(const Duration(seconds: 4));
      final ({bool known, int? value}) mine =
          await HasherDirectoryService.fetchMine();
      if (!mine.known || mine.value != null) return;

      for (int i = 0; i < 60 && Get.overlayContext == null; i++) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (Get.overlayContext == null) return;
      BootLogger.logBreadcrumb('[DIRECTORY] asking who may find this hasher');
      final int? answer = await showFindabilityQuestion(required: true);
      BootLogger.logBreadcrumb('[DIRECTORY] answered ${answer ?? 'nothing'}');
    } catch (e, s) {
      BootLogger.logError('[ERROR][DIRECTORY]', 'prompt failed: $e', s);
    } finally {
      _running = false;
    }
  }
}
