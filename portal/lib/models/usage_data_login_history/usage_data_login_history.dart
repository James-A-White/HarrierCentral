// package imports
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_data_login_history.freezed.dart';
part 'usage_data_login_history.g.dart';

@freezed
abstract class UdLoginHistoryModel with _$UdLoginHistoryModel {
  factory UdLoginHistoryModel({
    required DateTime loginDate,
    required String hcVersion,
    required String systemVersion,
    required int isIphone,
    @Default(0.0) double latitude,
    @Default(0.0) double longitude,
    @Default('') String locationName,
  }) = _UdLoginHistoryModel;

  factory UdLoginHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$UdLoginHistoryModelFromJson(json);
}
