import 'package:harrier_central/imports.dart';

/// What happens when the server says this device has been signed out
/// (E9.F7.S19).
///
/// The signal is `errorType == 7` from ValidateAppAuth, and ONLY that. It is
/// deliberately not the ordinary bad-token error (type 1): a phone whose
/// clock has drifted produces that one, and wiping an install because a
/// clock slipped would be a catastrophe dressed as a security feature.
///
/// The response is the one a fresh install gets: tell the hasher plainly,
/// then wipe everything this device holds — GetStorage, the keychain (and
/// its Android equivalent) and the local database — and reboot into guest
/// discovery. AppBootService.resetAndReboot(keepResetCode: false) already
/// does exactly that; it is the same path the Log Out button takes, so the
/// wipe is not written twice.
class SignedOutHandler {
  const SignedOutHandler._();

  /// The server's "this device was signed out" error type.
  static const int signedOutErrorType = 7;

  /// True once the flow has started, so the five calls that fail together
  /// raise ONE dialog and ONE wipe rather than five. It is never reset:
  /// the app is on its way to a reboot.
  static bool _handling = false;

  static bool get isHandling => _handling;

  /// Returns true when [errorType] means this device has been signed out.
  static bool isSignedOut(num? errorType) =>
      errorType != null && errorType.toInt() == signedOutErrorType;

  /// Tell the hasher, wipe the device, reboot into guest discovery.
  ///
  /// [message] is the server's own wording when it sent any.
  static Future<void> handle({String? message}) async {
    if (_handling) return;
    _handling = true;

    BootLogger.logBreadcrumb(
      '[SignedOut] device revoked — wiping and rebooting',
    );

    await Utilities.showAlert(
      'Signed out',
      (message == null || message.trim().isEmpty)
          ? 'This device was signed out of your Harrier Central account.\r\n\r\n'
                'Your runs and photos are safe on our servers. Sign in again '
                'to get them back on this phone.'
          : message.replaceAll('~', '\r\n'),
      'OK',
    );

    // keepResetCode: false — the recovery key goes too, so boot lands on
    // guest discovery and asks who this is, exactly as a new install does.
    await AppBootService.resetAndReboot(keepResetCode: false);
  }
}
