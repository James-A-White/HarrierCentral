import 'package:harrier_central/imports.dart';

class GetResetCodeService {
  Future<SingleResultModel> getResetCode(String supportCode) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId);

    final String accessToken = IveCoreUtilities.generateToken(userId, 'getResetCode');

    final String body = jsonEncode(<String, String>{'userId': userId, 'accessToken': accessToken, 'supportCode': supportCode});

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_get_reset_code', body);

    // final Response response = await post(BASE_API_URL + 'hc3_get_reset_code', headers: <String, String>{'content-type': 'application/json'}, body: body).catchError(
    //   (dynamic error) {
    //     return Future<Response>.value(null);
    //   },
    // );

    SingleResultModel result;

    if ((responseBody != null) && (responseBody.isNotEmpty) && (!responseBody.startsWith(ERROR_PREFIX))) {
      json.decode(responseBody).forEach(
        (dynamic item) {
          result = SingleResultModel(result: item['result']);
        },
      );
    }

    return result;
  }
}
