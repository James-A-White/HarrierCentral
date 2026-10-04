import 'package:harrier_central/imports.dart';

/// Puts ONE run on the phone so it can be opened (James, 2026-10-04: "is
/// there a way to load just that one run?"). The user sync carries only ten
/// days of the runs of kennels a hasher does not follow, but the kennel trail
/// map shows every run of the kennel. hcapp_getRunForPhone answers with the
/// run in the sync's own events shape, and it is written through the same
/// serialised sync writer, so it lands exactly as a synced run would —
/// no follow, nothing else downloaded.
class RunOnPhone {
  const RunOnPhone._();

  /// True when the run is now on the phone (it was already, or it arrived).
  static Future<bool> load(HcId eventId) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String secret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    if (userId.isEmpty || deviceId.isEmpty || secret.isEmpty) return false;
    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'getRunForPhone',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_getRunForPhone',
          paramString: secret,
        ),
        'eventId': eventId,
      }),
      errorCallback: (_) async => true,
    );
    if (result.startsWith(ERROR_PREFIX)) return false;
    await tableModel.syncUserDataService
        .updateSqlTablesWithResultsFromApiWithAdHocData(
          result,
          tables: <BaseTableHelper<AppDomainType>>[
            tableModel.eventsTableHelper,
          ],
          batchText: 'one run for the kennel map',
        );
    return true;
  }
}
