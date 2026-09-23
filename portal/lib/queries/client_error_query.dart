import 'package:hcportal/imports.dart';

/// Ships one client-side error to `hcportal_logClientError` → HC.ErrorLog.
///
/// Fire-and-forget and must NEVER throw: this runs from inside the global
/// error handlers, and an exception here would re-enter them. Every failure
/// is swallowed on purpose — the logger failing is not something the logger
/// can log.
///
/// Auth is best-effort. Before sign-in there is no device secret, so the
/// token is empty and the SP accepts the report only if the device id it
/// carries is one we issued. That is deliberate: a crash on the sign-in page
/// is the one most worth hearing about.
Future<void> sendClientError({
  required String errorName,
  required String errorDescription,
  required String source,
  required String appVersion,
  String? route,
}) async {
  try {
    final deviceId = (box.get(HIVE_DEVICE_ID) as String?) ?? '';
    final deviceSecret = (box.get(HIVE_DEVICE_SECRET) as String?) ?? '';

    // PortalApiHC6 refuses any call without BOTH deviceId and accessToken
    // present — it checks presence, not validity; the SP validates. So a
    // browser that has never held a device cannot report at all (accepted:
    // it has nothing the server could trust), and before sign-in, when there
    // is a device but no secret, a placeholder token goes through and the SP
    // falls back to its device-exists gate. Found on the 2.0.84 smoke test,
    // where the first version of this sent no token and the shim dropped
    // every pre-sign-in report on the floor.
    if (deviceId.isEmpty) return;
    final accessToken = deviceSecret.isEmpty
        ? 'none'
        : Utilities.generateToken(
            deviceId,
            'hcportal_logClientError',
            paramString: deviceSecret,
          );

    final body = <String, String>{
      'queryType': 'logClientError',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'errorName': errorName.length > 500 ? errorName.substring(0, 500) : errorName,
      'errorDescription': errorDescription.length > 2400
          ? errorDescription.substring(0, 2400)
          : errorDescription,
      'source': source,
      'appVersion': appVersion,
      'route': ?route,
    };

    await ServiceCommon.sendHttpPostToHC6Api(body);
  } catch (_) {
    // See above: swallowed on purpose.
  }
}
