// package imports
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'kennel_hashers_model.freezed.dart';
part 'kennel_hashers_model.g.dart';

@freezed
abstract class KennelHashersModel with _$KennelHashersModel {
  factory KennelHashersModel({
    required String publicHasherId,
    required String publicKennelId,
    required String eMail,
    required String photo,
    required String inviteCode,
    required String isHomeKennel,
    required String isFollowing,
    required String isMember,
    required String status,
    required String notifications,
    required String emailAlerts,
    required int historicHaring,
    required int historicTotalRuns,
    required int hcHaringCount,
    required int hcTotalRunCount,
    required String historicCountsAreEstimates,
    required num kennelCredit,
    required num discountAmount,
    required int discountPercent,
    required num hashCredit,
    String? hashName,
    String? firstName,
    String? lastName,
    String? displayName,
    DateTime? lastLoginDateTime,
    DateTime? dateOfLastRun,
    DateTime? membershipExpirationDate,
    String? discountDescription,
    String? atLastEvent,
    String? atSecondToLastEvent,
    DateTime? lastEventDate,
    DateTime? nextEventDate,
    DateTime? secondToLastEventDate,
    String? nextEventNumber,
  }) = _KennelHashersModel;

  factory KennelHashersModel.fromJson(Map<String, dynamic> json) =>
      _$KennelHashersModelFromJson(json);
}
