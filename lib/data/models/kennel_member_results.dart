// ignore_for_file: constant_identifier_names

import 'package:harrier_central/imports_null_safe.dart';

class KennelMembersResults {
  KennelMembersResults({
    required this.hasherId,
    required this.dispName,
    this.nameForSort,
    this.photo,
    required this.following,
    required this.kennelId,
    this.dateOfLastRun,
    this.historicalTotalRunCount,
    this.historicalHaringCount,
    this.hcHaringCount,
    this.hcTotalRunCount,
    this.kennelEmailAlertPreference,
    this.membershipExpirationDate,
    this.memberSince,
    this.membershipDurationInMonths,
    this.isLoading = false,
    this.kennelShortName,
    this.appAccessFlags,
    this.mismanagementRoles,
    this.kennelCredit,
    this.memberFollowingStatus,
    this.memberInfoBeingUpdated = false,
  });

  final String hasherId;
  String dispName;
  String? nameForSort;
  String? photo;
  final int following;
  final String kennelId;
  final DateTime? dateOfLastRun;
  final int? hcTotalRunCount;
  final int? hcHaringCount;
  final int? historicalTotalRunCount;
  final int? historicalHaringCount;
  int? kennelEmailAlertPreference;
  final DateTime? membershipExpirationDate;
  final DateTime? memberSince;
  final int? membershipDurationInMonths;
  int? appAccessFlags;
  int? mismanagementRoles;
  bool? isLoading;
  bool? memberInfoBeingUpdated;
  String? kennelShortName;
  num? kennelCredit;
  int? memberFollowingStatus;

  static KennelMembersResults fromMap(Map<String, dynamic> map) {
    final KennelMembersResults item = KennelMembersResults(
      hasherId: map['hasherId'],
      dispName: map['dispName'],
      nameForSort: map['nameForSort'],
      photo: map['photo'],
      following: map['following'],
      kennelId: map['kennelId'],
      dateOfLastRun: (map['dateOfLastRun'] == null) ? null : DateTime.parse(map['dateOfLastRun'].toString().substring(0, 19)),
      hcTotalRunCount: map['hcTotalRunCount'],
      hcHaringCount: map['hcHaringCount'],
      historicalTotalRunCount: map['historicalTotalRunCount'],
      historicalHaringCount: map['historicalHaringCount'],
      kennelEmailAlertPreference: map['kennelEmailAlertPreference'],
      membershipExpirationDate: (map['membershipExpirationDate'] == null) ? null : DateTime.parse(map['membershipExpirationDate'].toString().substring(0, 19)),
      memberSince: (map['memberSince'] == null) ? null : DateTime.parse(map['memberSince'].toString().substring(0, 19)),
      membershipDurationInMonths: map['membershipDurationInMonths'],
      appAccessFlags: map['appAccessFlags'],
      mismanagementRoles: map['mismanagementRoles'],
      kennelShortName: map['kennelShortName'],
      kennelCredit: map['kennelCredit'],
      memberFollowingStatus: map['memberFollowingStatus'],
    );
    return item;
  }

  Mismanagement get mismanagement {
    return Mismanagement(mismanagementRoles ?? 0);
  }

  AppAccess get appAccess {
    return AppAccess(appAccessFlags ?? 0);
  }
}
