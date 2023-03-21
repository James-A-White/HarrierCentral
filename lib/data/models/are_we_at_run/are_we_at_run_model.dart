import 'package:harrier_central/imports_null_safe.dart';

part 'are_we_at_run_model.freezed.dart';
part 'are_we_at_run_model.g.dart';

@freezed
class AreWeAtRunModel with _$AreWeAtRunModel implements BaseModel {
  factory AreWeAtRunModel({
    required String eventId,
    required String eventName,
    String? eventImage,
    required String kennelId,
    required String kennelLogo,
    required String kennelShortName,
    required int eventNumber,
    required double distanceInMeters,
    required double deltaHours,
    required double kennelCredit,
    required double memberPrice,
    required double nonMemberPrice,
    required double extrasCost,
    required double discountAmount,
    required double discountPercent,
    required int attendenceState,
    required int digitsAfterDecimal,
    required int allowSelfPayment,
    required String currencySymbol,
    required DateTime membershipExpirationDate,
    String? extrasDescription,
  }) = _AreWeAtRunModel;

  factory AreWeAtRunModel.fromJson(Map<String, dynamic> json) => _$AreWeAtRunModelFromJson(json);

  @override
  factory AreWeAtRunModel.fromMap(Map<String, dynamic> map) {
    return AreWeAtRunModel.fromJson(map);
  }
}
