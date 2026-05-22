import 'package:harrier_central/imports.dart';
import 'package:intl/intl.dart';

class SnoozePromotionService {
  Future<SingleResultModel?> snoozePromotion(
    String promotionId,
    bool deletePromotion,
  ) async {
    if (Utilities.isNotConnected()) {
      return null;
      // TODO(James): fix this so we can return a bool
      //return false;
    }

    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final String responseBody = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, String>{
        'queryType': 'snoozePromotion',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_snoozePromotion',
          paramString: deviceSecret,
        ),
        'promotionId': promotionId,
        'snoozeUntilDate': deletePromotion
            ? '2100-01-01'
            : DateFormat(
                'yyyy-MM-dd',
              ).format(DateTime.now().add(const Duration(days: 4))),
      }),
    );

    SingleResultModel? result;

    if (!responseBody.startsWith(ERROR_PREFIX)) {
      result = SingleResultModel(result: 'success');
    }

    return result;
  }
}
