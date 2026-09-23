import 'package:harrier_central/imports.dart';

/// State for the Support page: the secret QR code (keychain, so async), the
/// Reload Data reboot and the copy-log button's two-second "Copied!".
class SupportController extends GetxController {
  static const String tag = 'support';

  final String userName = getStringPref(StringPrefsEnum.displayName) ?? '';
  final String supportCode = getStringPref(StringPrefsEnum.supportCode) ?? '';
  final RxString userSecretCode = ''.obs;
  final RxBool isReloading = false.obs;
  final RxBool bootLogCopied = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_loadSecretCode());
  }

  // qrSecretCode lives in the keychain (async) — load it after first frame.
  Future<void> _loadSecretCode() async {
    final String code = await getQrSecretCode() ?? '';
    if (isClosed) return;
    userSecretCode.value = code;
  }

  Future<void> reloadData() async {
    isReloading.value = true;
    await AppBootService.resetAndReboot(keepResetCode: true);
    // Reached only if the reset was aborted (e.g. offline) — clear the spinner.
    if (isClosed) return;
    isReloading.value = false;
  }

  Future<void> copyBootLogToClipboard() async {
    final text =
        getStringPref(StringPrefsEnum.lastSessionErrorLog) ?? 'No error log.';
    await Clipboard.setData(ClipboardData(text: text));
    if (isClosed) return;
    bootLogCopied.value = true;
    Future.delayed(const Duration(seconds: 2), () {
      if (!isClosed) bootLogCopied.value = false;
    });
  }
}
