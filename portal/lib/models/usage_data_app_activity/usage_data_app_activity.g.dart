// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_data_app_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UdAppActivityModel _$UdAppActivityModelFromJson(Map<String, dynamic> json) =>
    _UdAppActivityModel(
      dataType: json['dataType'] as String,
      lastHour: (json['lastHour'] as num).toInt(),
      lastHourComp: (json['lastHourComp'] as num).toInt(),
      lastDay: (json['lastDay'] as num).toInt(),
      lastDayComp: (json['lastDayComp'] as num).toInt(),
      lastWeek: (json['lastWeek'] as num).toInt(),
      lastWeekComp: (json['lastWeekComp'] as num).toInt(),
      lastMonth: (json['lastMonth'] as num).toInt(),
      lastMonthComp: (json['lastMonthComp'] as num).toInt(),
    );

Map<String, dynamic> _$UdAppActivityModelToJson(_UdAppActivityModel instance) =>
    <String, dynamic>{
      'dataType': instance.dataType,
      'lastHour': instance.lastHour,
      'lastHourComp': instance.lastHourComp,
      'lastDay': instance.lastDay,
      'lastDayComp': instance.lastDayComp,
      'lastWeek': instance.lastWeek,
      'lastWeekComp': instance.lastWeekComp,
      'lastMonth': instance.lastMonth,
      'lastMonthComp': instance.lastMonthComp,
    };
