import 'package:harrier_central/imports.dart';

class GetInviteCodeService {
  Future<SingleResultModel?> getInviteCode(String targetUserId) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus2.notConnected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;

    final String accessToken = Utilities.generateToken(userId, 'getInviteCode');

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'targetUserId': targetUserId
    });

    final String responseBody =
        await ServiceCommon.sendHttpPost('hc3_get_invite_code', body);

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
