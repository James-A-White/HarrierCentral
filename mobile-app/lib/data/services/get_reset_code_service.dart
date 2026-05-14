import 'package:harrier_central/imports.dart';

class GetResetCodeService {
  Future<SingleResultModel?> getResetCode(String supportCode) async {
    if (Utilities.isNotConnected()) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String accessToken = Utilities.generateToken(
      userId,
      'hcapp_getResetCode',
      paramString: deviceSecret,
    );

    final String body = jsonEncode(<String, String>{
      'queryType': 'getResetCode',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'supportCode': supportCode,
    });

    final String responseBody = await ServiceCommon.sendHttpPost(body);

    SingleResultModel? result;

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      final List<dynamic> parsed = json.decode(responseBody) as List<dynamic>;
      if (parsed.isNotEmpty && (parsed[0] as List).isNotEmpty) {
        result = SingleResultModel(result: parsed[0][0]['resetCode'] as String?);
      }
    }

    return result;
  }
}
