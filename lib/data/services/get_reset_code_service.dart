import 'package:harrier_central/imports.dart';

class GetResetCodeService {
  Future<SingleResultModel?> getResetCode(String supportCode) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
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
      'supportCode': supportCode
    });

    final String responseBody = await ServiceCommon.sendHttpPostV2(body);

    SingleResultModel? result;

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      json.decode(responseBody).forEach(
        (dynamic item) {
          result = SingleResultModel(result: item[0]['result']);
        },
      );
    }

    return result;
  }
}
