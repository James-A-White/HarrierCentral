// package imports
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_data_recent_user.freezed.dart';
part 'usage_data_recent_user.g.dart';

@freezed
abstract class UdRecentUserModel with _$UdRecentUserModel {
  factory UdRecentUserModel({
    @Default('') String userId,
    required String userName,
    @Default('') String realName,
    required String photo,
    required DateTime lastLoginDate,
    required int minutesSinceLastLogin,
    required int loginCount,
    required int isIphone,
    required String systemVersion,
    required String kennelName,
    required String kennelShortName,
    required String hcVersion,
    required int highlightPhoneVersion,
    required int highlightHcVersion,
  }) = _UdRecentUserModel;

  factory UdRecentUserModel.fromJson(Map<String, dynamic> json) =>
      _$UdRecentUserModelFromJson(json);
}
