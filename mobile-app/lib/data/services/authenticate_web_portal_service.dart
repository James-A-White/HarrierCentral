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

    final String responseBody = await ServiceCommon.sendHttpPost(body);

    SingleResultModel? result;

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      // HC6: rowset 0 is the write SP success envelope; result data is at rowset 1.
      final decoded = json.decode(responseBody) as List<dynamic>;
      if (decoded.length > 1) {
        result = SingleResultModel(result: (decoded[1] as List<dynamic>)[0]['result']);
      }
    }

    return result;
  }
}
