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
    final accessToken = deviceId.isEmpty || deviceSecret.isEmpty
        ? ''
        : Utilities.generateToken(
            deviceId,
            'hcportal_logClientError',
            paramString: deviceSecret,
          );

    final body = <String, String>{
      'queryType': 'logClientError',
      if (deviceId.isNotEmpty) 'deviceId': deviceId,
      if (accessToken.isNotEmpty) 'accessToken': accessToken,
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
