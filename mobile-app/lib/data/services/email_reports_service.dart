import 'package:harrier_central/imports.dart';

class EmailReportsService {
  Future<Map<String, String>> sendKennelRunStatsReportByEmail({
    required String kennelId,
    required String kennelName,
    required int digitsAfterDecimal,
    required String currencySymbol,
  }) async {
    // final String? userId = getStringPref(StringPrefsEnum.userId);
    final String userName = getStringPref(StringPrefsEnum.displayName) ?? '';
    final String? emailAddress = getStringPref(StringPrefsEnum.email);

    final String? deviceId = getStringPref(StringPrefsEnum.deviceId);
    final String? deviceSecret = getStringPref(StringPrefsEnum.deviceSecret);

    final String? userId = getStringPref(StringPrefsEnum.userId);

    if (((userId ?? '').isNotEmpty) &&
        ((emailAddress ?? '').isNotEmpty) &&
        ((deviceId ?? '').isNotEmpty) &&
        ((deviceSecret ?? '').isNotEmpty)) {
      final String accessToken = Utilities.generateToken(
        userId!,
        'hcapp_rptKennelRunStats',
        paramString: deviceSecret!,
      );

      final String body = jsonEncode(<String, String>{
        'queryType': 'rptKennelRunStats',
        'deviceId': deviceId!,
        'accessToken': accessToken,
        'kennelId': kennelId,
        'kennelName': kennelName,
        'userName': userName,
        'emailAddress': emailAddress!,
        'digitsAfterDecimal': digitsAfterDecimal.toString(),
        'currencySymbol': currencySymbol,
      });

      final Response response =
          await post(
            Uri.parse(EMAIL_KENNEL_RUN_STATS_API_URL),
            headers: <String, String>{'content-type': 'application/json'},
            body: body,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => Response('timeout', 408),
          ).catchError((dynamic error) {
            return Future<Response>.value(Response('error', 500));
          });

      return <String, String>{'result': response.body, 'email': emailAddress};
    }
    return <String, String>{
      'result': 'No valid email address found',
      'email': '',
    };
  }

  // TODO: Re-implement email run invites

  // Future<Map<String, String>> sendKennelInvitesByEmail({
  //   required String kennelId,
  //   required String kennelName,
  //   required String isPreview,
  // }) async {
  //   final String? userId = getStringPref(StringPrefsEnum.userId);
  //   final String userName = getStringPref(StringPrefsEnum.displayName) ?? '';
  //   final String? emailAddress = getStringPref(StringPrefsEnum.email);

  //   if (((userId ?? '').isNotEmpty) && ((emailAddress ?? '').isNotEmpty)) {
  //     final String accessToken = Utilities.generateToken(
  //       userId!,
  //       'rptApi_emailKennelInviteCodes',
  //       paramString: kennelId,
  //     );

  //     final String body = jsonEncode(<String, String>{
  //       'userId': userId,
  //       'accessToken': accessToken,
  //       'kennelId': kennelId,
  //       'kennelName': kennelName,
  //       'userName': userName,
  //       'emailAddress': emailAddress!,
  //       'isPreview': isPreview,
  //     });

  //     final Response response = await post(
  //       Uri.parse(EMAIL_KENNEL_INVITE_CODES_API_URL),
  //       headers: <String, String>{'content-type': 'application/json'},
  //       body: body,
  //     ).catchError((dynamic error) {
  //       return Future<Response>.value(Response('error', 500));
  //     });

  //     return <String, String>{'result': response.body};
  //   }
  //   return <String, String>{
  //     'result': 'No valid email address found',
  //     'email': '',
  //   };
  // }
}
