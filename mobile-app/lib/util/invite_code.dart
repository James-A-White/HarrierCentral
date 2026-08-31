import 'package:harrier_central/imports.dart';

/// Normalises whatever the user typed, pasted or scanned into the exact form
/// `hcapp_authorizeDevice` expects: `URC:` followed by six uppercase letters.
///
/// Invite codes are generated from a letters-only alphabet
/// (`nonApi_getUserInviteCode` uses A-Z, no digits), so any digit in the input
/// is unambiguously a mistyped letter and can be corrected with no risk of
/// collision. That kills the commonest transcription errors — reading a code
/// off a screen or a handwritten note — before we ever call it a failure.
String normalizeInviteCode(String raw) {
  String code = raw.trim().toUpperCase();

  // A helpful paste often includes the prefix; the emailed code does not.
  // Strip any number of them so we never build 'URC:URC:ABCDEF'.
  while (code.startsWith(QR_PREFIX_USER_RESET_CODE)) {
    code = code.substring(QR_PREFIX_USER_RESET_CODE.length).trim();
  }

  // Digits cannot appear in a valid code, so these are always mistakes.
  code = code
      .replaceAll('0', 'O')
      .replaceAll('1', 'I')
      .replaceAll('5', 'S');

  // Drop anything that is still not a letter (spaces, dashes, stray symbols).
  code = code.replaceAll(RegExp(r'[^A-Z]'), '');

  return QR_PREFIX_USER_RESET_CODE + code;
}
