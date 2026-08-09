import 'package:harrier_central/imports.dart';

part 'check_in_pack_model.freezed.dart';
part 'check_in_pack_model.g.dart';

@freezed
abstract class CheckInPackModel with _$CheckInPackModel implements BaseModel {
  factory CheckInPackModel({
    String? hasherId,
    String? hemId,
    @Default(0) int isMember,
    String? membershipExpirationDate,
    @Default(0) int isHare,
    int? isPaid,
    @Default('') String nameForDisplay,
    @Default('') String nameForSort,
    @Default('') String firstName,
    @Default('') String lastName,
    @Default(0) int paymentType,
    @Default(0.0) double creditAmount,
    @Default('') String photo,
    @Default(0) int virginVisitorType,
    @Default(0) int rsvpState,
    @Default(0) int attendenceState,
    @Default(0) int discountPercent,
    @Default(0.0) double discountAmount,
    @Default(0) int hcTotalRunCount,
    @Default(0) int hcHaringCount,
    @Default(0) int historicalTotalRunCount,
    @Default(0) int historicalHaringCount,
    @Default(0) int historicalCountIsEstimate,
    @Default(0) int totalRunsThisKennel,
    @Default(0) int totalHaringThisKennel,
    String? hemUpdatedAt,
    String? payUpdatedAt,
    @Default(0.0) double credit,
    @Default(0) int isFollowing,
    String? homeKennelName,
  }) = _CheckInPackModel;

  factory CheckInPackModel.fromJson(Map<String, dynamic> json) =>
      _$CheckInPackModelFromJson(json);

  @override
  factory CheckInPackModel.fromMap(Map<String, dynamic> map) {
    return CheckInPackModel.fromJson(map);
  }
}
