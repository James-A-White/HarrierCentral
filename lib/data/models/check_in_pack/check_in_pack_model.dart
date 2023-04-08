import 'package:harrier_central/imports_null_safe.dart';

part 'check_in_pack_model.freezed.dart';
part 'check_in_pack_model.g.dart';

@freezed
class CheckInPackModel with _$CheckInPackModel implements BaseModel {
  factory CheckInPackModel({
    required String hasherId,
    required String hemId,
    @Default(0) int isMember,
    @Default(0) int isHare,
    @Default(0) int isPaid,
    @Default('') String nameForDisplay,
    @Default('') String nameForSort,
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
    required String hemUpdatedAt,
    required String payUpdatedAt,
    @Default(0.0) double credit,
    @Default(0) int isFollowing,
  }) = _CheckInPackModel;

  factory CheckInPackModel.fromJson(Map<String, dynamic> json) => _$CheckInPackModelFromJson(json);

  @override
  factory CheckInPackModel.fromMap(Map<String, dynamic> map) {
    return CheckInPackModel.fromJson(map);
  }
}
