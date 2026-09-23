import 'package:harrier_central/imports.dart';

/// State for the invite-code page: the code field, the optional QR scanner
/// that fills it, and the device-authorisation submit with its "code not
/// found" / "account removed" branches.
class InviteCodeController extends QrScanController {
  InviteCodeController({this.initialCode});

  /// A code obtained without typing — the passkey sign-in (E9.F7.S13) —
  /// which the page submits on its own as soon as it is shown.
  final String? initialCode;

  static const String tag = 'invite-code';

  late final TextEditingController inviteCodeTextController;
  final FocusNode inviteCodeFocusNode = FocusNode();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool showQrScanner = false.obs;

  /// Failed "code not found" attempts. Mistyping a six-letter code is easy, so
  /// there is no attempt limit — this only decides when to also *offer* a way
  /// onward, for someone who has checked the code and knows it is right.
  int _notFoundAttempts = 0;

  String emailAddress = '';
  String _lastQrCode = '';

  @override
  void onInit() {
    super.onInit();
    inviteCodeTextController = TextEditingController(text: initialCode ?? '');
    if ((initialCode ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isClosed) unawaited(submitInviteCode());
      });
    }
  }

  @override
  void onClose() {
    inviteCodeTextController.dispose();
    inviteCodeFocusNode.dispose();
    super.onClose();
  }

  /// The QR button beside the code field.
  void toggleQrScanner() {
    showQrScanner.value = !showQrScanner.value;
    if (showQrScanner.value) {
      _lastQrCode = '';
      unawaited(scanner.start());
    } else {
      unawaited(scanner.pause());
    }
  }

  @override
  Future<void> onCodeRead(String scanResult) async {
    if (scanResult.isEmpty ||
        !showQrScanner.value ||
        _lastQrCode == scanResult) {
      return;
    }
    _lastQrCode = scanResult;
    final Map<String, String> result = Utilities.validateScan(
      scanResult,
      Utilities.qrScanTypeFlag_resetCode +
          Utilities.qrScanTypeFlag_userSecretCode,
    );
    await scanner.pause();
    if (isClosed) return;
    isScanning.value = false;
    showQrScanner.value = false;

    if (result['validScan'] == 'false') {
      await Utilities.showAlert(
        'Wrong QR Code',
        'The QR Code you scanned is not a valid Harrier Central invite code. Please use a proper invite code or manually type in your invite code on this screen.',
        'OK',
      );
    } else {
      inviteCodeTextController.text = scanResult.replaceAll(
        QR_PREFIX_USER_RESET_CODE,
        '',
      );
    }
  }

  /// "Email me a new invite code" — remembers the address for next time.
  Future<String> emailNewCode(String email) {
    emailAddress = email;
    return HashersService.sendInviteCodeByEmail(email);
  }

  /// The Get Started button — also run unprompted when the page opened with
  /// a code from the passkey sign-in.
  Future<void> submitInviteCode() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    final AuthorizeDeviceService srv = AuthorizeDeviceService();
    final Map<String, String> result = await srv.authorizeDevice(
      scanText: normalizeInviteCode(inviteCodeTextController.text),
    );
    if (isClosed) return;
    isLoading.value = false;

    if (result['result'] != 'failed') {
      final String userName =
          getStringPref(StringPrefsEnum.displayName) ?? '<no name>';
      String? profilePhotoUrl = getStringPref(StringPrefsEnum.profilePhotoUrl);
      profilePhotoUrl ??= bundledAvatarUrl(Random.secure().nextInt(49) + 1);

      await Utilities.showAlert(
        'Success!',
        'The app has been successfully set up for $userName.',
        'OK',
      );

      final NavigatorState? nav = navigatorKey.currentState;
      if (nav == null) return;
      nav.pop();
      await nav.pushReplacement<dynamic, dynamic>(
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) => ChooseProfileImage(
            isForThisDevice: true,
            fileNamePrefix:
                getStringPref(StringPrefsEnum.supportCode) ?? '<no code>',
            currentProfileImage: profilePhotoUrl,
            popToCaller: false,
          ),
        ),
      );
      return;
    }

    final int? errorCode = int.tryParse(result['errorCode'] ?? '');

    if (errorCode == DB_ERROR_ACCOUNT_REMOVED) {
      // The code was entered CORRECTLY — it resolved to a real account that
      // has since been removed. Never ask them to retype it; that is an
      // endless loop. They may still have a second, live account (a kennel
      // admin may have created one for them), so send them to look
      // themselves up.
      await Utilities.showAlert(
        'Let\'s find your account',
        'That invite code is no longer active.'
            '\r\n\r\nEnter your hash name or email address '
            'and we\'ll find your account.',
        'Continue',
      );
      await OnboardingFlowController.start(OnboardingDestination.findMyAccount);
      return;
    }

    if (errorCode == DB_ERROR_INVITE_CODE_NOT_FOUND) {
      _notFoundAttempts++;
      // After a couple of misses, also offer a way on — by then it is more
      // likely the code is stale than mistyped. Retrying stays the default.
      if (_notFoundAttempts >= 2) {
        final bool findAccount =
            await Utilities.showAlert(
              'Code not found',
              'We couldn\'t find that invite code.'
                  '\r\n\r\nIf you\'re sure it\'s right it may '
                  'have expired — we can look up your '
                  'account instead.',
              'Find my account',
              showCancelButton: true,
            ) ??
            false;
        if (findAccount) {
          await OnboardingFlowController.start(
            OnboardingDestination.findMyAccount,
          );
        }
      } else {
        await Utilities.showAlert(
          'Code not found',
          'We couldn\'t find that invite code. Please check it and try again.',
          'OK',
        );
      }
      return;
    }

    await Utilities.showAlert(
      'Setup failed',
      result['message'] ??
          'We could not set up your device. Please check your invite code and try again.',
      'OK',
    );
  }
}
