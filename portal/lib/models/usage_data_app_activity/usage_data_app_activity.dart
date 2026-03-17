// package imports
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'usage_data_app_activity.freezed.dart';
part 'usage_data_app_activity.g.dart';

@freezed
abstract class UdAppActivityModel with _$UdAppActivityModel {
  factory UdAppActivityModel({
    required String dataType,
    required int lastHour,
    required int lastHourComp,
    required int lastDay,
    required int lastDayComp,
    required int lastWeek,
    required int lastWeekComp,
    required int lastMonth,
    required int lastMonthComp,
  }) = _UdAppActivityModel;

  factory UdAppActivityModel.fromJson(Map<String, dynamic> json) =>
      _$UdAppActivityModelFromJson(json);
}
