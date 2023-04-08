import 'package:harrier_central/imports.dart';

class GdprDeleteService {
  Future<SingleResultModel?> gdprDelete() async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;

    final String accessToken = IveCoreUtilities.generateToken(userId, 'gdprDelete');

    final String body = jsonEncode(<String, String>{'userId': userId, 'accessToken': accessToken});

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_gdpr_delete', body);

    SingleResultModel? result;

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      json.decode(responseBody).forEach(
        (dynamic item) {
          result = SingleResultModel(result: item['result']);
        },
      );
    }

    return result;
  }
}
