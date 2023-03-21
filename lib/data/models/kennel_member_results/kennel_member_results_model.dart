import 'package:harrier_central/imports_null_safe.dart';

part 'kennel_member_results_model.freezed.dart';
part 'kennel_member_results_model.g.dart';

@freezed
class KennelMemberResultsModel with _$KennelMemberResultsModel implements BaseModel {
  factory KennelMemberResultsModel({
    required String hasherId,
    String? dispName,
    String? nameForSort,
    String? photo,
    required int following,
    required String kennelId,
    DateTime? dateOfLastRun,
    required int hcTotalRunCount,
    required int hcHaringCount,
    required int historicalTotalRunCount,
    required int historicalHaringCount,
    int? kennelEmailAlertPreference,
    DateTime? membershipExpirationDate,
    DateTime? memberSince,
    required int membershipDurationInMonths,
    int? appAccessFlags,
    int? mismanagementRoles,
    String? kennelShortName,
    num? kennelCredit,
    int? memberFollowingStatus,
  }) = _KennelMemberResultsModel;

  factory KennelMemberResultsModel.fromJson(Map<String, dynamic> json) => _$KennelMemberResultsModelFromJson(json);

  @override
  factory KennelMemberResultsModel.fromMap(Map<String, dynamic> map) {
    return KennelMemberResultsModel.fromJson(map);
  }
}
