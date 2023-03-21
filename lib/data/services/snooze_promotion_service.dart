import 'package:harrier_central/imports_null_safe.dart';
import 'package:intl/intl.dart';

class SnoozePromotionService {
  Future<SingleResultModel?> snoozePromotion(String promotionId, bool deletePromotion) async {
    if (G0<AppModel>().connectionStatus == EnumConnectionStatus.not_connected) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = getStringPref(StringPrefsEnum.userId)!;

    final String accessToken = IveCoreUtilities.generateToken(userId, 'snoozePromotion');

    final String body = jsonEncode(<String, String>{
      'userId': userId,
      'accessToken': accessToken,
      'promotionId': promotionId,
      'snoozeUntilDate': deletePromotion ? '2100-01-01' : DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 4)))
    });

    final String responseBody = await ServiceCommon.sendHttpPost('hc3_snooze_promotion', body);

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
