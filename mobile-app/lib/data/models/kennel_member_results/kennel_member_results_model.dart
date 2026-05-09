import 'package:harrier_central/imports.dart';

part 'kennel_member_results_model.freezed.dart';
part 'kennel_member_results_model.g.dart';

@freezed
abstract class KennelMemberResultsModel
    with _$KennelMemberResultsModel
    implements BaseModel {
  factory KennelMemberResultsModel({
    required String hasherId,
    required String dispName,
    required String nameForSort,
    String? photo,
    @Default(0) int following,
    required String kennelId,
    DateTime? dateOfLastRun,
    @Default(0) int hcTotalRunCount,
    @Default(0) int hcHaringCount,
    @Default(0) int historicalTotalRunCount,
    @Default(0) int historicalHaringCount,
    @Default(0) int kennelEmailAlertPreference,
    DateTime? membershipExpirationDate,
    DateTime? memberSince,
    @Default(6) int membershipDurationInMonths,
    @Default(0) int appAccessFlags,
    @Default(0) int mismanagementRoles,
    String? kennelShortName,
    @Default(0.0) double kennelCredit,
    @Default(0) int memberFollowingStatus,
    @Default(false)
    @JsonKey(includeFromJson: false, includeToJson: false)
    bool memberInfoBeingUpdated,
  }) = _KennelMemberResultsModel;

  factory KennelMemberResultsModel.fromJson(Map<String, dynamic> json) =>
      _$KennelMemberResultsModelFromJson(json);

  @override
  factory KennelMemberResultsModel.fromMap(Map<String, dynamic> map) {
    return KennelMemberResultsModel.fromJson(map);
  }
}
