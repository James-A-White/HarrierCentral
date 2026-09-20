import 'package:harrier_central/imports.dart';

/// One passkey registered against this hasher's account (E9.F7.S18).
///
/// A passkey lives ON an HC.Device row — there is no separate table — so a
/// passkey is really "a device that can sign me in without a code". The
/// credential id and public key are deliberately never sent to the client:
/// they identify the credential to an authenticator and are of no use on a
/// settings screen.
class AccountPasskey {
  const AccountPasskey({
    required this.deviceId,
    required this.label,
    required this.platform,
    required this.isThisDevice,
    required this.isMobile,
    this.lastLogin,
    this.hasPasskey = true,
    this.isSignedOut = false,
    this.appVersion,
    this.appBuild,
  });

  /// "3.1.0 (1378)", or "version not recorded" when the row never sent one.
  String get versionLabel {
    if (appVersion == null || appVersion!.isEmpty) {
      return 'version not recorded';
    }
    return appBuild == null || appBuild!.isEmpty
        ? appVersion!
        : '$appVersion ($appBuild)';
  }

  final String deviceId;

  /// Server-built and server-owned, e.g. "Safari on iPhone". Built there so
  /// the app and the web name the same device the same way.
  final String label;
  final String platform;
  final bool isThisDevice;
  final bool isMobile;
  final DateTime? lastLogin;

  /// Whether this device holds a passkey, and whether it has been signed
  /// out. A row that is BOTH signed out and passkey-free is not returned at
  /// all — it can no longer reach the account by any route, so it leaves the
  /// list (E9.F7.S19, James 2026-09-20).
  final bool hasPasskey;
  final bool isSignedOut;

  /// What the device was running when it last signed in. Null for the 564
  /// rows platform-wide that never reported one.
  final String? appVersion;
  final String? appBuild;

  factory AccountPasskey.fromJson(Map<String, dynamic> json) => AccountPasskey(
    deviceId: ((json['DeviceId'] as String?) ?? '').asUuid,
    label: (json['Label'] as String?) ?? 'A device',
    platform: (json['Platform'] as String?) ?? '',
    // These come from CASE expressions, so they are INTs, not BIT columns —
    // but the == 1 / == true pair costs nothing and survives either.
    isThisDevice: json['IsThisDevice'] == 1 || json['IsThisDevice'] == true,
    isMobile: json['IsMobile'] == 1 || json['IsMobile'] == true,
    lastLogin: DateTime.tryParse('${json['LastLogin'] ?? ''}'),
    // listPasskeys (the older SP, still called by builds 1390/1391) sends
    // neither column and every row it returns HAS a passkey — hence the
    // defaults above.
    hasPasskey: json['HasPasskey'] == null
        ? true
        : (json['HasPasskey'] == 1 || json['HasPasskey'] == true),
    isSignedOut: json['IsSignedOut'] == 1 || json['IsSignedOut'] == true,
    appVersion: json['AppVersion'] as String?,
    appBuild: json['AppBuild']?.toString(),
  );
}

/// Reading and revoking the passkeys on this account.
///
/// Both calls return null on FAILURE and a list on success — an empty list is
/// the ordinary answer for the many hashers who have never made a passkey, and
/// must not be drawn as an error (nor a failure drawn as "you have none").
class PasskeyManageService {
  const PasskeyManageService();

  /// Every device that can reach this account, with its passkey and
  /// signed-out state (E9.F7.S19). Supersedes [fetchPasskeys].
  static Future<List<AccountPasskey>?> fetchDevices() =>
      _call(queryType: 'listDevices', procName: 'hcapp_listDevices');

  /// Cuts one device off: the server rotates its secret, drops its push
  /// tokens and takes it out of the list. Returns what is left.
  ///
  /// It does NOT remove that device's passkey — two acts, two
  /// consequences — so a signed-out device holding one stays listed until
  /// the passkey is removed too.
  static Future<List<AccountPasskey>?> signOutDevice(String targetDeviceId) =>
      _call(
        queryType: 'signOutDevice',
        procName: 'hcapp_signOutDevice',
        extra: <String, dynamic>{'targetDeviceId': targetDeviceId.asUuid},
      );

  static Future<List<AccountPasskey>?> fetchPasskeys() =>
      _call(queryType: 'listPasskeys', procName: 'hcapp_listPasskeys');

  /// Revokes one passkey and returns what REMAINS, so the screen repaints
  /// from the reply rather than asking again.
  ///
  /// Removing this device's own passkey does not sign it out: the device row
  /// and its secret survive, only the credential goes.
  static Future<List<AccountPasskey>?> deletePasskey(String targetDeviceId) =>
      _call(
        queryType: 'deletePasskey',
        procName: 'hcapp_deletePasskey',
        extra: <String, dynamic>{'targetDeviceId': targetDeviceId.asUuid},
      );

  static Future<List<AccountPasskey>?> _call({
    required String queryType,
    required String procName,
    Map<String, dynamic>? extra,
  }) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    if (userId.isEmpty || deviceId.isEmpty || deviceSecret.isEmpty) return null;

    final String result = await ServiceCommon.sendHttpPost(() {
      // Minted inside the closure so a retry gets a fresh token.
      return jsonEncode(<String, dynamic>{
        'queryType': queryType,
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          procName,
          paramString: deviceSecret,
        ),
        ...?extra,
      });
    });

    if (result.startsWith(ERROR_PREFIX)) return null;

    try {
      final outer = jsonDecode(result) as List<dynamic>;
      // Rowset 0 is the success envelope and never business data; the
      // passkeys are rowset 1. A reply with only the envelope means the SP
      // returned an error envelope, not an empty list.
      if (outer.isEmpty) return null;
      final envelope = (outer[0] as List<dynamic>);
      final bool ok =
          envelope.isNotEmpty &&
          ((envelope[0] as Map<String, dynamic>)['success'] as num?)?.toInt() ==
              1;
      if (!ok) return null;
      if (outer.length < 2) return <AccountPasskey>[];
      return (outer[1] as List<dynamic>)
          .map(
            (dynamic r) => AccountPasskey.fromJson(r as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }
}
