import 'package:harrier_central/imports.dart';

class AuthenticateWebPortalService {
  Future<SingleResultModel?> authenticateWebPortal(String scan) async {
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
      'hcapp_authenticateWebPortal',
      paramString: deviceSecret + scan,
    );

    final String body = jsonEncode(<String, String>{
      'queryType': 'authenticateWebPortal',
      'deviceId': deviceId,
      'accessToken': accessToken,
      'scanData': scan,
    });

    final String responseBody = await ServiceCommon.sendHttpPostV2(body);

    SingleResultModel? result;

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      json.decode(responseBody).forEach((dynamic item) {
        result = SingleResultModel(result: item[0]['result']);
      });
    }

    return result;
  }
}
