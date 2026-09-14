import 'package:harrier_central/imports.dart';

part 'hasher_kennel_map_model_ns.freezed.dart';
part 'hasher_kennel_map_model_ns.g.dart';

extension HasherKennelMapModelExtension on HasherKennelMapModel {
  Mismanagement get mismanagement => Mismanagement(mismanagementRoles);
  AppAccess get appAccess => AppAccess(appAccessFlags);
}

@freezed
abstract class HasherKennelMapModel
    with _$HasherKennelMapModel
    implements BaseModel {
  factory HasherKennelMapModel({
    required String hkmId,
    required String userId,
    required String kennelId,
    required int following,
    required int isMember,
    required int isHomeKennel,
    required int kennelNotificationPreference,
    required int kennelEmailAlertPreference,
    String? authorizedDeviceList,
    int? authorizedDeviceCount,
    required int userRoleFlags,
    required int appAccessFlags,
    required int hcTotalRunCount,
    required int hcHaringCount,
    required int historicalTotalRunCount,
    required int historicalHaringCount,
    required int historicalCountIsEstimate,
    required double kennelCredit,
    required double discountAmount,
    required int discountPercent,
    required String discountDescription,
    DateTime? dateOfLastRun,
    DateTime? membershipExpirationDate,
    DateTime? memberSince,
    int? isKennelFollowing,
    required int mismanagementRoles,
    String? kennelUserPhoto,
    String? kennelHashName,
    /// Pinned chat, TRI-STATE (E9.F1.S8): null means "use the default",
    /// which is pinned for the home kennel and unpinned otherwise. 0 and 1
    /// are the hasher's explicit choice and override the default.
    int? pinned,
    DateTime? updatedAt,
    int? removed,
  }) = _HasherKennelMapModel;

  factory HasherKennelMapModel.fromJson(Map<String, dynamic> json) =>
      _$HasherKennelMapModelFromJson(json);
}
