import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

/// A first install signs in with the passkey the hasher made on
/// hashruns.org (E9.F7.S13).
///
/// The web is the relying party: it hands out the challenge, verifies the
/// assertion against the passkey it stored on the hasher's browser device
/// row, and answers with a fresh invite code. The app then takes its own
/// `hcapp_authorizeDevice` URC path with that code — the same door an
/// emailed code opens, so there is no new auth model on the server.
///
/// iOS reports the assertion's origin as `https://hashruns.org` and Android
/// as its signing certificate's hash; the web accepts both. The app must
/// carry the `webcredentials:hashruns.org` entitlement (iOS) and be listed
/// in `/.well-known/assetlinks.json` with `get_login_creds` (Android).
class PasskeySignInService {
  static const String _base = 'https://www.hashruns.org/api/member/passkey';
  static const Duration _timeout = Duration(seconds: 20);

  /// Returns the six-letter invite code, or throws a
  /// [PasskeySignInException] with a message fit to show.
  Future<String> signIn() async {
    final http.Response opt = await http
        .post(Uri.parse('$_base/app-options'))
        .timeout(_timeout);
    if (opt.statusCode != 200) {
      throw PasskeySignInException(
        'Passkey sign-in is not available right now. Please try again later.',
      );
    }
    final Map<String, dynamic> j = jsonDecode(opt.body) as Map<String, dynamic>;
    final Map<String, dynamic> options = j['options'] as Map<String, dynamic>;
    final String ticket = j['ticket'] as String;

    final AuthenticateRequestType request = AuthenticateRequestType.fromJson(
      options,
      mediation: MediationType.Optional,
      preferImmediatelyAvailableCredentials: true,
    );

    final AuthenticateResponseType res;
    try {
      res = await PasskeyAuthenticator().authenticate(request);
    } on PasskeyAuthCancelledException {
      throw PasskeySignInException('Passkey sign-in was cancelled.');
    } on NoCredentialsAvailableException {
      throw PasskeySignInException(
        'No passkey for hashruns.org was found on this device.\r\n\r\n'
        'Sign in at www.hashruns.org on this device first, or use an invite code.',
      );
    } on DeviceNotSupportedException {
      throw PasskeySignInException(
        'This device does not support passkeys. Please use an invite code.',
      );
    } on DomainNotAssociatedException catch (e) {
      throw PasskeySignInException(
        'Passkeys are not set up for this build of the app (${e.message ?? 'domain not associated'}).',
      );
    } on AuthenticatorException catch (e) {
      throw PasskeySignInException('Passkey sign-in failed: $e');
    }

    final String body = jsonEncode(<String, dynamic>{
      'ticket': ticket,
      'response': <String, dynamic>{
        'id': res.id,
        'rawId': res.rawId,
        'type': 'public-key',
        'response': <String, dynamic>{
          'clientDataJSON': res.clientDataJSON,
          'authenticatorData': res.authenticatorData,
          'signature': res.signature,
          'userHandle': res.userHandle.isEmpty ? null : res.userHandle,
        },
        'clientExtensionResults':
            res.clientExtensionResults ?? <String, dynamic>{},
      },
    });
    final http.Response ver = await http
        .post(
          Uri.parse('$_base/app-verify'),
          headers: <String, String>{'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);
    Map<String, dynamic> v = <String, dynamic>{};
    try {
      v = jsonDecode(ver.body) as Map<String, dynamic>;
    } catch (_) {}
    if (ver.statusCode != 200 || v['ok'] != true) {
      throw PasskeySignInException(
        (v['error'] as String?) ?? "That passkey couldn't be verified.",
      );
    }
    return v['inviteCode'] as String;
  }
}

class PasskeySignInException implements Exception {
  PasskeySignInException(this.message);
  final String message;
  @override
  String toString() => message;
}
