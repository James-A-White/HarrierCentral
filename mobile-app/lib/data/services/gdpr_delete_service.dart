import 'package:harrier_central/imports.dart';

class GdprDeleteService {
  Future<SingleResultModel?> gdprDelete() async {
    if (Utilities.isNotConnected()) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String responseBody = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, String>{
        'queryType': 'gdprDelete',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_gdprDelete',
          paramString: deviceSecret,
        ),
      }),
    );

    SingleResultModel? result;

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      result = SingleResultModel(result: 'success');
    }

    return result;
  }
}
