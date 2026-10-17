import 'package:crypto/crypto.dart';
import 'package:harrier_central/imports.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Sign in with Apple, verified on the server (E1.F1.S8, James 2026-10-17).
///
/// The phone makes a fresh random nonce for THIS attempt and gives Apple its
/// SHA-256; Apple signs an identity token carrying that hash. The phone sends
/// the token and the RAW nonce to the API's ThirdPartySignIn, which checks
/// the signature against Apple's keys, the audience (our bundle id), the
/// expiry and the nonce — so a captured token cannot be replayed — and
/// answers with the account's reset code. The caller then signs the phone in
/// with that code exactly as with an emailed one (UseInviteCodePage).
class AppleSignInService {
  static const String _url = 'https://$BASE_AF_URL/api/ThirdPartySignIn';

  /// The reset code to sign in with, or null when the person cancelled.
  /// Throws [AppleSignInException] with a message to show otherwise.
  static Future<String?> signInForCode() async {
    final String rawNonce = _randomNonce();
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw AppleSignInException('Apple sign-in did not complete (${e.code.name}).');
    }
    final String? token = credential.identityToken;
    if (token == null || token.isEmpty) {
      throw const AppleSignInException('Apple did not return a sign-in token. Please try again.');
    }

    http.Response r;
    try {
      r = await http
          .post(
            Uri.parse(_url),
            headers: const <String, String>{'content-type': 'application/json'},
            body: jsonEncode(<String, dynamic>{
              'provider': 'apple',
              'identityToken': token,
              'rawNonce': rawNonce,
              // Apple sends names only the first time; used only for a new account.
              'firstName': credential.givenName,
              'lastName': credential.familyName,
              'hcVersion': getStringPref(StringPrefsEnum.harrierCentralVersionAndBuild),
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const AppleSignInException(
        'No connection to Harrier Central. Check your connection and try again.',
      );
    }
    Map<String, dynamic> j = <String, dynamic>{};
    try {
      j = jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    if (r.statusCode != 200 || (j['resetCode'] as String?) == null) {
      throw AppleSignInException(
        (j['errorUserMessage'] as String?) ??
            'Apple sign-in could not be completed (${r.statusCode}).',
      );
    }
    return j['resetCode'] as String;
  }

  static String _randomNonce([int length = 32]) {
    const String chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final Random rnd = Random.secure();
    return List<String>.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}

class AppleSignInException implements Exception {
  const AppleSignInException(this.message);
  final String message;
  @override
  String toString() => message;
}
