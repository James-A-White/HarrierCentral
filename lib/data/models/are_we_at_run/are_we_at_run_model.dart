import 'package:harrier_central/imports.dart';

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
    @Default(0.0) double kennelCredit,
    required double memberPrice,
    required double nonMemberPrice,
    required double extrasCost,
    @Default(0.0) double discountAmount,
    @Default(0.0) double discountPercent,
    @Default(0) int attendenceState,
    @Default(2) int digitsAfterDecimal,
    @Default(0) int allowSelfPayment,
    @Default(r'$^') String currencySymbol,
    required DateTime membershipExpirationDate,
    String? extrasDescription,
  }) = _AreWeAtRunModel;

  factory AreWeAtRunModel.fromJson(Map<String, dynamic> json) => _$AreWeAtRunModelFromJson(json);

  @override
  factory AreWeAtRunModel.fromMap(Map<String, dynamic> map) {
    return AreWeAtRunModel.fromJson(map);
  }
}
